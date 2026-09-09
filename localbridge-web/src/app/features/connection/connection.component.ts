import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, inject } from '@angular/core';
import { interval, Subscription, catchError, of, switchMap } from 'rxjs';

import { FileService } from '../../core/services/file.service';
import { QrPairingComponent } from '../qr-pairing/qr-pairing.component';

@Component({
  selector: 'app-connection',
  standalone: true,
  imports: [CommonModule, QrPairingComponent],
  templateUrl: './connection.component.html',
})
export class ConnectionComponent implements OnInit, OnDestroy {
  private readonly fileService = inject(FileService);
  private refreshSubscription?: Subscription;

  backendLive = false;
  phoneConnected = false;
  phoneServerLive = false;
  phoneServerUrl: string | null = null;
  lastChecked: Date | null = null;
  checking = false;

  ngOnInit() {
    this.checkNow();
    this.refreshSubscription = interval(10000).subscribe(() => this.checkNow());
  }

  ngOnDestroy() {
    this.refreshSubscription?.unsubscribe();
  }

  checkNow() {
    if (this.checking) return;
    this.checking = true;
    this.fileService.refreshPhoneServer().subscribe({
      next: (status) => {
        this.backendLive = true;
        this.phoneConnected = status.connected;
        this.phoneServerUrl = status.phoneServerUrl;
        if (!status.phoneServerUrl) {
          this.phoneServerLive = false;
          this.finishCheck();
          return;
        }
        this.fileService
          .heartbeatPhoneServer()
          .pipe(catchError(() => of(null)))
          .subscribe((heartbeat) => {
            this.phoneServerLive = heartbeat !== null;
            this.finishCheck();
          });
      },
      error: () => {
        this.backendLive = false;
        this.phoneConnected = false;
        this.phoneServerLive = false;
        this.finishCheck();
      },
    });
  }

  private finishCheck() {
    this.lastChecked = new Date();
    this.checking = false;
  }
}
