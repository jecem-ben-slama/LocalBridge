import { Component, inject, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { AuthService } from './core/services/auth.service';
import { SessionService } from './core/services/session.service';
import { LoginComponent } from './features/auth/login.component';
import { DashboardLayoutComponent } from './features/dashboard/dashboard-layout.component';
import { UpdateBannerComponent } from "./features/update-banner/update-banner.component";

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, LoginComponent, DashboardLayoutComponent, UpdateBannerComponent],
  templateUrl: './app.component.html',
})
export class AppComponent implements OnInit {
  authService = inject(AuthService);
  sessionService = inject(SessionService);

  ngOnInit() {
   
    this.initializeSession();
  }

  private initializeSession(): void {
    // Try to create a session if one doesn't exist
    if (!this.sessionService.getSessionId()) {
      this.sessionService.createSession('LocalBridge Web App').subscribe({
        error: (error) => {
          console.error('[AppComponent] Failed to create session:', error);
        },
      });
    }
  }
}
