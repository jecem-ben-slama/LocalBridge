import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

export interface UpdateStatusDto {
  currentVersion: string;
  latestVersion: string;
  updateAvailable: boolean;
  releaseUrl: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

const DISMISS_KEY = 'localbridge_update_dismissed_at';
const TWENTY_FOUR_HOURS_MS = 24 * 60 * 60 * 1000;

@Injectable({
  providedIn: 'root',
})
export class UpdateService {
  private updateState = signal<UpdateStatusDto | null>(null);
  private dismissed = signal<boolean>(this.isDismissalValid());

  readonly updateInfo = this.updateState.asReadonly();
  readonly hasUpdate = computed(() => {
    const state = this.updateState();
    return !!state?.updateAvailable && !this.dismissed();
  });

  constructor(private http: HttpClient) {}

  async checkForUpdates(): Promise<void> {
    try {
      const response = await firstValueFrom(
        this.http.get<ApiResponse<UpdateStatusDto>>('/api/update/check')
      );
      console.log('Update check response:', response);

      if (response?.success && response.data) {
        this.updateState.set(response.data);
      }
    } catch (error) {
      console.debug('Update check skipped or failed:', error);
    }
  }

  /**
   * Hide banner and store timestamp in localStorage for 24h
   */
  dismissBanner(): void {
    localStorage.setItem(DISMISS_KEY, Date.now().toString());
    this.dismissed.set(true);
  }

  /**
   * Checks if a valid non-expired dismissal exists in localStorage
   */
  private isDismissalValid(): boolean {
    const savedTimestamp = localStorage.getItem(DISMISS_KEY);
    if (!savedTimestamp) return false;

    const dismissedAt = parseInt(savedTimestamp, 10);
    const isStillValid = Date.now() - dismissedAt < TWENTY_FOUR_HOURS_MS;

    if (!isStillValid) {
      localStorage.removeItem(DISMISS_KEY);
    }

    return isStillValid;
  }
}
