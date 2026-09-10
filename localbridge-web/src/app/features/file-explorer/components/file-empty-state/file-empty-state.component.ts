import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';

@Component({
  selector: 'app-file-empty-state',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-empty-state.component.html',
})
export class FileEmptyStateComponent {
  @Input() label = 'This folder is empty.';
}
