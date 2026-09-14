import { Injectable, inject } from '@angular/core';
import {
  HttpClient,
  HttpEvent,
  HttpEventType,
  HttpHeaders,
  HttpParams,
  HttpRequest,
} from '@angular/common/http';
import {
  Observable,
  BehaviorSubject,
  Subject,
  Subscription,
  catchError,
  combineLatest,
  defer,
  distinctUntilChanged,
  exhaustMap,
  finalize,
  interval,
  map,
  merge,
  of,
  startWith,
  switchMap,
  tap,
  throwError,
  timeout,
  withLatestFrom,
} from 'rxjs';
import { ApiResponse } from 'src/app/model/apiresponse';
import { FileNode } from 'src/app/model/filenode';

export interface ConnectionStatus {
  backendLive: boolean;
  phoneConnected: boolean;
  phoneServerLive: boolean;
  phoneServerUrl: string | null;
  checking: boolean;
  lastChecked: Date | null;
}

@Injectable({
  providedIn: 'root',
})
export class FileService {
  private static readonly MAX_CONSECUTIVE_HEARTBEAT_FAILURES = 3;
  // Heartbeat gets a longer timeout than ordinary calls: a slow-but-alive
  // phone (e.g. mid-way through serving a big /browse listing) should not
  // be counted as a failure just because 5-10s of generic HTTP timeout
  // elapsed while it was legitimately busy.
  private static readonly HEARTBEAT_TIMEOUT_MS = 20000;
  // Bound on the /api/phone/status call that kicks off every poll cycle.
  // pollOnce() must always settle within a known upper bound - otherwise,
  // with exhaustMap on the outer poller, a single hung backend call would
  // permanently wedge all future polling (nothing would ever unsubscribe
  // it for us the way switchMap used to).
  private static readonly STATUS_TIMEOUT_MS = 10000;
  // If any request to the phone server succeeded this recently, a failed
  // heartbeat is almost certainly the phone being briefly busy, not gone -
  // don't count it towards the failure threshold.
  private static readonly RECENT_SUCCESS_GRACE_MS = 15000;

  private http = inject(HttpClient);
  private apiUrl = '/api/files/list';
  private phoneServerUrl: string | null = null;
  private phoneServerToken: string | null = null;
  private heartbeatFailureCount = 0;
  private lastPhoneServerSuccessAt = 0;

  private transferSubscription?: Subscription;
  private readonly transferSubject = new BehaviorSubject<TransferState>({
    active: false,
    kind: null,
    fileName: null,
    progress: 0,
    error: null,
    cancelled: false,
  });
  readonly transferState$ = this.transferSubject.asObservable();

  // Tracks concurrent in-flight phone browse requests. A counter (not a
  // boolean) so overlapping browse calls - e.g. double-clicking into a
  // folder before the first response lands - don't clobber each other.
  private readonly browseCountSubject = new BehaviorSubject<number>(0);

  // Single source of truth for "the phone is currently proving liveness to
  // us directly via a browse or transfer". Composed from browse count +
  // transfer state instead of duplicating the concept in two places.
  private readonly phoneBusy$ = combineLatest([
    this.browseCountSubject,
    this.transferState$,
  ]).pipe(
    map(([browseCount, transfer]) => browseCount > 0 || transfer.active),
    distinctUntilChanged()
  );

  // Single, centralized connection poller. Components subscribe to this
  // instead of each running their own interval against the shared service
  // state - that duplication was what caused the checking-flag race.
  //
  // NOTE: this used to be paired with a *second*, independent heartbeat
  // loop (startPhoneHeartbeat/phoneHeartbeat) that also called
  // heartbeatPhoneServer on its own 10s timer. Both loops incremented the
  // same heartbeatFailureCount, so a single slow response from the phone
  // (e.g. while it was serving a large /browse listing) could get counted
  // as two failures in quick succession, tripping the disconnect threshold
  // well before the phone was actually unreachable. There is now exactly
  // one thing that calls heartbeatPhoneServer: this poller.
  //
  // NOTE 2: this uses exhaustMap, not switchMap. HEARTBEAT_TIMEOUT_MS
  // (20s) is longer than the 10s tick interval, so with switchMap any
  // heartbeat that legitimately took >10s (e.g. phone mid-/browse) would
  // get cancelled - not failed - by the next tick before it could ever
  // call patchStatus(). That silently froze the UI at its initial
  // "checking" defaults instead of ever reflecting a live phone.
  // exhaustMap lets an in-flight poll run to completion (success or real
  // failure) and simply drops ticks that land while it's still running.
  // pollOnce() is bounded (STATUS_TIMEOUT_MS + HEARTBEAT_TIMEOUT_MS worst
  // case) so it always settles and the next tick is never blocked for
  // long.
  private readonly manualCheck$ = new Subject<void>();
  private readonly statusSubject = new BehaviorSubject<ConnectionStatus>({
    backendLive: false,
    phoneConnected: false,
    phoneServerLive: false,
    phoneServerUrl: null,
    checking: false,
    lastChecked: null,
  });
  readonly connectionStatus$ = this.statusSubject.asObservable();

  constructor() {
    merge(interval(10000).pipe(startWith(0)), this.manualCheck$)
      .pipe(
        withLatestFrom(this.phoneBusy$),
        exhaustMap(([, phoneBusy]) => this.pollOnce(phoneBusy))
      )
      .subscribe();
  }

  /** Trigger an immediate connection check (e.g. from a manual refresh button). */
  checkNow(): void {
    this.manualCheck$.next();
  }

  get transferState(): TransferState {
    return this.transferSubject.value;
  }

  get transferBusy(): boolean {
    return this.transferState.active;
  }

  private pollOnce(phoneBusy: boolean): Observable<void> {
    this.patchStatus({ checking: true });

    return this.refreshPhoneServer().pipe(
      switchMap((status) => {
        if (!status.phoneServerUrl) {
          this.patchStatus({
            backendLive: true,
            phoneConnected: status.connected,
            phoneServerLive: false,
            phoneServerUrl: null,
            checking: false,
            lastChecked: new Date(),
          });
          return of(void 0);
        }
        return this.heartbeatPhoneServer(phoneBusy).pipe(
          map(() => {
            this.patchStatus({
              backendLive: true,
              phoneConnected: status.connected,
              phoneServerLive: true,
              phoneServerUrl: status.phoneServerUrl,
              checking: false,
              lastChecked: new Date(),
            });
          }),
          catchError(() => {
            this.patchStatus({
              backendLive: true,
              phoneConnected: status.connected,
              phoneServerLive: false,
              phoneServerUrl: status.phoneServerUrl,
              checking: false,
              lastChecked: new Date(),
            });
            return of(void 0);
          })
        );
      }),
      catchError(() => {
        this.patchStatus({
          backendLive: false,
          phoneConnected: false,
          phoneServerLive: false,
          checking: false,
          lastChecked: new Date(),
        });
        return of(void 0);
      })
    );
  }

  private patchStatus(patch: Partial<ConnectionStatus>): void {
    this.statusSubject.next({ ...this.statusSubject.value, ...patch });
  }
  refreshPhoneServer(): Observable<{
    connected: boolean;
    phoneServerUrl: string | null;
    phoneServerToken: string | null;
  }> {
    // Add a unique timestamp string to the end of the URL path to bypass the browser cache
    const cacheBuster = `?cb=${new Date().getTime()}`;

    return this.http
      .get<{
        connected: boolean;
        phoneServerUrl: string | null;
        phoneServerToken: string | null;
      }>(`/api/phone/status${cacheBuster}`, {
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          Pragma: 'no-cache',
          Expires: '0',
        },
      })
      .pipe(
        // Bounded so pollOnce() can never hang indefinitely - see the
        // exhaustMap note on the constructor's poller above.
        timeout(FileService.STATUS_TIMEOUT_MS),
        tap((status) => {
          // Updated to use Local Time string so it matches your Flutter log format!
          console.log(
            `[${new Date().toLocaleString()}] Phone server status refreshed:`,
            status
          );

          this.phoneServerUrl = status.phoneServerUrl;
          this.phoneServerToken = status.phoneServerToken;
        })
      );
  }

  /**
   * Pings the phone's /health endpoint - unless the phone is already busy
   * serving us a browse or transfer request, in which case that IS proof
   * of life and we skip the probe entirely.
   *
   * A failure is only counted towards the disconnect threshold if we
   * haven't seen a successful phone response very recently - a slow /health
   * response right after (or during) a big /browse listing is far more
   * likely to be "busy" than "gone".
   */
  heartbeatPhoneServer(phoneBusy: boolean): Observable<unknown> {
    if (!this.phoneServerUrl) return of(null);

    if (phoneBusy) {
      this.heartbeatFailureCount = 0;
      this.lastPhoneServerSuccessAt = Date.now();
      return of(null);
    }

    return this.http
      .get(`${this.phoneServerUrl}/health`, {
        params: this.phoneParams(),
      })
      .pipe(
        timeout(FileService.HEARTBEAT_TIMEOUT_MS),
        tap(() => {
          this.heartbeatFailureCount = 0;
          this.lastPhoneServerSuccessAt = Date.now();
        }),
        catchError((error) => {
          const recentlyAlive =
            Date.now() - this.lastPhoneServerSuccessAt <
            FileService.RECENT_SUCCESS_GRACE_MS;
          if (!recentlyAlive) {
            this.heartbeatFailureCount++;
          }
          if (
            this.heartbeatFailureCount >=
            FileService.MAX_CONSECUTIVE_HEARTBEAT_FAILURES
          ) {
            this.phoneServerUrl = null;
            this.phoneServerToken = null;
          }
          return throwError(() => error);
        })
      );
  }

  disconnectPhone(): Observable<unknown> {
    const params = this.phoneParams();
    return this.http.post('/api/phone/disconnect', {}, { params }).pipe(
      tap(() => {
        this.phoneServerUrl = null;
        this.phoneServerToken = null;
        localStorage.removeItem('localbridge_token');
        this.patchStatus({
          phoneConnected: false,
          phoneServerLive: false,
          phoneServerUrl: null,
        });
      })
    );
  }

  getDirectoryContents(
    path?: string,
    source: 'pc' | 'phone' = 'pc'
  ): Observable<ApiResponse<FileNode[]>> {
    let params = new HttpParams();
    if (path) {
      params = params.set('path', path);
    }
    const endpoint =
      source === 'phone' && this.phoneServerUrl
        ? `${this.phoneServerUrl}/browse`
        : source === 'phone'
        ? '/api/phone/list'
        : this.apiUrl;
    if (source === 'phone' && this.phoneServerUrl) {
      params = this.phoneParams(params);
    }

    const request$ = this.http
      .get<ApiResponse<FileNode[]>>(endpoint, { params })
      .pipe(timeout(60000));

    if (source !== 'phone') {
      return request$;
    }

    return defer(() => {
      this.browseCountSubject.next(this.browseCountSubject.value + 1);
      return request$.pipe(
        tap(() => {
          this.lastPhoneServerSuccessAt = Date.now();
        }),
        finalize(() =>
          this.browseCountSubject.next(this.browseCountSubject.value - 1)
        )
      );
    });
  }

  getThumbnailUrl(path: string, source: 'pc' | 'phone' = 'pc'): string {
    const endpoint =
      source === 'phone' && this.phoneServerUrl
        ? `${this.phoneServerUrl}/preview`
        : source === 'phone'
        ? '/api/phone/preview'
        : '/api/files/preview';
    return this.withToken(`${endpoint}?path=${encodeURIComponent(path)}`);
  }

  getDownloadUrl(path: string, source: 'pc' | 'phone' = 'pc'): string {
    const endpoint =
      source === 'phone' && this.phoneServerUrl
        ? `${this.phoneServerUrl}/download`
        : source === 'phone'
        ? '/api/phone/download'
        : '/api/files/download';
    return this.withToken(`${endpoint}?path=${encodeURIComponent(path)}`);
  }

  private withToken(url: string): string {
    const token =
      this.phoneServerToken ?? localStorage.getItem('localbridge_token');
    return token ? `${url}&token=${encodeURIComponent(token)}` : url;
  }

  private phoneParams(params = new HttpParams()): HttpParams {
    const token =
      this.phoneServerToken ?? localStorage.getItem('localbridge_token');
    return token ? params.set('token', token) : params;
  }

  uploadToPhone(file: File, path = ''): Observable<HttpEvent<unknown>> {
    if (!this.phoneServerUrl) {
      return throwError(() => new Error('Phone server is not available.'));
    }
    let params = this.phoneParams();
    if (path) {
      params = params.set('path', path);
    }
    const request = new HttpRequest(
      'POST',
      `${this.phoneServerUrl}/upload`,
      file,
      {
        reportProgress: true,
        responseType: 'json',
        headers: new HttpHeaders({
          'Content-Type': file.type || 'application/octet-stream',
          'X-File-Name': encodeURIComponent(file.name),
        }),
        params,
      }
    );
    return this.http.request(request);
  }

  async saveDownload(
    path: string,
    source: 'pc' | 'phone',
    onProgress?: (percent: number) => void
  ): Promise<void> {
    const url = this.getDownloadUrl(path, source);
    const fileName = decodeURIComponent(path.split('/').pop() || 'download');
    const savePicker = (window as any).showSaveFilePicker;
    if (typeof savePicker !== 'function') {
      const link = document.createElement('a');
      link.href = url;
      link.download = fileName;
      link.click();
      return;
    }

    const response = await fetch(url);
    if (!response.ok || !response.body) {
      throw new Error('The download did not return a file.');
    }
    const total = Number(response.headers.get('content-length')) || 0;
    const handle = await savePicker({ suggestedName: fileName });
    const writable = await handle.createWritable();
    const reader = response.body.getReader();
    let received = 0;
    try {
      while (true) {
        const chunk = await reader.read();
        if (chunk.done) break;
        await writable.write(chunk.value);
        received += chunk.value.byteLength;
        if (total > 0) onProgress?.(Math.round((received / total) * 100));
      }
      await writable.close();
      onProgress?.(100);
    } catch (error) {
      await writable.abort();
      throw error;
    }
  }

  uploadFile(path: string, file: File): Observable<HttpEvent<any>> {
    const formData = new FormData();
    formData.append('file', file);

    let params = new HttpParams();
    params = params.set('path', path || 'LocalBridge');

    return this.http.post<any>('/api/files/upload', formData, {
      params,
      reportProgress: true,
      observe: 'events',
    });
  }

  startUpload(path: string, file: File, destination: 'pc' | 'phone'): boolean {
    if (this.transferBusy) return false;
    this.beginTransfer('upload', file.name);
    const request =
      destination === 'pc'
        ? this.uploadFile(path, file)
        : this.refreshPhoneServer().pipe(
            switchMap(() => this.uploadToPhone(file, path))
          );
    this.transferSubscription = request.subscribe({
      next: (event) => {
        if (event.type === HttpEventType.UploadProgress && event.total) {
          this.updateTransfer(Math.round((event.loaded / event.total) * 100));
        }
        if (event.type === HttpEventType.Response) {
          this.lastPhoneServerSuccessAt = Date.now();
          this.finishTransfer();
        }
      },
      error: (error) =>
        this.failTransfer(error?.error?.message || 'Upload failed.'),
    });
    return true;
  }

  startDownload(path: string, source: 'pc' | 'phone'): boolean {
    if (this.transferBusy) return false;
    const fileName = decodeURIComponent(path.split('/').pop() || 'download');
    this.beginTransfer('download', fileName);
    this.saveDownload(path, source, (progress) => this.updateTransfer(progress))
      .then(() => {
        this.lastPhoneServerSuccessAt = Date.now();
        this.finishTransfer();
      })
      .catch((error) =>
        this.failTransfer(error?.message || 'Download failed.')
      );
    return true;
  }

  cancelTransfer(): void {
    if (!this.transferBusy) return;

    this.transferSubscription?.unsubscribe();
    this.transferSubscription = undefined;

    this.transferSubject.next({
      active: false,
      kind: null,
      fileName: null,
      progress: 0,
      error: 'Transfer cancelled',
      cancelled: true,
    });
  }

  private beginTransfer(kind: TransferKind, fileName: string) {
    this.transferSubject.next({
      active: true,
      kind,
      fileName,
      progress: 0,
      error: null,
      cancelled: false,
    });
  }

  private updateTransfer(progress: number) {
    this.transferSubject.next({ ...this.transferState, progress });
  }

  private finishTransfer() {
    this.transferSubscription = undefined;
    this.transferSubject.next({
      ...this.transferState,
      active: false,
      progress: 100,
      cancelled: false,
    });
  }

  private failTransfer(error: string) {
    this.transferSubscription = undefined;
    this.transferSubject.next({
      ...this.transferState,
      active: false,
      error,
      cancelled: false,
    });
  }
}

export type TransferKind = 'upload' | 'download';

export interface TransferState {
  active: boolean;
  kind: TransferKind | null;
  fileName: string | null;
  progress: number;
  error: string | null;
  cancelled: boolean;
}
