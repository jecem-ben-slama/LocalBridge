import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sidebar.component.html',
})
export class SidebarComponent {
  @Input() currentTab: 'files' | 'recent' | 'connection' | 'clipboard' =
    'files';
  @Output() tabChange = new EventEmitter<
    'files' | 'recent' | 'connection' | 'clipboard'
  >();
  @Output() onLogout = new EventEmitter<void>();

  isMobileMenuOpen = false;

  toggleMobileMenu() {
    this.isMobileMenuOpen = !this.isMobileMenuOpen;
  }

  selectTab(tab: 'files' | 'recent' | 'connection' | 'clipboard') {
    this.tabChange.emit(tab);
    this.isMobileMenuOpen = false; // Auto-close drawer on mobile when tab is picked
  }
}
