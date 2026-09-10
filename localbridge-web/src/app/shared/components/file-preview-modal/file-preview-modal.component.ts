import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { SafeResourceUrl } from '@angular/platform-browser';
import { FileNode } from 'src/app/model/filenode';

@Component({
  selector: 'app-file-preview-modal',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-preview-modal.component.html',
})
export class FilePreviewModalComponent {
  @Input() file: FileNode | null = null;
  @Input() previewUrl: SafeResourceUrl | null = null;
  @Input() previewKind: 'image' | 'video' | 'audio' | 'document' | 'browser' =
    'browser';
  @Input() downloadDisabled = false;

  @Output() close = new EventEmitter<void>();
  @Output() download = new EventEmitter<FileNode>();

  onDownload() {
    if (this.file) {
      this.download.emit(this.file);
    }
  }
}
