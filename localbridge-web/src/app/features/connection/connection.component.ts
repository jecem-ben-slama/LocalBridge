import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { Subscription } from 'rxjs';

import { FileService } from '../../core/services/file.service';
import { SessionService } from '../../core/services/session.service';
import { QrPairingComponent } from '../qr-pairing/qr-pairing.component';
import { ConnectionEndpointCardComponent } from './components/connection-endpoint-card/connection-endpoint-card.component';
import { ConnectionHeaderComponent } from './components/connection-header/connection-header.component';
import { ConnectionStatusCardComponent } from './components/connection-status-card/connection-status-card.component';

@Component({
  selector: 'app-connection',
  standalone: true,
  imports: [
    CommonModule,
    QrPairingComponent,
    ConnectionHeaderComponent,
    ConnectionStatusCardComponent,
    ConnectionEndpointCardComponent,
  ],
  templateUrl: './connection.component.html',
})
export class ConnectionComponent implements OnInit, OnDestroy {
  private readonly fileService = inject(FileService);
  private readonly sessionService = inject(SessionService);
  private statusSubscription?: Subscription;

  backendLive = false;
  phoneConnected = false;
  phoneServerLive = false;
  phoneServerUrl: string | null = null;
  lastChecked: Date | null = null;
  checking = false;
  disconnecting = false;

  ngOnInit() {
    this.statusSubscription = this.fileService.connectionStatus$.subscribe(
      (status) => {
        this.backendLive = status.backendLive;
        this.phoneConnected = status.phoneConnected;
        this.phoneServerLive = status.phoneServerLive;
        this.phoneServerUrl = status.phoneServerUrl;
        this.lastChecked = status.lastChecked;
        this.checking = status.checking;
      }
    );
  }

  ngOnDestroy() {
    this.statusSubscription?.unsubscribe();
  }

  checkNow() {
    this.fileService.checkNow();
  }

  /** Manually tear down the paired phone's session. */
  disconnectPhone() {
    if (!this.phoneConnected || this.disconnecting) return;

    this.disconnecting = true;
    this.sessionService.closeSession().subscribe({
      next: () => {
        this.phoneConnected = false;
        this.disconnecting = false;
        this.fileService.checkNow(); // reconcile full status from server
      },
      error: (err) => {
        console.error('[ConnectionComponent] Failed to disconnect phone:', err);
        this.disconnecting = false;
        this.fileService.checkNow();
      },
    });
  }
}
