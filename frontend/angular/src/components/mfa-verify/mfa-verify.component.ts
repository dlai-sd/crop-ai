import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthApiService, MFAVerificationRequest } from '../../services/auth-api.service';
import { AuthService } from '../../services/auth.service';
import { TranslationService } from '../../services/translation.service';
import { Subject, interval } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'app-mfa-verify',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  template: `
    <div class="mfa-container" [style.direction]="direction">
      <div class="mfa-card">
        <!-- Header -->
        <div class="mfa-header">
          <h1>{{ t('verifyIdentity') }}</h1>
          <p class="subtitle">{{ t('mfaInstructions', { method: mfaMethod }) }}</p>
        </div>

        <!-- Alert Messages -->
        <div *ngIf="successMessage" class="alert alert-success">
          <span class="alert-icon">✓</span>
          <span>{{ successMessage }}</span>
        </div>

        <div *ngIf="errorMessage" class="alert alert-error">
          <span class="alert-icon">✕</span>
          <span>{{ errorMessage }}</span>
          <span class="attempts-remaining" *ngIf="attemptsRemaining > 0">
            ({{ attemptsRemaining }} {{ t('attemptsRemaining') }})
          </span>
        </div>

        <!-- MFA Verification Form -->
        <form [formGroup]="mfaForm" (ngSubmit)="onSubmit()">
          <!-- Code Input -->
          <div class="form-group">
            <label for="code">{{ t('enterCode') }} <span class="required">*</span></label>
            <div class="code-input-group">
              <input
                id="code"
                type="text"
                class="code-input"
                formControlName="code"
                placeholder="000000"
                maxlength="6"
                inputmode="numeric"
                [class.is-invalid]="isFieldInvalid('code')"
                (input)="onCodeInput($event)">
              <span class="code-counter">{{ remainingTime }}s</span>
            </div>
            <small class="form-text error" *ngIf="isFieldInvalid('code')">
              {{ t('codeRequired') }}
            </small>
          </div>

          <!-- Verify Button -->
          <button
            type="submit"
            class="btn btn-primary btn-large"
            [disabled]="isSubmitting || !mfaForm.valid">
            <span *ngIf="!isSubmitting">{{ t('verify') }}</span>
            <span *ngIf="isSubmitting" class="spinner">⏳ {{ t('verifying') }}</span>
          </button>
        </form>

        <!-- Backup Code Option -->
        <div class="backup-code-section">
          <button
            type="button"
            class="link-button"
            (click)="toggleBackupCodeInput()"
            [disabled]="isSubmitting">
            {{ showBackupCodeInput ? t('useCode') : t('useBackupCode') }}
          </button>

          <div *ngIf="showBackupCodeInput" class="backup-code-input">
            <div class="form-group">
              <label for="backupCode">{{ t('enterBackupCode') }}</label>
              <input
                id="backupCode"
                type="text"
                class="form-control"
                [(ngModel)]="backupCode"
                placeholder="XXXX-XXXX-XXXX"
                [disabled]="isSubmitting">
            </div>
            <button
              type="button"
              class="btn btn-secondary"
              (click)="verifyBackupCode()"
              [disabled]="isSubmitting || !backupCode">
              {{ t('verify') }}
            </button>
          </div>
        </div>

        <!-- Footer -->
        <div class="mfa-footer">
          <button
            type="button"
            class="link-button"
            (click)="goBack()"
            [disabled]="isSubmitting">
            ← {{ t('backToLogin') }}
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .mfa-container {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%);
      padding: 20px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    }

    .mfa-card {
      background: white;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
      padding: 40px;
      max-width: 420px;
      width: 100%;
      animation: slideIn 0.3s ease-out;
    }

    @keyframes slideIn {
      from {
        opacity: 0;
        transform: translateY(20px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    .mfa-header {
      text-align: center;
      margin-bottom: 30px;
    }

    .mfa-header h1 {
      color: #2e7d32;
      font-size: 24px;
      font-weight: bold;
      margin: 0 0 10px 0;
    }

    .mfa-header .subtitle {
      color: #666;
      font-size: 14px;
      margin: 0;
    }

    /* Alert Messages */
    .alert {
      padding: 12px 15px;
      border-radius: 6px;
      margin-bottom: 20px;
      display: flex;
      align-items: center;
      gap: 10px;
      font-size: 14px;
      animation: slideIn 0.3s ease-out;
    }

    .alert-success {
      background-color: #f0f9ff;
      border: 1px solid #81c784;
      color: #2e7d32;
    }

    .alert-error {
      background-color: #ffebee;
      border: 1px solid #ef5350;
      color: #c62828;
    }

    .alert-icon {
      font-weight: bold;
      font-size: 16px;
    }

    .attempts-remaining {
      font-size: 12px;
      margin-left: 10px;
    }

    /* Form Group */
    .form-group {
      margin-bottom: 20px;
    }

    .form-group label {
      display: block;
      font-weight: 500;
      color: #333;
      margin-bottom: 8px;
      font-size: 14px;
    }

    .required {
      color: #d32f2f;
      font-weight: bold;
    }

    /* Code Input */
    .code-input-group {
      display: flex;
      gap: 10px;
      align-items: center;
    }

    .code-input {
      flex: 1;
      padding: 12px;
      border: 2px solid #ddd;
      border-radius: 8px;
      font-size: 24px;
      font-weight: bold;
      text-align: center;
      letter-spacing: 8px;
      font-family: 'Monaco', 'Courier New', monospace;
      transition: border-color 0.3s, box-shadow 0.3s;
      box-sizing: border-box;
    }

    .code-input:focus {
      outline: none;
      border-color: #2e7d32;
      box-shadow: 0 0 0 3px rgba(46, 125, 50, 0.1);
    }

    .code-input.is-invalid {
      border-color: #d32f2f;
      background-color: #ffebee;
    }

    .code-counter {
      min-width: 50px;
      text-align: center;
      font-weight: bold;
      color: #666;
      font-size: 14px;
    }

    .form-control {
      width: 100%;
      padding: 10px 12px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 14px;
      font-family: inherit;
      transition: border-color 0.3s;
      box-sizing: border-box;
    }

    .form-control:focus:not(:disabled) {
      outline: none;
      border-color: #2e7d32;
      box-shadow: 0 0 0 3px rgba(46, 125, 50, 0.1);
    }

    .form-text {
      display: block;
      font-size: 12px;
      margin-top: 6px;
      color: #d32f2f;
    }

    /* Buttons */
    .btn {
      padding: 10px 20px;
      border: none;
      border-radius: 6px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s;
      font-family: inherit;
    }

    .btn-primary {
      background-color: #2e7d32;
      color: white;
      width: 100%;
      padding: 12px 20px;
      font-size: 16px;
    }

    .btn-primary:hover:not(:disabled) {
      background-color: #1b5e20;
      box-shadow: 0 4px 12px rgba(46, 125, 50, 0.3);
    }

    .btn-primary:disabled {
      background-color: #ccc;
      cursor: not-allowed;
      opacity: 0.6;
    }

    .btn-large {
      width: 100%;
      padding: 12px 20px;
      font-size: 16px;
    }

    .btn-secondary {
      background-color: #f5f5f5;
      color: #333;
      border: 1px solid #ddd;
      width: 100%;
      padding: 10px 20px;
    }

    .btn-secondary:hover:not(:disabled) {
      background-color: #f0f0f0;
    }

    .spinner {
      opacity: 0.7;
    }

    .link-button {
      background: none;
      border: none;
      color: #2e7d32;
      cursor: pointer;
      font-size: 14px;
      font-weight: 500;
      padding: 0;
      text-decoration: underline;
      transition: opacity 0.3s;
    }

    .link-button:hover:not(:disabled) {
      opacity: 0.8;
    }

    .link-button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    /* Backup Code Section */
    .backup-code-section {
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid #eee;
      text-align: center;
    }

    .backup-code-input {
      margin-top: 15px;
      padding: 15px;
      background: #f9f9f9;
      border-radius: 6px;
      animation: slideIn 0.3s ease-out;
    }

    /* Footer */
    .mfa-footer {
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid #eee;
      text-align: center;
    }

    /* Responsive */
    @media (max-width: 600px) {
      .mfa-card {
        padding: 25px;
      }

      .mfa-header h1 {
        font-size: 22px;
      }

      .code-input-group {
        flex-direction: column;
      }

      .code-counter {
        width: 100%;
      }
    }
  `]
})
export class MFAVerifyComponent implements OnInit, OnDestroy {
  mfaForm!: FormGroup;
  isSubmitting = false;
  successMessage = '';
  errorMessage = '';
  direction = 'ltr';
  mfaMethod = 'TOTP';
  challengeId = '';
  
  showBackupCodeInput = false;
  backupCode = '';
  remainingTime = 300;
  attemptsRemaining = 5;

  private destroy$ = new Subject<void>();
  private timerInterval: any;

  constructor(
    private formBuilder: FormBuilder,
    private authApi: AuthApiService,
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router,
    private translation: TranslationService
  ) {
    this.createForm();
  }

  ngOnInit(): void {
    this.translation.currentLanguage$.pipe(
      takeUntil(this.destroy$)
    ).subscribe(() => {
      this.direction = this.translation.isRTL() ? 'rtl' : 'ltr';
    });

    // Get challenge ID and method from query params
    this.route.queryParams.pipe(
      takeUntil(this.destroy$)
    ).subscribe(params => {
      this.challengeId = params['challenge_id'] || '';
      this.mfaMethod = params['method'] || 'TOTP';
    });

    // Start timer
    this.startTimer();
  }

  ngOnDestroy(): void {
    if (this.timerInterval) {
      clearInterval(this.timerInterval);
    }
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Create MFA form
   */
  private createForm(): void {
    this.mfaForm = this.formBuilder.group({
      code: ['', [Validators.required, Validators.minLength(6), Validators.maxLength(6), Validators.pattern(/^\d+$/)]]
    });
  }

  /**
   * Check if field is invalid and touched
   */
  isFieldInvalid(fieldName: string): boolean {
    const field = this.mfaForm.get(fieldName);
    return !!(field && field.invalid && (field.dirty || field.touched));
  }

  /**
   * Handle code input
   */
  onCodeInput(event: any): void {
    const value = event.target.value.replace(/\D/g, '').substring(0, 6);
    this.mfaForm.patchValue({ code: value });
  }

  /**
   * Start countdown timer
   */
  private startTimer(): void {
    this.timerInterval = setInterval(() => {
      if (this.remainingTime > 0) {
        this.remainingTime--;
      } else {
        clearInterval(this.timerInterval);
        this.errorMessage = this.t('codeExpired');
      }
    }, 1000);
  }

  /**
   * Handle form submission
   */
  onSubmit(): void {
    if (this.mfaForm.invalid || this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';
    this.successMessage = '';

    const request: MFAVerificationRequest = {
      challenge_id: this.challengeId,
      code: this.mfaForm.get('code')?.value
    };

    this.authApi.verifyMFA(request).pipe(
      takeUntil(this.destroy$)
    ).subscribe({
      next: (response: any) => {
        this.successMessage = this.t('mfaVerificationSuccess');
        
        // Store user info
        this.authService.login({
          id: response.user_id,
          name: response.name,
          email: response.email,
          role: (response.role || 'farmer') as any
        });

        // Redirect to dashboard
        setTimeout(() => {
          this.router.navigate(['/dashboard']);
        }, 1000);
      },
      error: (error: any) => {
        this.isSubmitting = false;
        if (error?.status === 429) {
          this.errorMessage = this.t('tooManyAttempts');
        } else if (error?.status === 400) {
          this.errorMessage = this.t('invalidCode');
          this.attemptsRemaining = error?.details?.remaining_attempts || 0;
        } else {
          this.errorMessage = error?.message || this.t('verificationFailed');
        }
        console.error('MFA verification error:', error);
      }
    });
  }

  /**
   * Verify backup code
   */
  verifyBackupCode(): void {
    // TODO: Implement backup code verification
    console.log('Verify backup code:', this.backupCode);
  }

  /**
   * Toggle backup code input
   */
  toggleBackupCodeInput(): void {
    this.showBackupCodeInput = !this.showBackupCodeInput;
    this.backupCode = '';
  }

  /**
   * Go back to login
   */
  goBack(): void {
    this.router.navigate(['/login']);
  }

  /**
   * Translation helper
   */
  t(key: string, params?: Record<string, any>): string {
    return this.translation.translate(key, params);
  }
}
