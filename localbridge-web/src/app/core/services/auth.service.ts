import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap } from 'rxjs';
import { AuthVerifyResponse } from 'src/app/model/auth.model';
import { BrowserStorageService } from './browser-storage.service';
import { PairingTokenExtractorService } from './pairing-token-extractor.service';
import { ToastService } from 'src/app/core/services/toast.service';

const TOKEN_KEY = 'localbridge_token';
const LOOPBACK_TOKEN = 'AUTO_HOST_LOOPBACK_SESSION';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);
  private storage = inject(BrowserStorageService);
  private pairingTokens = inject(PairingTokenExtractorService);
  private toastService = inject(ToastService);

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
    this.toastService.show('Session ended.', 'info');
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  verifyToken(token: string): Observable<AuthVerifyResponse> {
    return this.http
      .post<AuthVerifyResponse>('/api/auth/verify', { token })
      .pipe(
        tap({
          next: () => {
            this.setToken(token);
            this.toastService.show('Device paired successfully!', 'success');
          },
          error: (err) => {
            const message =
              err?.error?.message ||
              'Pairing failed. Invalid or expired token.';
            this.toastService.show(message, 'error');
          },
        })
      );
  }

  private bootstrapLocalAccess(): void {
    const isLocalhost =
      window.location.hostname === 'localhost' ||
      window.location.hostname === '127.0.0.1';
    if (isLocalhost && !this.getToken()) {
      this.setToken(LOOPBACK_TOKEN);
    }
  }

  captureUrlToken(): Observable<AuthVerifyResponse> | null {
    const urlToken = this.pairingTokens.extractAndClean();
    return urlToken ? this.verifyToken(urlToken) : null;
  }
}
