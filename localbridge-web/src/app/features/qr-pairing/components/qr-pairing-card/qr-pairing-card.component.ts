import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-qr-pairing-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './qr-pairing-card.component.html',
})
export class QrPairingCardComponent {
  @Input() qrCodeUrl = '';
  @Input() pairingCode = '';
  @Input() rawPairingUrl = '';
}
