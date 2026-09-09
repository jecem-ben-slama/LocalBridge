import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../core/services/auth.service';

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
    // If user arrived via a QR code link containing the token, auto-authenticate and reload
    if (this.authService.handleUrlTokenCapture()) {
      window.location.reload();
    }
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
