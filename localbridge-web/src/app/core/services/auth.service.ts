import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class AuthService {
  private http = inject(HttpClient);
  private tokenKey = 'localbridge_token';

  constructor() {
    this.initializeLocalAccess();
  }

  private initializeLocalAccess(): void {
    const isLocalhost =
      window.location.hostname === 'localhost' ||
      window.location.hostname === '127.0.0.1';
    if (isLocalhost && !this.getToken()) {
      this.setToken('AUTO_HOST_LOOPBACK_SESSION');
    }
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  setToken(token: string): void {
    localStorage.setItem(this.tokenKey, token);
  }

  clearToken(): void {
    localStorage.removeItem(this.tokenKey);
  }

  verifyToken(token: string): Observable<any> {
    return this.http
      .post('/api/auth/verify', { token })
      .pipe(tap(() => this.setToken(token)));
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  // Automatically check URL parameters for a token passed via QR code / pairing link
  handleUrlTokenCapture(): boolean {
    const urlParams = new URLSearchParams(window.location.search);
    const urlToken =
      urlParams.get('token') ||
      urlParams.get('pairing_token') ||
      urlParams.get('pairing_code') ||
      urlParams.get('code');

    if (urlToken) {
      // Clean up the URL query parameters so the token isn't exposed in the address bar
      window.history.replaceState({}, document.title, window.location.pathname);
      this.verifyToken(urlToken).subscribe({
        error: () => this.clearToken(),
      });
      return true;
    }
    return false;
  }
}
