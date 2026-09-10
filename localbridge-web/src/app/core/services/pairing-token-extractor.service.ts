import { Injectable } from '@angular/core';
import { PAIRING_TOKEN_PARAMS } from 'src/app/model/auth.model';

/**
 * Extracts a pairing token from the current URL's query string (delivered
 * via QR code / pairing link) and scrubs it from the address bar afterwards
 * so it isn't left visible in the URL or bookmarkable with the token inside.
 */
@Injectable({ providedIn: 'root' })
export class PairingTokenExtractorService {
  extractAndClean(): string | null {
    const params = new URLSearchParams(window.location.search);
    const token = PAIRING_TOKEN_PARAMS.map((key) => params.get(key)).find(Boolean) ?? null;

    if (token) {
      window.history.replaceState({}, document.title, window.location.pathname);
    }
    return token;
  }
}
