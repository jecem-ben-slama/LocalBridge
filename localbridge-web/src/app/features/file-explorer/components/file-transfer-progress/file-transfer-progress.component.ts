import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-file-transfer-progress',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-transfer-progress.component.html',
})
export class FileTransferProgressComponent {
  @Input() title = '';
  @Input() progress = 0;
  @Input() fileName: string | null = null;
  @Input() showCancel = false;
  @Input() kind: 'download' | 'upload' = 'download';
  @Output() cancel = new EventEmitter<void>();
}
