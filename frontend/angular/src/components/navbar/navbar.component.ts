import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router } from '@angular/router';
import { AuthService, User } from '../../services/auth.service';

@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <nav class="navbar">
      <div class="navbar-content">
        <div class="navbar-brand">
          <span class="brand-icon">🌾</span>
          <span class="brand-name">CropAI</span>
        </div>

        <div class="navbar-items">
          <div *ngIf="currentUser" class="user-info">
            <span class="user-role" [class]="currentUser.role">{{ getRoleDisplay(currentUser.role) }}</span>
            <span class="user-name">{{ currentUser.name }}</span>
            <button class="btn-logout" (click)="logout()">{{ t('logout') }}</button>
          </div>
        </div>
      </div>
    </nav>
  `,
  styles: [`
    .navbar {
      background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%);
      padding: 0;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      position: sticky;
      top: 0;
      z-index: 100;
    }

    .navbar-content {
      max-width: 1200px;
      margin: 0 auto;
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 12px 20px;
    }

    .navbar-brand {
      display: flex;
      align-items: center;
      gap: 10px;
      color: white;
      font-size: 18px;
      font-weight: bold;
    }

    .brand-icon { font-size: 24px; }

    .navbar-items {
      display: flex;
      gap: 20px;
      align-items: center;
    }

    .user-info {
      display: flex;
      align-items: center;
      gap: 12px;
      color: white;
      font-size: 14px;
    }

    .user-role {
      background: rgba(255,255,255,0.2);
      padding: 4px 8px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: 600;
    }

    .user-role.farmer { background: rgba(76, 175, 80, 0.3); }
    .user-role.partner { background: rgba(33, 150, 243, 0.3); }
    .user-role.customer { background: rgba(255, 152, 0, 0.3); }
    .user-role.callcenter { background: rgba(156, 39, 176, 0.3); }
    .user-role.techsupport { background: rgba(0, 150, 136, 0.3); }
    .user-role.admin { background: rgba(244, 67, 54, 0.3); }

    .user-name {
      font-weight: 600;
    }

    .btn-logout {
      background: rgba(255,255,255,0.2);
      color: white;
      border: 1px solid rgba(255,255,255,0.5);
      padding: 6px 12px;
      border-radius: 4px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 600;
      transition: all 0.3s;
    }

    .btn-logout:hover {
      background: rgba(255,255,255,0.3);
      transform: scale(1.05);
    }

    @media (max-width: 768px) {
      .user-info {
        flex-direction: column;
        gap: 8px;
      }
      .btn-logout {
        width: 100%;
      }
    }
  `]
})
export class NavbarComponent implements OnInit {
  currentUser: User | null = null;

  constructor(
    private auth: AuthService,
    private router: Router
  ) {}

  ngOnInit() {
    this.auth.getCurrentUser().subscribe(user => {
      this.currentUser = user;
    });
  }

  getRoleDisplay(role: string): string {
    const roleMap: { [key: string]: string } = {
      'farmer': '👨‍🌾 Farmer',
      'partner': '🤝 Partner',
      'customer': '🛒 Customer',
      'callcenter': '📞 Call Center',
      'techsupport': '🔧 Tech Support',
      'admin': '👨‍💼 Admin'
    };
    return roleMap[role] || role;
  }

  logout() {
    this.auth.logout();
    this.router.navigate(['/login']);
  }

  t(key: string): string {
    const translations: { [key: string]: string } = {
      'logout': 'Logout'
    };
    return translations[key] || key;
  }
}
