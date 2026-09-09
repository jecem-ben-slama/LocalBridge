import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';

/**
 * Angular Session Service - manages session lifecycle for web client
 * Stores session ID and coordinates with backend session management
 */
@Injectable({
  providedIn: 'root',
})
export class SessionService {
  private sessionId$ = new BehaviorSubject<string | null>(null);
  private readonly SESSION_ID_KEY = 'localbridge_session_id';

  constructor(private http: HttpClient) {
    this.loadSessionFromStorage();
  }

  /**
   * Gets the current session ID
   */
  getSessionId(): string | null {
    return this.sessionId$.value;
  }

  /**
   * Gets session ID as observable for reactive updates
   */
  getSessionId$(): Observable<string | null> {
    return this.sessionId$.asObservable();
  }

  /**
   * Creates a new session with the backend
   */
  createSession(deviceName: string = 'Angular Web App'): Observable<any> {
    return this.http
      .post('/api/session/create', {
        deviceId: this.getDeviceId(),
        deviceName,
      })
      .pipe(
        tap((response: any) => {
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

  /**
   * Sets and stores the session ID
   */
  setSessionId(sessionId: string): void {
    this.sessionId$.next(sessionId);
    localStorage.setItem(this.SESSION_ID_KEY, sessionId);
    console.log(`[SessionService] Session ID set: ${sessionId}`);
  }

  /**
   * Clears the session ID
   */
  clearSessionId(): void {
    this.sessionId$.next(null);
    localStorage.removeItem(this.SESSION_ID_KEY);
    console.log('[SessionService] Session ID cleared');
  }

  /**
   * Loads session ID from local storage if available
   */
  private loadSessionFromStorage(): void {
    const stored = localStorage.getItem(this.SESSION_ID_KEY);
    if (stored) {
      this.sessionId$.next(stored);
      console.log(`[SessionService] Session loaded from storage: ${stored}`);
    }
  }

  /**
   * Refreshes the session to reset inactivity timeout
   */
  refreshSession(): Observable<any> {
    return this.http.post('/api/session/refresh', {}).pipe(
      catchError((error) => {
        if (error.status === 401) {
          this.clearSessionId();
        }
        return throwError(() => error);
      })
    );
  }

  /**
   * Sends a heartbeat to keep the session alive
   */
  heartbeat(): Observable<any> {
    return this.http.get('/api/session/heartbeat').pipe(
      catchError((error) => {
        if (error.status === 401) {
          this.clearSessionId();
        }
        return throwError(() => error);
      })
    );
  }

  /**
   * Closes the session
   */
  closeSession(): Observable<any> {
    return this.http.post('/api/session/close', {}).pipe(
      tap(() => this.clearSessionId()),
      catchError((error) => throwError(() => error))
    );
  }

  /**
   * Gets a unique device identifier for the web client
   */
  private getDeviceId(): string {
    let deviceId = sessionStorage.getItem('device_id');
    if (!deviceId) {
      deviceId = `web-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
      sessionStorage.setItem('device_id', deviceId);
    }
    return deviceId;
  }
}
