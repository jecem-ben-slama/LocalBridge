import { Component, inject, Input, OnDestroy, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { DomSanitizer, SafeResourceUrl } from '@angular/platform-browser';
import { interval, Subscription, switchMap, catchError, of } from 'rxjs';
import { FileService } from '../../core/services/file.service';
import { FileNode } from 'src/app/model/filenode';
import { FileEmptyStateComponent } from './components/file-empty-state/file-empty-state.component';
import { FileExplorerToolbarComponent } from './components/file-explorer-toolbar/file-explorer-toolbar.component';
import { FileGridComponent } from './components/file-grid/file-grid.component';
import { FileListComponent } from './components/file-list/file-list.component';
import { FileTransferProgressComponent } from './components/file-transfer-progress/file-transfer-progress.component';

@Component({
  selector: 'app-file-explorer',
  standalone: true,
  imports: [
    CommonModule,
    FileExplorerToolbarComponent,
    FileTransferProgressComponent,
    FileListComponent,
    FileGridComponent,
    FileEmptyStateComponent,
  ],
  templateUrl: './file-explorer.component.html',
})
export class FileExplorerComponent implements OnInit, OnDestroy {
  readonly fileService = inject(FileService);
  private sanitizer = inject(DomSanitizer);

  @Input() initialPath = '';
  @Input() title = '';

  files: FileNode[] = [];
  currentPath: string = '';
  pathHistory: string[] = [];
  isLoading: boolean = false;
  errorMessage: string | null = null;
  viewMode: 'grid' | 'list' = 'list';
  source: 'pc' | 'phone' = 'pc';
  searchTerm = '';
  fileTypeFilter:
    | 'all'
    | 'image'
    | 'video'
    | 'audio'
    | 'document'
    | 'folder'
    | 'file' = 'all';

  uploadProgressMap: { [fileName: string]: number } = {};
  isUploading: boolean = false;
  downloadProgress = 0;
  downloadingFileName: string | null = null;
  previewFile: FileNode | null = null;
  previewUrl: SafeResourceUrl | null = null;
  previewKind: 'image' | 'video' | 'audio' | 'document' | 'browser' = 'browser';
  toastMessage: string | null = null;
  toastType: 'success' | 'error' | 'info' = 'info';
  private toastTimer?: ReturnType<typeof setTimeout>;
  private directoryRequest?: Subscription;
  private directoryRequestVersion = 0;
  private phoneHeartbeat?: Subscription;
  private transferState?: Subscription;
  private lastTransferState?: {
    active: boolean;
    kind: string | null;
    fileName: string | null;
    progress: number;
    error: string | null;
    cancelled: boolean;
  };
  private phoneRefresh?: Subscription;
  private phoneServerWasAvailable = false;
  private phoneServerStopAlertShown = false;

  ngOnInit() {
    this.transferState = this.fileService.transferState$.subscribe((state) => {
      const wasBusy = !!this.lastTransferState?.active;
      const justFinished = wasBusy && !state.active;

      this.isUploading = state.active && state.kind === 'upload';
      this.downloadingFileName =
        state.active && state.kind === 'download' ? state.fileName : null;
      this.downloadProgress = state.progress;
      if (this.isUploading && state.fileName) {
        this.uploadProgressMap = { [state.fileName]: state.progress };
      } else if (!this.isUploading) {
        this.uploadProgressMap = {};
      }

      if (justFinished) {
        if (state.error) {
          this.showToast(
            this.friendlyError(
              state.error,
              'Transfer failed. Please try again.'
            ),
            'error'
          );
        } else if (state.cancelled) {
          this.showToast('Transfer cancelled.', 'info');
        } else {
          const action = state.kind === 'upload' ? 'Upload' : 'Download';
          const file = state.fileName || 'file';
          this.showToast(
            `${action} of ${file} finished successfully.`,
            'success'
          );
        }
      }

      this.lastTransferState = state;
    });
    this.loadFiles(this.initialPath || undefined);
  }

  ngOnDestroy() {
    this.directoryRequest?.unsubscribe();
    this.phoneHeartbeat?.unsubscribe();
    this.transferState?.unsubscribe();
    this.phoneRefresh?.unsubscribe();
    if (this.toastTimer) clearTimeout(this.toastTimer);
  }

  loadFiles(path?: string) {
    const requestVersion = ++this.directoryRequestVersion;
    const requestedSource = this.source;
    this.directoryRequest?.unsubscribe();
    this.isLoading = true;
    this.errorMessage = null;

    this.directoryRequest = this.fileService
      .getDirectoryContents(path, requestedSource)
      .subscribe({
        next: (response) => {
          if (
            requestVersion !== this.directoryRequestVersion ||
            requestedSource !== this.source
          ) {
            return;
          }
          if (!response.success) {
            this.files = [];
            this.errorMessage =
              response.message || 'Failed to load directory contents.';
          } else if (Array.isArray(response.data)) {
            this.files = response.data.filter(
              (file) =>
                !file.name.startsWith('.') &&
                file.name.toLowerCase() !== '.files'
            );
            this.currentPath = path || '';
          } else {
            this.files = [];
            this.errorMessage =
              'The phone returned an invalid directory listing.';
          }
          this.isLoading = false;
        },
        error: (err) => {
          if (
            requestVersion !== this.directoryRequestVersion ||
            requestedSource !== this.source
          ) {
            return;
          }
          this.errorMessage =
            err.error?.message || 'Failed to load directory contents.';
          this.isLoading = false;
        },
      });
  }

  refreshCurrentFolder() {
    this.loadFiles(this.currentPath || undefined);
  }

  openNode(node: FileNode) {
    if (node.isDirectory) {
      this.pathHistory.push(this.currentPath);
      this.loadFiles(node.path);
    } else {
      this.openPreview(node);
    }
  }

  downloadFile(node: FileNode, event?: MouseEvent) {
    event?.stopPropagation();
    this.saveFile(node);
  }

  downloadSelectedFile(node: FileNode) {
    this.saveFile(node);
  }

  private saveFile(node: FileNode) {
    if (!this.fileService.startDownload(node.path, this.source)) return;
  }

  private showToast(message: string, type: 'success' | 'error' | 'info') {
    this.toastMessage = message;
    this.toastType = type;
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => (this.toastMessage = null), 4500);
  }

  private friendlyError(error: any, fallback: string) {
    const message = error?.error?.message || error?.message;
    if (typeof message === 'string' && message.trim()) {
      if (message.includes('Maximum upload size')) {
        return 'That file is too large. The maximum upload size is 10 GB.';
      }
      return message;
    }
    return fallback;
  }

  openPreview(node: FileNode) {
    const extension = node.name.split('.').pop()?.toLowerCase() || '';
    this.previewKind = this.isImageFile(node.name)
      ? 'image'
      : ['mp4', 'webm', 'mov', 'mkv', 'avi'].includes(extension)
      ? 'video'
      : ['mp3', 'wav', 'ogg', 'm4a'].includes(extension)
      ? 'audio'
      : ['pdf', 'txt', 'csv', 'json', 'html'].includes(extension)
      ? 'document'
      : 'browser';
    this.previewFile = node;
    this.previewUrl = this.sanitizer.bypassSecurityTrustResourceUrl(
      this.fileService.getDownloadUrl(node.path, this.source)
    );
  }

  closePreview() {
    this.previewFile = null;
    this.previewUrl = null;
  }

  selectSource(source: 'pc' | 'phone') {
    if (this.source === source) return;
    this.source = source;
    this.pathHistory = [];
    this.phoneRefresh?.unsubscribe();
    if (source === 'phone') {
      this.phoneRefresh = this.fileService.refreshPhoneServer().subscribe({
        next: () => {
          this.phoneServerWasAvailable = true;
          this.phoneServerStopAlertShown = false;
          this.startPhoneHeartbeat();
          this.loadFiles();
        },
        error: () => this.loadFiles(),
      });
    } else {
      this.phoneHeartbeat?.unsubscribe();
      this.loadFiles();
    }
  }

  private startPhoneHeartbeat() {
    this.phoneHeartbeat?.unsubscribe();
    this.phoneHeartbeat = interval(10000)
      .pipe(
        switchMap(() => this.fileService.heartbeatPhoneServer()),
        catchError(() => {
          if (this.phoneServerWasAvailable && !this.phoneServerStopAlertShown) {
            this.phoneServerStopAlertShown = true;
            this.showToast(
              'The phone server stopped. Phone files are no longer available.',
              'error'
            );
          }
          this.phoneServerWasAvailable = false;
          return of(null);
        })
      )
      .subscribe();
  }

  goBack() {
    const previousPath = this.pathHistory.pop() || '';
    this.loadFiles(previousPath === '' ? undefined : previousPath);
  }

  onFileSelected(event: any, destination: 'pc' | 'phone' = 'pc') {
    if (this.fileService.transferBusy) return;
    const selectedFiles: FileList = event.target.files;
    if (!selectedFiles || selectedFiles.length === 0) return;
    this.fileService.startUpload(
      this.currentPath,
      selectedFiles[0],
      destination
    );
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
      if (this.fileTypeFilter === 'folder') return file.isDirectory;
      if (this.fileTypeFilter === 'file') return !file.isDirectory;

      if (file.isDirectory) return false;
      if (this.fileTypeFilter === 'image') return this.isImageFile(file.name);
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

  isImageFile(fileName: string): boolean {
    const ext = this.getExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].includes(ext || '');
  }

  getThumbnailUrl(path: string): string {
    return this.fileService.getThumbnailUrl(path, this.source);
  }

  private getExtension(fileName: string): string {
    return fileName.split('.').pop()?.toLowerCase() || '';
  }

  formatSize(bytes?: number): string {
    if (!bytes || bytes === 0) return '--';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  }
}
