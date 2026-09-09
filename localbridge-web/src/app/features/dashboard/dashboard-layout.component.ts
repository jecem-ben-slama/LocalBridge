import { Component, inject, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { catchError, interval, of, Subscription, switchMap } from 'rxjs';
import { AuthService } from 'src/app/core/services/auth.service';
import { QrPairingComponent } from '../qr-pairing/qr-pairing.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { FileExplorerComponent } from '../file-explorer/file-explorer.component';
import { ConnectionComponent } from '../connection/connection.component';
import { RecentSharedComponent } from '../recent-shared/recent-shared.component';
import { FileService } from '../../core/services/file.service';

@Component({
  selector: 'app-dashboard-layout',
  standalone: true,
  imports: [
    CommonModule,
    SidebarComponent,
    QrPairingComponent,
    FileExplorerComponent,
    ConnectionComponent,
    RecentSharedComponent,
  ],
  templateUrl: './dashboard-layout.component.html',
})
export class DashboardLayoutComponent implements OnInit, OnDestroy {
  private authService = inject(AuthService);
  readonly fileService = inject(FileService);
  private statusSubscription?: Subscription;
  currentTab: 'files' | 'recent' | 'connection' | 'clipboard' = 'files';
  backendLive = false;
  phoneConnected = false;
  phoneServerLive = false;
  phoneServerChecking = false;

  ngOnInit() {
    this.refreshStatus();
    this.statusSubscription = interval(10000).subscribe(() =>
      this.refreshStatus()
    );
  }

  ngOnDestroy() {
    this.statusSubscription?.unsubscribe();
  }

  refreshStatus() {
    if (this.phoneServerChecking) return;
    this.phoneServerChecking = true;
    this.fileService.refreshPhoneServer().subscribe({
      next: (status) => {
        this.backendLive = true;
        this.phoneConnected = status.connected;
        if (!status.phoneServerUrl) {
          this.phoneServerLive = false;
          this.phoneServerChecking = false;
          return;
        }
        this.fileService
          .heartbeatPhoneServer()
          .pipe(catchError(() => of(null)))
          .subscribe((heartbeat) => {
            this.phoneServerLive = heartbeat !== null;
            this.phoneServerChecking = false;
          });
      },
      error: () => {
        this.backendLive = false;
        this.phoneConnected = false;
        this.phoneServerLive = false;
        this.phoneServerChecking = false;
      },
    });
  }

  logout() {
    this.authService.clearToken();
    window.location.reload();
  }
}
