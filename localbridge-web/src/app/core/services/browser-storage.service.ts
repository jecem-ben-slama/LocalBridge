import { Injectable, PLATFORM_ID, inject } from '@angular/core';
import { isPlatformBrowser } from '@angular/common';

export type StorageArea = 'local' | 'session';

/**
 * Thin, injectable wrapper around window.localStorage / window.sessionStorage.
 *
 * Every feature service should depend on this instead of touching the global
 * `localStorage`/`sessionStorage` objects directly. That gives us:
 *  - a single SSR-safety check instead of one per call site
 *  - one seam to mock in unit tests
 *  - one place to change persistence strategy later (e.g. IndexedDB)
 */
@Injectable({ providedIn: 'root' })
export class BrowserStorageService {
  private readonly isBrowser = isPlatformBrowser(inject(PLATFORM_ID));

  get(key: string, area: StorageArea = 'local'): string | null {
    if (!this.isBrowser) return null;
    return this.storageFor(area).getItem(key);
  }

  set(key: string, value: string, area: StorageArea = 'local'): void {
    if (!this.isBrowser) return;
    this.storageFor(area).setItem(key, value);
  }

  remove(key: string, area: StorageArea = 'local'): void {
    if (!this.isBrowser) return;
    this.storageFor(area).removeItem(key);
  }

  private storageFor(area: StorageArea): Storage {
    return area === 'local' ? window.localStorage : window.sessionStorage;
  }
}
