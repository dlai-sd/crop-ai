import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="login-container" [style.direction]="direction">
      <div class="login-card">
        <h1 class="app-title">{{ t('appTitle') }}</h1>
        <p class="app-subtitle">🌾 Intelligent Crop Identification</p>

        <div class="aadhaar-banner">
          <div class="banner-icon">🛡️</div>
          <div>
            <h4>{{ t('aadhaarVerification') }}</h4>
            <p>We're adding AADHAAR-based verification for enhanced security ({{ t('phase2') }})</p>
          </div>
        </div>

        <div class="sso-section">
          <h2>{{ t('login') }}</h2>
          
          <button class="btn btn-google" (click)="loginGoogle()">
            <span>🔵 {{ t('loginWithGoogle') }}</span>
          </button>

          <button class="btn btn-facebook" (click)="loginFacebook()">
            <span>🔵 {{ t('loginWithFacebook') }}</span>
          </button>

          <div class="divider">or</div>

          <input type="email" placeholder="{{ t('email') }}" [(ngModel)]="email" class="form-input">
          <input type="password" placeholder="{{ t('password') }}" [(ngModel)]="password" class="form-input">
          <input type="text" placeholder="Your Name" [(ngModel)]="userName" class="form-input">

          <button class="btn btn-primary" (click)="loginEmail()">
            {{ t('login') }}
          </button>
        </div>

        <div class="language-selector">
          <select [(ngModel)]="currentLang" (change)="changeLanguage($event)">
            <option value="en">English</option>
            <option value="hi">हिंदी</option>
          </select>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .login-container {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%);
      padding: 20px;
    }

    .login-card {
      background: white;
      border-radius: 12px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.1);
      padding: 40px;
      max-width: 400px;
      width: 100%;
    }

    .app-title {
      margin: 0 0 5px 0;
      color: #2e7d32;
      font-size: 32px;
      font-weight: bold;
      text-align: center;
    }

    .app-subtitle {
      text-align: center;
      color: #666;
      margin: 0 0 30px 0;
      font-size: 14px;
    }

    .aadhaar-banner {
      background: #f0f9ff;
      border-left: 4px solid #2e7d32;
      padding: 15px;
      border-radius: 6px;
      margin-bottom: 30px;
      display: flex;
      gap: 12px;
      font-size: 14px;
    }

    .banner-icon {
      font-size: 20px;
    }

    .aadhaar-banner h4 {
      margin: 0 0 5px 0;
      color: #2e7d32;
      font-size: 14px;
    }

    .aadhaar-banner p {
      margin: 0;
      color: #666;
      font-size: 12px;
    }

    .sso-section h2 {
      margin-top: 0;
      margin-bottom: 20px;
      text-align: center;
      color: #333;
      font-size: 20px;
    }

    .btn {
      width: 100%;
      padding: 12px;
      margin-bottom: 12px;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: all 0.3s;
    }

    .btn-google, .btn-facebook {
      background: #f5f5f5;
      color: #333;
      border: 1px solid #ddd;
    }

    .btn-google:hover { background: #efefef; }
    .btn-facebook:hover { background: #efefef; }

    .btn-primary {
      background: #2e7d32;
      color: white;
    }

    .btn-primary:hover { background: #1b5e20; }

    .divider {
      text-align: center;
      margin: 20px 0;
      color: #999;
      font-size: 12px;
    }

    .form-input {
      width: 100%;
      padding: 12px;
      margin-bottom: 12px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 14px;
      box-sizing: border-box;
    }

    .form-input:focus {
      outline: none;
      border-color: #2e7d32;
      box-shadow: 0 0 0 2px rgba(46, 125, 50, 0.1);
    }

    .language-selector {
      margin-top: 20px;
      text-align: center;
    }

    .language-selector select {
      padding: 8px 12px;
      border: 1px solid #ddd;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
    }
  `]
})
export class LoginComponent implements OnInit {
  email = '';
  password = '';
  userName = '';
  currentLang = 'en';
  direction = 'ltr';

  constructor(
    private auth: AuthService,
    private translation: TranslationService,
    private router: Router
  ) {}

  ngOnInit() {
    this.currentLang = this.translation.getCurrentLanguage();
    this.direction = this.currentLang === 'hi' ? 'rtl' : 'ltr';
  }

  t(key: string): string {
    return this.translation.translate(key);
  }

  loginGoogle() {
    const name = 'Farmer User';
    this.auth.loginWithGoogle('user@gmail.com', name);
    this.router.navigate(['/role-selection']);
  }

  loginFacebook() {
    const name = 'Farmer User';
    this.auth.loginWithFacebook('user@facebook.com', name);
    this.router.navigate(['/role-selection']);
  }

  loginEmail() {
    if (this.email && this.password && this.userName) {
      const user = { id: Math.random().toString(), email: this.email, name: this.userName, role: 'farmer' as const };
      this.auth.login(user);
      this.router.navigate(['/role-selection']);
    }
  }

  changeLanguage(event: any) {
    const lang = event.target.value;
    this.translation.setLanguage(lang);
    this.direction = lang === 'hi' ? 'rtl' : 'ltr';
  }
}
