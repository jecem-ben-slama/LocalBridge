import { Injectable, inject } from '@angular/core';
import { BrowserStorageService } from './browser-storage.service';

const DEVICE_ID_KEY = 'device_id';

/**
 * Generates and persists (per-tab, via sessionStorage) a unique identifier
 * for this web client instance. Extracted out of SessionService so device
 * identity can be reused or reasoned about independently of sessions.
 */
@Injectable({ providedIn: 'root' })
export class DeviceIdService {
  private storage = inject(BrowserStorageService);

  getOrCreate(): string {
    let deviceId = this.storage.get(DEVICE_ID_KEY, 'session');
    if (!deviceId) {
      deviceId = this.generate();
      this.storage.set(DEVICE_ID_KEY, deviceId, 'session');
    }
    return deviceId;
  }

  private generate(): string {
    return `web-${Date.now()}-${Math.random().toString(36).slice(2, 11)}`;
  }
}
