import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { Subscription } from 'rxjs';

import { FileService } from '../../core/services/file.service';
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
  private statusSubscription?: Subscription;

  backendLive = false;
  phoneConnected = false;
  phoneServerLive = false;
  phoneServerUrl: string | null = null;
  lastChecked: Date | null = null;
  checking = false;

  ngOnInit() {
    // Subscribe to the shared poller instead of running a second independent
    // interval - see FileService.connectionStatus$ for the polling logic.
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

  /** Manual "refresh now" button in the template. */
  checkNow() {
    this.fileService.checkNow();
  }
}
