import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { NavbarComponent } from './components/navbar/navbar.component';
import { FooterComponent } from './components/footer/footer.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterModule, NavbarComponent, FooterComponent],
  template: `
    <div class="app-wrapper">
      <app-navbar *ngIf="showNavbar"></app-navbar>
      <main [class.full-height]="!showNavbar">
        <router-outlet></router-outlet>
      </main>
      <app-footer *ngIf="showNavbar"></app-footer>
    </div>
  `,
  styles: [`
    .app-wrapper {
      display: flex;
      flex-direction: column;
      min-height: 100vh;
    }

    main {
      flex: 1;
      padding: 20px;
    }

    main.full-height {
      padding: 0;
      background: transparent;
    }
  `]
})
export class AppComponent implements OnInit {
  title = 'crop-ai';
  showNavbar = true;

  constructor(private router: Router) {}

  ngOnInit() {
    this.router.events.subscribe(() => {
      this.showNavbar = !this.router.url.includes('/login');
    });
  }
}

