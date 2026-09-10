import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-connection-endpoint-card',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './connection-endpoint-card.component.html',
})
export class ConnectionEndpointCardComponent {
  @Input() phoneServerUrl: string | null = null;
  @Input() lastChecked: Date | null = null;
}
