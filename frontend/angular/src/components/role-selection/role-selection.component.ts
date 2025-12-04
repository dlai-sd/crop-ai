import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService, User } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';

type RoleType = 'farmer' | 'partner' | 'customer' | 'callcenter' | 'techsupport' | 'admin';

@Component({
  selector: 'app-role-selection',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="role-container">
      <div class="role-header">
        <h1>{{ t('selectRole') }}</h1>
        <p>Choose how you want to use CropAI</p>
      </div>

      <div class="roles-grid">
        <div class="role-card" (click)="selectRole('farmer')" [class.active]="selectedRole === 'farmer'">
          <div class="role-icon">👨‍🌾</div>
          <h3>{{ t('farmer') }}</h3>
          <p>Grow crops, get AI insights, sell direct</p>
        </div>

        <div class="role-card" (click)="selectRole('partner')" [class.active]="selectedRole === 'partner'">
          <div class="role-icon">🤝</div>
          <h3>{{ t('servicePartner') }}</h3>
          <p>Find customers, provide services</p>
        </div>

        <div class="role-card" (click)="selectRole('customer')" [class.active]="selectedRole === 'customer'">
          <div class="role-icon">🛒</div>
          <h3>{{ t('customer') }}</h3>
          <p>Buy fresh produce, verify origin</p>
        </div>

        <div class="role-card" (click)="selectRole('callcenter')" [class.active]="selectedRole === 'callcenter'">
          <div class="role-icon">📞</div>
          <h3>Call Center</h3>
          <p>Support farmers and customers</p>
        </div>

        <div class="role-card" (click)="selectRole('techsupport')" [class.active]="selectedRole === 'techsupport'">
          <div class="role-icon">🔧</div>
          <h3>Tech Support</h3>
          <p>Monitor system health</p>
        </div>

        <div class="role-card" (click)="selectRole('admin')" [class.active]="selectedRole === 'admin'">
          <div class="role-icon">👨‍💼</div>
          <h3>Administrator</h3>
          <p>Manage the platform</p>
        </div>
      </div>

      <button class="btn-continue" (click)="continueWithRole()" [disabled]="!selectedRole">
        Continue → 
      </button>
    </div>
  `,
  styles: [`
    .role-container {
      min-height: 100vh;
      background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%);
      padding: 40px 20px;
    }

    .role-header {
      text-align: center;
      color: white;
      margin-bottom: 40px;
    }

    .role-header h1 {
      margin: 0 0 10px 0;
      font-size: 32px;
    }

    .role-header p {
      margin: 0;
      font-size: 16px;
      opacity: 0.9;
    }

    .roles-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 20px;
      max-width: 1200px;
      margin: 0 auto 40px;
    }

    .role-card {
      background: white;
      border-radius: 12px;
      padding: 30px;
      text-align: center;
      cursor: pointer;
      transition: all 0.3s ease;
      border: 2px solid transparent;
    }

    .role-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 12px 24px rgba(0,0,0,0.15);
    }

    .role-card.active {
      border-color: #2e7d32;
      background: #f0fdf4;
      box-shadow: 0 0 0 3px rgba(46, 125, 50, 0.1);
    }

    .role-icon {
      font-size: 48px;
      margin-bottom: 15px;
    }

    .role-card h3 {
      margin: 15px 0 10px 0;
      color: #333;
      font-size: 18px;
    }

    .role-card p {
      margin: 0;
      color: #666;
      font-size: 14px;
      line-height: 1.5;
    }

    .btn-continue {
      display: block;
      margin: 0 auto;
      padding: 14px 40px;
      background: white;
      color: #2e7d32;
      border: none;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
    }

    .btn-continue:hover:not(:disabled) {
      background: #f0f0f0;
      transform: scale(1.05);
    }

    .btn-continue:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `]
})
export class RoleSelectionComponent implements OnInit {
  selectedRole: RoleType | null = null;

  constructor(
    private auth: AuthService,
    private translation: TranslationService,
    private router: Router
  ) {}

  ngOnInit() {}

  t(key: string): string {
    return this.translation.translate(key);
  }

  selectRole(role: RoleType) {
    this.selectedRole = role;
  }

  continueWithRole() {
    if (this.selectedRole) {
      this.auth.setUserRole(this.selectedRole);
      this.router.navigate(['/dashboard']);
    }
  }
}
