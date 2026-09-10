import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-connection-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './connection-header.component.html',
})
export class ConnectionHeaderComponent {
  @Input() checking = false;
  @Output() checkNow = new EventEmitter<void>();
}
