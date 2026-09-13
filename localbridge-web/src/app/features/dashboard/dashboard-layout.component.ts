import { Component, inject, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Subscription } from 'rxjs';
import { AuthService } from 'src/app/core/services/auth.service';

import { FileExplorerComponent } from '../file-explorer/file-explorer.component';
import { ConnectionComponent } from '../connection/connection.component';
import { RecentSharedComponent } from '../recent-shared/recent-shared.component';
import { FileService } from '../../core/services/file.service';

@Component({
  selector: 'app-dashboard-layout',
  standalone: true,
  imports: [
    CommonModule,
  
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
    // Mirror the service's single shared poller rather than running our own
    // interval - two components independently polling the same shared
    // FileService state was the source of the stuck "disconnected" bug.
    this.statusSubscription = this.fileService.connectionStatus$.subscribe(
      (status) => {
        this.backendLive = status.backendLive;
        this.phoneConnected = status.phoneConnected;
        this.phoneServerLive = status.phoneServerLive;
        this.phoneServerChecking = status.checking;
      }
    );
  }

  ngOnDestroy() {
    this.statusSubscription?.unsubscribe();
  }

  /** Bound to the ↻ button in the template. */
  refreshStatus() {
    this.fileService.checkNow();
  }

  logout() {
    this.authService.clearToken();
    window.location.reload();
  }
}
