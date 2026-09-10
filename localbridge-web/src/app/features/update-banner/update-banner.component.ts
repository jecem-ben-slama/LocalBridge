import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UpdateService } from 'src/app/core/services/update.service';

@Component({
  selector: 'app-update-banner',
  standalone: true,
  imports: [CommonModule], // CommonModule provides *ngIf
  templateUrl: './update-banner.component.html',
})
export class UpdateBannerComponent implements OnInit {
  protected updateService = inject(UpdateService);

  ngOnInit(): void {
    this.updateService.checkForUpdates();
  }
}
