import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-file-explorer-toolbar',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-explorer-toolbar.component.html',
})
export class FileExplorerToolbarComponent {
  @Input() title = '';
  @Input() currentPath = '';
  @Input() source: 'pc' | 'phone' = 'pc';
  @Input() pathHistoryLength = 0;
  @Input() viewMode: 'list' | 'grid' = 'list';
  @Input() isLoading = false;
  @Input() transferBusy = false;
  @Input() isUploading = false;
  @Input() searchTerm = '';
  @Input() fileTypeFilter:
    | 'all'
    | 'image'
    | 'video'
    | 'audio'
    | 'document'
    | 'folder'
    | 'file' = 'all';

  @Output() goBack = new EventEmitter<void>();
  @Output() selectSource = new EventEmitter<'pc' | 'phone'>();
  @Output() uploadToPc = new EventEmitter<void>();
  @Output() uploadToPhone = new EventEmitter<void>();
  @Output() refresh = new EventEmitter<void>();
  @Output() setViewMode = new EventEmitter<'list' | 'grid'>();
  @Output() searchTermChange = new EventEmitter<string>();
  @Output() fileTypeFilterChange = new EventEmitter<
    'all' | 'image' | 'video' | 'audio' | 'document' | 'folder' | 'file'
  >();
}
