import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import * as QRCode from 'qrcode';

import { QrPairingCardComponent } from './components/qr-pairing-card/qr-pairing-card.component';
import { QrPairingStepsComponent } from './components/qr-pairing-steps/qr-pairing-steps.component';

@Component({
  selector: 'app-qr-pairing',
  standalone: true,
  imports: [CommonModule, QrPairingCardComponent, QrPairingStepsComponent],
  templateUrl: './qr-pairing.component.html',
})
export class QrPairingComponent {
  private http = inject(HttpClient);

  qrCodeUrl: string = '';
  rawPairingUrl: string = '';
  pairingCode: string = '';
  isGeneratingQr: boolean = false;

  async generatePairingQr() {
    this.isGeneratingQr = true;
    this.http
      .get<{ pairingUrl: string; pairingCode: string }>('/api/auth/pairing-url')
      .subscribe({
        next: async (res) => {
          try {
            this.rawPairingUrl = res.pairingUrl;
            this.pairingCode = res.pairingCode || '';
            this.qrCodeUrl = await QRCode.toDataURL(res.pairingUrl, {
              width: 200,
              margin: 1,
            });
          } catch (error) {
            console.error('Failed to encode pairing URL', error);
            this.qrCodeUrl = '';
          } finally {
            this.isGeneratingQr = false;
          }
        },
        error: (err) => {
          console.error('Failed to generate pairing URL', err);
          this.isGeneratingQr = false;
        },
      });
  }
}
