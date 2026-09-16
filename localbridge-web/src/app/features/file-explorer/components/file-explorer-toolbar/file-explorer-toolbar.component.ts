import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';

export interface QuickLink {
  id: string;
  label: string;
  path: string;
  icon: string;
  source: 'pc' | 'phone';
}

export type FileTypeFilter =
  | 'all'
  | 'image'
  | 'video'
  | 'audio'
  | 'document'
  | 'folder'
  | 'file';

export const AVAILABLE_ICONS = [
  { id: 'folder', name: 'Folder' },
  { id: 'desktop', name: 'Desktop' },
  { id: 'download', name: 'Download' },
  { id: 'document', name: 'Document' },
  { id: 'image', name: 'Image' },
  { id: 'video', name: 'Video' },
  { id: 'music', name: 'Music' },
  { id: 'star', name: 'Star' },
  { id: 'bookmark', name: 'Bookmark' },
  { id: 'share', name: 'Share' },
  { id: 'link', name: 'Link' },
];

const STORAGE_KEY = 'localbridge_custom_shortcuts';

@Component({
  selector: 'app-file-explorer-toolbar',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './file-explorer-toolbar.component.html',
})
export class FileExplorerToolbarComponent implements OnInit {
  @Input() title = '';
  @Input() currentPath = '';
  @Input() source: 'pc' | 'phone' = 'pc';
  @Input() pathHistoryLength = 0;
  @Input() viewMode: 'list' | 'grid' = 'list';
  @Input() isLoading = false;
  @Input() transferBusy = false;
  @Input() isUploading = false;
  @Input() searchTerm = '';

  @Input() fileTypeFilter: FileTypeFilter = 'all';

  @Output() goBack = new EventEmitter<void>();
  @Output() selectSource = new EventEmitter<'pc' | 'phone'>();
  @Output() uploadToPhone = new EventEmitter<any>();
  @Output() refresh = new EventEmitter<void>();
  @Output() setViewMode = new EventEmitter<'list' | 'grid'>();
  @Output() searchTermChange = new EventEmitter<string>();
  @Output() fileTypeFilterChange = new EventEmitter<FileTypeFilter>();
  @Output() navigateToPath = new EventEmitter<string>();

  isQuickLinksOpen = true;
  isAddModalOpen = false;

  quickLinks: QuickLink[] = [];
  availableIcons = AVAILABLE_ICONS;

  newLabel = '';
  newPath = '';
  newIcon = 'folder';
  formError: string | null = null;

  ngOnInit(): void {
    this.loadQuickLinks();
  }

  get filteredQuickLinks(): QuickLink[] {
    return this.quickLinks.filter((link) => link.source === this.source);
  }

  /**
   * Breaks currentPath into clickable breadcrumb segments.
   *
   * Handles Windows-style paths:
   *   C:\Users\Dev
   *
   * And POSIX-style paths:
   *   /storage/emulated/0
   */
  get pathSegments(): { label: string; path: string }[] {
    if (!this.currentPath) {
      return [];
    }

    const normalized = this.currentPath.replace(/\\/g, '/');
    const isWindowsPath = /^[a-zA-Z]:/.test(normalized);
    const isPosixAbsolute = !isWindowsPath && normalized.startsWith('/');
    const parts = normalized.split('/').filter(Boolean);

    const segments: { label: string; path: string }[] = [];
    let acc = '';

    parts.forEach((part, index) => {
      if (index === 0 && isWindowsPath) {
        // A bare drive letter like "C:" is NOT an absolute path to the
        // underlying filesystem APIs (Paths.get("C:").isAbsolute() is
        // false on Windows - it means "current dir on that drive").
        // Only "C:/" (drive root, trailing separator) is absolute, so
        // the drive-root breadcrumb must keep the trailing slash.
        acc = `${part}/`;
      } else if (index === 0 && isPosixAbsolute) {
        // POSIX split() drops the leading empty string from the
        // leading '/', so the first segment must have it reattached
        // or the path stops being absolute too.
        acc = `/${part}`;
      } else {
        acc = acc ? `${acc}/${part}` : part;
      }

      segments.push({
        label: part,
        path: acc,
      });
    });

    return segments;
  }

  onBreadcrumbClick(path: string): void {
    if (path === this.currentPath) {
      return;
    }

    this.navigateToPath.emit(path);
  }

  onQuickLinkClick(path: string): void {
    this.navigateToPath.emit(path);
  }

  clearSearch(): void {
    this.searchTermChange.emit('');
  }

  openAddModal(prefillCurrentPath = false): void {
    if (prefillCurrentPath && this.currentPath) {
      this.newPath = this.currentPath;

      const parts = this.currentPath.replace(/\\/g, '/').split('/');

      this.newLabel = parts[parts.length - 1] || 'New Shortcut';
    } else {
      this.newLabel = '';
      this.newPath = '';
    }

    this.newIcon = 'folder';
    this.formError = null;
    this.isAddModalOpen = true;
  }

  closeAddModal(): void {
    this.isAddModalOpen = false;
    this.formError = null;
  }

  saveShortcut(): void {
    const label = this.newLabel.trim();
    const path = this.newPath.trim();

    if (!label || !path) {
      return;
    }

    const isDuplicate = this.quickLinks.some(
      (link) =>
        link.source === this.source &&
        link.label.toLowerCase() === label.toLowerCase()
    );

    if (isDuplicate) {
      this.formError =
        `A ${this.source === 'pc' ? 'PC' : 'Phone'} shortcut ` +
        `named "${label}" already exists.`;

      return;
    }

    const newShortcut: QuickLink = {
      id: 'shortcut_' + Date.now(),
      label,
      path,
      icon: this.newIcon,
      source: this.source,
    };

    this.quickLinks.push(newShortcut);
    this.persistQuickLinks();
    this.closeAddModal();
  }

  deleteShortcut(id: string, event: MouseEvent): void {
    event.stopPropagation();

    this.quickLinks = this.quickLinks.filter((link) => link.id !== id);

    this.persistQuickLinks();
  }

  toggleQuickLinks(): void {
    this.isQuickLinksOpen = !this.isQuickLinksOpen;
  }

  private loadQuickLinks(): void {
    const saved = localStorage.getItem(STORAGE_KEY);

    if (!saved) {
      this.quickLinks = [];
      return;
    }

    try {
      const parsed = JSON.parse(saved) as QuickLink[];

      this.quickLinks = parsed.map((link) => ({
        ...link,
        source: link.source || 'pc',
      }));
    } catch (error) {
      console.error('Failed to parse shortcuts', error);
      this.quickLinks = [];
    }
  }

  private persistQuickLinks(): void {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(this.quickLinks));
  }
}
