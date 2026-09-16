import { Component, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ToastService, ToastType } from 'src/app/core/services/toast.service';

@Component({
  selector: 'app-toast-container',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './toast-container.component.html',
})
export class ToastContainerComponent {
  toastService = inject(ToastService);

  private readonly icons: Record<ToastType, string> = {
    success: '✅',
    error: '❌',
    warning: '⚠️',
    info: 'ℹ️',
  };

  getIcon(type: ToastType): string {
    return this.icons[type] || 'ℹ️';
  }

  trackById(_: number, toast: { id: string }): string {
    return toast.id;
  }
}
