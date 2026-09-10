import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

export type ConnectionStatusTone = 'success' | 'danger' | 'warning' | 'neutral';

@Component({
  selector: 'app-connection-status-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './connection-status-card.component.html',
})
export class ConnectionStatusCardComponent {
  @Input() label = '';
  @Input() value = '';
  @Input() detail = '';
  @Input() badge = '';
  @Input() tone: ConnectionStatusTone = 'neutral';
}
