import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FileService } from '../../core/services/file.service';
import { FileNode } from '../../model/filenode';

@Component({
  selector: 'app-recent-shared',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './recent-shared.component.html',
})
export class RecentSharedComponent implements OnInit {
  private readonly fileService = inject(FileService);

  files: FileNode[] = [];
  loading = true;
  error: string | null = null;

  ngOnInit() {
    this.reload();
  }

  reload() {
    this.loading = true;
    this.error = null;
    this.fileService.getDirectoryContents('LocalBridge', 'pc').subscribe({
      next: (response) => {
        this.files =
          response.success && Array.isArray(response.data)
            ? response.data
                .filter((file) => !file.isDirectory)
                .sort(
                  (left, right) =>
                    this.toTime(right.lastModified) -
                    this.toTime(left.lastModified)
                )
            : [];
        this.error = response.success ? null : response.message;
        this.loading = false;
      },
      error: (error) => {
        this.error = error.error?.message || 'Could not load shared files.';
        this.loading = false;
      },
    });
  }

  async download(file: FileNode) {
    try {
      await this.fileService.saveDownload(file.path, 'pc');
    } catch (error) {
      this.error = error instanceof Error ? error.message : 'Download failed.';
    }
  }

  isImage(file: FileNode) {
    return /\.(png|jpe?g|gif|webp|bmp)$/i.test(file.name);
  }

  thumbnail(file: FileNode) {
    return this.fileService.getThumbnailUrl(file.path, 'pc');
  }

  private toTime(value?: number) {
    return typeof value === 'number' && Number.isFinite(value) ? value : 0;
  }
}
