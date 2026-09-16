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
  exhaustMap,
} from 'rxjs';
import { ApiResponse } from 'src/app/model/apiresponse';
import { FileNode } from 'src/app/model/filenode';
import { ToastService } from './toast.service';

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
  private static readonly HEARTBEAT_TIMEOUT_MS = 20000;
  private static readonly STATUS_TIMEOUT_MS = 10000;
  private static readonly RECENT_SUCCESS_GRACE_MS = 15000;
  // Sentinel stored in localbridge_token when this browser is running on
  // the same machine as the backend - AuthenticationService's loopback
  // check auto-trusts it (SecurityContext.trustedLocal()), so it never
  // needed a real per-phone pairing token. It isn't tied to any specific
  // phone connection, so disconnecting a phone must not clear it: doing
  // so would force the user to re-pair the host session itself, not just
  // the phone.
  private static readonly AUTO_LOOPBACK_TOKEN = 'AUTO_HOST_LOOPBACK_SESSION';

  private http = inject(HttpClient);
  private toastService = inject(ToastService);

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

  private readonly browseCountSubject = new BehaviorSubject<number>(0);

  private readonly phoneBusy$ = combineLatest([
    this.browseCountSubject,
    this.transferState$,
  ]).pipe(
    map(([browseCount, transfer]) => browseCount > 0 || transfer.active),
    distinctUntilChanged()
  );

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
    merge(interval(5000).pipe(startWith(0)), this.manualCheck$)
      .pipe(
        withLatestFrom(this.phoneBusy$),
        exhaustMap(([, phoneBusy]) => this.pollOnce(phoneBusy))
      )
      .subscribe();
  }

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
    const cacheBuster = `?cb=${new Date().getTime()}`;
    const token = localStorage.getItem('localbridge_token');

    const headersConfig: { [header: string]: string } = {
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      Pragma: 'no-cache',
      Expires: '0',
    };

    if (token) {
      headersConfig['X-Session-Id'] = token;
    }

    return this.http
      .get<{
        connected: boolean;
        phoneServerUrl: string | null;
        phoneServerToken: string | null;
      }>(`/api/phone/status${cacheBuster}`, {
        headers: new HttpHeaders(headersConfig),
      })
      .pipe(
        timeout(FileService.STATUS_TIMEOUT_MS),
        tap((status) => {
          this.phoneServerUrl = status.phoneServerUrl;
          this.phoneServerToken = status.phoneServerToken;
        })
      );
  }

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

  /**
   * Clears the stored device pairing token - unless it's the
   * AUTO_LOOPBACK_TOKEN sentinel, which represents host-loopback trust
   * rather than a pairing with a specific phone and must survive phone
   * disconnects.
   */
  private clearPairingToken(): void {
    const existing = localStorage.getItem('localbridge_token');
    if (existing !== FileService.AUTO_LOOPBACK_TOKEN) {
      localStorage.removeItem('localbridge_token');
    }
  }

  disconnectPhone(): Observable<unknown> {
    return this.http.post('/api/phone/disconnect', {}).pipe(
      tap(() => {
        // Force clear all local references immediately
        this.phoneServerUrl = null;
        this.phoneServerToken = null;
        this.heartbeatFailureCount = 0;
        this.lastPhoneServerSuccessAt = 0;

        this.clearPairingToken();
        localStorage.removeItem('localbridge_session_id');

        // Force status update to disconnected right away
        this.patchStatus({
          backendLive: true,
          phoneConnected: false,
          phoneServerLive: false,
          phoneServerUrl: null,
          checking: false,
          lastChecked: new Date(),
        });

        this.toastService.info('Phone disconnected.');
      }),
      catchError((error) => {
        // Even if the network call fails, force local cleanup so the UI isn't stuck
        this.phoneServerUrl = null;
        this.phoneServerToken = null;
        this.clearPairingToken();
        localStorage.removeItem('localbridge_session_id');
        this.patchStatus({
          backendLive: false,
          phoneConnected: false,
          phoneServerLive: false,
          phoneServerUrl: null,
          checking: false,
          lastChecked: new Date(),
        });
        this.toastService.error(
          'Disconnect failed, but local session was cleared.'
        );
        return throwError(() => error);
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

  uploadFile(path: string, file: File): Observable<HttpEvent<unknown>> {
    const formData = new FormData();
    formData.append('file', file);
    let params = new HttpParams();
    params = params.set('path', path || 'LocalBridge');
    return this.http.post('/api/files/upload', formData, {
      params,
      reportProgress: true,
      observe: 'events',
    });
  }

  startUpload(path: string, file: File, destination: 'pc' | 'phone'): boolean {
    if (this.transferBusy) {
      this.toastService.warning('Another transfer is currently in progress.');
      return false;
    }

    if (destination === 'phone') {
      const currentStatus = this.statusSubject.value;
      if (!currentStatus.phoneConnected || !currentStatus.phoneServerLive) {
        const errorMsg =
          'Cannot send to phone: The phone server is unreachable. Please open the app on your phone.';
        this.toastService.error(errorMsg);
        this.failTransfer(errorMsg);
        return false;
      }
    }

    this.beginTransfer('upload', file.name);

    const request =
      destination === 'pc'
        ? this.uploadFile(path, file)
        : this.refreshPhoneServer().pipe(
            switchMap((status) => {
              if (!status.phoneServerUrl) {
                return throwError(
                  () =>
                    new Error(
                      'Phone disconnected right before transfer. Please wake up the phone.'
                    )
                );
              }
              return this.uploadToPhone(file, path);
            })
          );

    this.transferSubscription = request.subscribe({
      next: (event) => {
        if (event.type === HttpEventType.UploadProgress && event.total) {
          this.updateTransfer(Math.round((event.loaded / event.total) * 100));
        }
        if (event.type === HttpEventType.Response) {
          this.lastPhoneServerSuccessAt = Date.now();
          this.toastService.success(`Successfully uploaded ${file.name}`);
          this.finishTransfer();
        }
      },
      error: (error) => {
        const errorMessage =
          error?.message || error?.error?.message || 'Upload failed.';
        this.toastService.error(`Upload failed: ${errorMessage}`);
        this.failTransfer(errorMessage);
      },
    });

    return true;
  }

  startDownload(path: string, source: 'pc' | 'phone'): boolean {
    if (this.transferBusy) {
      this.toastService.warning('Another transfer is currently in progress.');
      return false;
    }

    const fileName = decodeURIComponent(path.split('/').pop() || 'download');
    this.beginTransfer('download', fileName);

    this.saveDownload(path, source, (progress) => this.updateTransfer(progress))
      .then(() => {
        this.lastPhoneServerSuccessAt = Date.now();
        this.toastService.success(`Successfully downloaded ${fileName}`);
        this.finishTransfer();
      })
      .catch((error) => {
        const errorMsg = error?.message || 'Download failed.';
        this.toastService.error(errorMsg);
        this.failTransfer(errorMsg);
      });

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
    this.toastService.info('Transfer cancelled');
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
