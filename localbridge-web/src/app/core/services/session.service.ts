import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';
import { BrowserStorageService } from './browser-storage.service';
import { DeviceIdService } from './device-id.service';
import { SessionId, SessionCreateResponse, SessionCreateRequest } from 'src/app/model/session.model';

const SESSION_ID_KEY = 'localbridge_session_id';

/**
 * Manages session lifecycle for the web client: creation, persistence,
 * refresh/heartbeat, and teardown.
 *
 * This is a thin orchestrator — it composes BrowserStorageService (storage
 * primitive) and DeviceIdService (identity primitive) rather than owning
 * either concern itself, so each piece can be tested and reused on its own.
 */
@Injectable({ providedIn: 'root' })
export class SessionService {
  private http = inject(HttpClient);
  private storage = inject(BrowserStorageService);
  private deviceId = inject(DeviceIdService);

  private readonly sessionId$ = new BehaviorSubject<SessionId | null>(
    this.storage.get(SESSION_ID_KEY)
  );

  getSessionId(): SessionId | null {
    return this.sessionId$.value;
  }

  getSessionId$(): Observable<SessionId | null> {
    return this.sessionId$.asObservable();
  }

  createSession(deviceName = 'Angular Web App'): Observable<SessionCreateResponse> {
    const payload: SessionCreateRequest = {
      deviceId: this.deviceId.getOrCreate(),
      deviceName,
    };

    return this.http.post<SessionCreateResponse>('/api/session/create', payload).pipe(
      tap((response) => {
        if (response.sessionId) {
          this.setSessionId(response.sessionId);
        }
      }),
      catchError((error) => {
        console.error('[SessionService] Failed to create session:', error);
        return throwError(() => error);
      })
    );
  }

  setSessionId(sessionId: SessionId): void {
    this.sessionId$.next(sessionId);
    this.storage.set(SESSION_ID_KEY, sessionId);
  }

  clearSessionId(): void {
    this.sessionId$.next(null);
    this.storage.remove(SESSION_ID_KEY);
  }

  refreshSession(): Observable<unknown> {
    return this.http
      .post('/api/session/refresh', {})
      .pipe(catchError((error) => this.handleAuthError(error)));
  }

  heartbeat(): Observable<unknown> {
    return this.http
      .get('/api/session/heartbeat')
      .pipe(catchError((error) => this.handleAuthError(error)));
  }

  closeSession(): Observable<unknown> {
    return this.http.post('/api/session/close', {}).pipe(
      tap(() => this.clearSessionId()),
      catchError((error) => throwError(() => error))
    );
  }

  /** Any 401 from a session-scoped call means the session is dead client-side too. */
  private handleAuthError(error: { status?: number }): Observable<never> {
    if (error?.status === 401) {
      this.clearSessionId();
    }
    return throwError(() => error);
  }
}
