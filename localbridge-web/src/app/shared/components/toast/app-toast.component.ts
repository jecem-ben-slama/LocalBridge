import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-toast',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div
      *ngIf="message"
      class="fixed bottom-5 right-5 z-[60] max-w-sm rounded-2xl border px-4 py-3 text-sm shadow-2xl"
      [ngClass]="{
        'border-bridge-success/40 bg-bridge-success-soft': type === 'success',
        'border-bridge-error/40 bg-bridge-error-soft': type === 'error',
        'border-bridge-border bg-bridge-card': type === 'info'
      }"
    >
      {{ message }}
    </div>
  `,
})
export class AppToastComponent {
  @Input() message: string | null = null;
  @Input() type: 'success' | 'error' | 'info' = 'info';
}
