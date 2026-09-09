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
  catchError,
  BehaviorSubject,
  Subscription,
  switchMap,
  tap,
  throwError,
  timeout,
} from 'rxjs';
import { ApiResponse } from 'src/app/model/apiresponse';
import { FileNode } from 'src/app/model/filenode';

@Injectable({
  providedIn: 'root',
})
export class FileService {
  private http = inject(HttpClient);
  private apiUrl = '/api/files/list';
  private phoneServerUrl: string | null = null;
  private phoneServerToken: string | null = null;
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

  get transferState(): TransferState {
    return this.transferSubject.value;
  }

  get transferBusy(): boolean {
    return this.transferState.active;
  }

  refreshPhoneServer(): Observable<{
    connected: boolean;
    phoneServerUrl: string | null;
    phoneServerToken: string | null;
  }> {
    return this.http
      .get<{
        connected: boolean;
        phoneServerUrl: string | null;
        phoneServerToken: string | null;
      }>('/api/phone/status')
      .pipe(
        tap((status) => {
          this.phoneServerUrl = status.phoneServerUrl;
          this.phoneServerToken = status.phoneServerToken;
        })
      );
  }

  heartbeatPhoneServer(): Observable<unknown> {
    if (!this.phoneServerUrl)
      return new Observable((subscriber) => subscriber.complete());
    return this.http
      .get(`${this.phoneServerUrl}/health`, {
        params: this.phoneParams(),
      })
      .pipe(
        tap(() => undefined),
        catchError((error) => {
          this.phoneServerUrl = null;
          this.phoneServerToken = null;
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
    return this.http
      .get<ApiResponse<FileNode[]>>(endpoint, { params })
      .pipe(timeout(60000));
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
      .then(() => this.finishTransfer())
      .catch((error) =>
        this.failTransfer(error?.message || 'Download failed.')
      );
    return true;
  }

  /**
   * Cancels the active transfer (upload or download).
   */
  cancelTransfer(): void {
    if (!this.transferBusy) return;

    // Unsubscribe from any active HTTP requests
    this.transferSubscription?.unsubscribe();
    this.transferSubscription = undefined;

    // Reset transfer state
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
