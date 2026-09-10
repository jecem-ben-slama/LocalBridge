import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { FileService } from '../../core/services/file.service';
import { FileNode } from '../../model/filenode';
import { AppToastComponent } from '../../shared/components/toast/app-toast.component';
import { FilePreviewModalComponent } from '../../shared/components/file-preview-modal/file-preview-modal.component';

@Component({
  selector: 'app-recent-shared',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    AppToastComponent,
    FilePreviewModalComponent,
  ],
  templateUrl: './recent-shared.component.html',
})
export class RecentSharedComponent implements OnInit {
  private readonly fileService = inject(FileService);
  private readonly sanitizer = inject(DomSanitizer);

  files: FileNode[] = [];
  loading = true;
  error: string | null = null;
  searchTerm = '';
  fileTypeFilter: 'all' | 'image' | 'video' | 'audio' | 'document' | 'file' =
    'all';
  previewFile: FileNode | null = null;
  previewUrl: SafeResourceUrl | null = null;
  previewKind: 'image' | 'video' | 'audio' | 'document' | 'browser' = 'browser';
  toastMessage: string | null = null;
  toastType: 'success' | 'error' | 'info' = 'info';
  private toastTimer?: ReturnType<typeof setTimeout>;

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
      this.showToast('Download started.', 'success');
    } catch (error) {
      this.error = error instanceof Error ? error.message : 'Download failed.';
      this.showToast(this.error, 'error');
    }
  }

  openPreview(file: FileNode) {
    const extension = file.name.split('.').pop()?.toLowerCase() || '';
    this.previewKind = this.isImage(file)
      ? 'image'
      : ['mp4', 'webm', 'mov', 'mkv', 'avi'].includes(extension)
      ? 'video'
      : ['mp3', 'wav', 'ogg', 'm4a'].includes(extension)
      ? 'audio'
      : ['pdf', 'txt', 'csv', 'json', 'html'].includes(extension)
      ? 'document'
      : 'browser';
    this.previewFile = file;
    this.previewUrl = this.sanitizer.bypassSecurityTrustResourceUrl(
      this.fileService.getDownloadUrl(file.path, 'pc')
    );
  }

  closePreview() {
    this.previewFile = null;
    this.previewUrl = null;
  }

  private showToast(message: string, type: 'success' | 'error' | 'info') {
    this.toastMessage = message;
    this.toastType = type;
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => (this.toastMessage = null), 4500);
  }

  get filteredFiles(): FileNode[] {
    const term = this.searchTerm.trim().toLowerCase();

    return this.files.filter((file) => {
      const matchesSearch =
        !term ||
        file.name.toLowerCase().includes(term) ||
        file.path.toLowerCase().includes(term);

      if (!matchesSearch) return false;

      if (this.fileTypeFilter === 'all') return true;
      if (this.fileTypeFilter === 'file') return !file.isDirectory;

      if (file.isDirectory) return false;
      if (this.fileTypeFilter === 'image') return this.isImage(file);
      if (this.fileTypeFilter === 'video')
        return ['mp4', 'webm', 'mov', 'mkv', 'avi'].includes(
          this.getExtension(file.name)
        );
      if (this.fileTypeFilter === 'audio')
        return ['mp3', 'wav', 'ogg', 'm4a'].includes(
          this.getExtension(file.name)
        );
      if (this.fileTypeFilter === 'document')
        return [
          'pdf',
          'txt',
          'csv',
          'json',
          'html',
          'md',
          'doc',
          'docx',
          'ppt',
          'pptx',
        ].includes(this.getExtension(file.name));

      return true;
    });
  }

  isImage(file: FileNode) {
    return /\.(png|jpe?g|gif|webp|bmp)$/i.test(file.name);
  }

  thumbnail(file: FileNode) {
    return this.fileService.getThumbnailUrl(file.path, 'pc');
  }

  private getExtension(fileName: string): string {
    return fileName.split('.').pop()?.toLowerCase() || '';
  }

  private toTime(value?: number) {
    return typeof value === 'number' && Number.isFinite(value) ? value : 0;
  }
}
