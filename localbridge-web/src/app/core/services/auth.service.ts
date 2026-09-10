import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { AuthVerifyResponse } from 'src/app/model/auth.model';
import { BrowserStorageService } from './browser-storage.service';
import { PairingTokenExtractorService } from './pairing-token-extractor.service';


const TOKEN_KEY = 'localbridge_token';
const LOOPBACK_TOKEN = 'AUTO_HOST_LOOPBACK_SESSION';

/**
 * Manages the client's auth token: localhost auto-bootstrap, pairing-link
 * capture, verification against the backend, and persistence.
 *
 * Storage access goes through BrowserStorageService (shared with
 * SessionService, so the token-key convention lives in exactly one place
 * instead of being duplicated across services). URL parsing is delegated to
 * PairingTokenExtractorService so it can be unit-tested without a real
 * `window.location`.
 *
 * Pairing-link capture is deliberately NOT triggered automatically from the
 * constructor: verifying a token is an async network call, and a component
 * (e.g. LoginComponent) needs to know when it starts and how it resolves to
 * show a loading state and handle failure — a constructor firing an
 * unobservable subscribe() can't give it that. Call `captureUrlToken()`
 * explicitly from wherever the app should react to a pairing link, typically
 * the login screen's `ngOnInit`.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private storage = inject(BrowserStorageService);
  private pairingTokens = inject(PairingTokenExtractorService);

  constructor() {
    this.bootstrapLocalAccess();
  }

  getToken(): string | null {
    return this.storage.get(TOKEN_KEY);
  }

  setToken(token: string): void {
    this.storage.set(TOKEN_KEY, token);
  }

  clearToken(): void {
    this.storage.remove(TOKEN_KEY);
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  verifyToken(token: string): Observable<AuthVerifyResponse> {
    return this.http
      .post<AuthVerifyResponse>('/api/auth/verify', { token })
      .pipe(tap(() => this.setToken(token)));
  }

  /**
   * On localhost, auto-grants a loopback session so an operator on the same
   * machine doesn't need to pair a device with itself. No-op if a token
   * already exists.
   */
  private bootstrapLocalAccess(): void {
    const isLocalhost =
      window.location.hostname === 'localhost' ||
      window.location.hostname === '127.0.0.1';
    if (isLocalhost && !this.getToken()) {
      this.setToken(LOOPBACK_TOKEN);
    }
  }

  /**
   * If a pairing token is present in the URL (QR code / pairing link),
   * extracts it, scrubs it from the address bar, and returns an observable
   * that verifies it against the backend and persists it on success.
   *
   * Returns `null` synchronously when there is nothing to capture, so a
   * caller can decide whether to enter a loading state before subscribing:
   *
   *   const capture$ = this.authService.captureUrlToken();
   *   if (capture$) {
   *     this.isLoading = true;
   *     capture$.subscribe({ next: () => ..., error: () => ... });
   *   }
   */
  captureUrlToken(): Observable<AuthVerifyResponse> | null {
    const urlToken = this.pairingTokens.extractAndClean();
    return urlToken ? this.verifyToken(urlToken) : null;
  }
}
