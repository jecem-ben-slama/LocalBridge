import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { FileNode } from 'src/app/model/filenode';
import { FileService } from 'src/app/core/services/file.service';

@Component({
  selector: 'app-file-list',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-list.component.html',
})
export class FileListComponent {
  private readonly fileService = inject(FileService);

  @Input() files: FileNode[] = [];
  @Input() source: 'pc' | 'phone' = 'pc';
  @Input() transferBusy = false;
  @Output() openNode = new EventEmitter<FileNode>();
  @Output() downloadFile = new EventEmitter<FileNode>();

  isImageFile(fileName: string): boolean {
    const ext = fileName.split('.').pop()?.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].includes(ext || '');
  }

  getThumbnailUrl(path: string): string {
    return this.fileService.getThumbnailUrl(path, this.source);
  }

  formatSize(bytes?: number): string {
    if (!bytes || bytes === 0) return '--';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
}
