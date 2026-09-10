import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from 'src/app/core/services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
})
export class LoginComponent implements OnInit {
  tokenInput = '';
  errorMessage = '';
  isLoading = false;
  private authService = inject(AuthService);

  ngOnInit() {
    // If we arrived via a QR code / pairing link, auto-authenticate.
    const capture$ = this.authService.captureUrlToken();
    if (!capture$) return;

    this.isLoading = true;
    capture$.subscribe({
      next: () => window.location.reload(),
      error: (err) => {
        this.isLoading = false;
        this.errorMessage =
          err.error?.message ||
          'The link token was invalid or expired. Enter it manually below.';
      },
    });
  }

  onSubmit(event: Event) {
    event.preventDefault();
    if (!this.tokenInput.trim()) return;

    this.isLoading = true;
    this.errorMessage = '';

    this.authService.verifyToken(this.tokenInput.trim()).subscribe({
      next: () => {
        this.isLoading = false;
        window.location.reload();
      },
      error: (err) => {
        this.isLoading = false;
        this.errorMessage =
          err.error?.message ||
          'Invalid or expired token. Check your Spring Boot console output.';
      },
    });
  }
}
