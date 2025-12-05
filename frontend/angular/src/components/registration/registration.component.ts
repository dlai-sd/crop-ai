import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule, ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthApiService, RegistrationRequest, RegistrationResponse } from '../../services/auth-api.service';
import { TranslationService } from '../../services/translation.service';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

@Component({
  selector: 'app-registration',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  template: `
    <div class="registration-container" [style.direction]="direction">
      <div class="registration-card">
        <!-- Header -->
        <div class="registration-header">
          <h1>{{ t('register') }}</h1>
          <p class="subtitle">{{ t('createNewAccount') }}</p>
        </div>

        <!-- Alert Messages -->
        <div *ngIf="successMessage" class="alert alert-success">
          <span class="alert-icon">✓</span>
          <span>{{ successMessage }}</span>
        </div>

        <div *ngIf="errorMessage" class="alert alert-error">
          <span class="alert-icon">✕</span>
          <span>{{ errorMessage }}</span>
        </div>

        <!-- Registration Form -->
        <form [formGroup]="registrationForm" (ngSubmit)="onSubmit()">
          <!-- Personal Information Section -->
          <div class="form-section">
            <h3 class="section-title">{{ t('personalInformation') }}</h3>

            <!-- First Name -->
            <div class="form-group">
              <label for="firstName">{{ t('firstName') }} <span class="required">*</span></label>
              <input
                id="firstName"
                type="text"
                class="form-control"
                formControlName="firstName"
                placeholder="John"
                [class.is-invalid]="isFieldInvalid('firstName')">
              <small class="form-text error" *ngIf="isFieldInvalid('firstName')">
                {{ t('fieldRequired') }}
              </small>
            </div>

            <!-- Last Name -->
            <div class="form-group">
              <label for="lastName">{{ t('lastName') }} <span class="required">*</span></label>
              <input
                id="lastName"
                type="text"
                class="form-control"
                formControlName="lastName"
                placeholder="Doe"
                [class.is-invalid]="isFieldInvalid('lastName')">
              <small class="form-text error" *ngIf="isFieldInvalid('lastName')">
                {{ t('fieldRequired') }}
              </small>
            </div>

            <!-- Date of Birth -->
            <div class="form-group">
              <label for="dob">{{ t('dateOfBirth') }} <span class="required">*</span></label>
              <input
                id="dob"
                type="date"
                class="form-control"
                formControlName="dateOfBirth"
                [class.is-invalid]="isFieldInvalid('dateOfBirth')">
              <small class="form-text error" *ngIf="isFieldInvalid('dateOfBirth')">
                {{ t('dateOfBirthRequired') }}
              </small>
            </div>

            <!-- Gender -->
            <div class="form-group">
              <label for="gender">{{ t('gender') }} <span class="required">*</span></label>
              <select
                id="gender"
                class="form-control"
                formControlName="gender"
                [class.is-invalid]="isFieldInvalid('gender')">
                <option value="">{{ t('selectGender') }}</option>
                <option value="M">{{ t('male') }}</option>
                <option value="F">{{ t('female') }}</option>
                <option value="O">{{ t('other') }}</option>
              </select>
              <small class="form-text error" *ngIf="isFieldInvalid('gender')">
                {{ t('genderRequired') }}
              </small>
            </div>
          </div>

          <!-- Contact Information Section -->
          <div class="form-section">
            <h3 class="section-title">{{ t('contactInformation') }}</h3>

            <!-- Email -->
            <div class="form-group">
              <label for="email">{{ t('email') }} <span class="required">*</span></label>
              <input
                id="email"
                type="email"
                class="form-control"
                formControlName="email"
                placeholder="john@example.com"
                [class.is-invalid]="isFieldInvalid('email')">
              <small class="form-text error" *ngIf="isFieldInvalid('email') && registrationForm.get('email')?.errors?.['required']">
                {{ t('emailRequired') }}
              </small>
              <small class="form-text error" *ngIf="isFieldInvalid('email') && registrationForm.get('email')?.errors?.['email']">
                {{ t('invalidEmail') }}
              </small>
            </div>

            <!-- Phone Number -->
            <div class="form-group">
              <label for="phone">{{ t('phoneNumber') }} <span class="required">*</span></label>
              <input
                id="phone"
                type="tel"
                class="form-control"
                formControlName="phoneNumber"
                placeholder="+91 1234567890"
                [class.is-invalid]="isFieldInvalid('phoneNumber')">
              <small class="form-text help">{{ t('phoneNumberHint') }}</small>
              <small class="form-text error" *ngIf="isFieldInvalid('phoneNumber')">
                {{ t('invalidPhoneNumber') }}
              </small>
            </div>
          </div>

          <!-- Password Section -->
          <div class="form-section">
            <h3 class="section-title">{{ t('security') }}</h3>

            <!-- Password -->
            <div class="form-group">
              <label for="password">{{ t('password') }} <span class="required">*</span></label>
              <input
                id="password"
                type="password"
                class="form-control"
                formControlName="password"
                [class.is-invalid]="isFieldInvalid('password')"
                (input)="updatePasswordStrength()">
              <small class="form-text help">
                {{ t('passwordRequirements') }}: 8+ {{ t('characters') }}, {{ t('uppercase') }}, {{ t('lowercase') }}, {{ t('numbers') }}, {{ t('symbols') }}
              </small>

              <!-- Password Strength Indicator -->
              <div class="password-strength" *ngIf="passwordStrength > 0">
                <div class="strength-bar">
                  <div class="strength-fill" [ngClass]="'strength-' + passwordStrength" [style.width]="(passwordStrength * 25) + '%'"></div>
                </div>
                <span class="strength-text" [ngClass]="'strength-' + passwordStrength">
                  {{ getPasswordStrengthText() }}
                </span>
              </div>

              <small class="form-text error" *ngIf="isFieldInvalid('password')">
                {{ t('passwordTooWeak') }}
              </small>
            </div>

            <!-- Confirm Password -->
            <div class="form-group">
              <label for="confirmPassword">{{ t('confirmPassword') }} <span class="required">*</span></label>
              <input
                id="confirmPassword"
                type="password"
                class="form-control"
                formControlName="confirmPassword"
                [class.is-invalid]="isFieldInvalid('confirmPassword') || (registrationForm.get('confirmPassword')?.touched && registrationForm.errors?.['passwordMismatch'])">
              <small class="form-text error" *ngIf="registrationForm.errors?.['passwordMismatch'] && registrationForm.get('confirmPassword')?.touched">
                {{ t('passwordMismatch') }}
              </small>
            </div>
          </div>

          <!-- Terms & Conditions -->
          <div class="form-group checkbox-group">
            <label>
              <input
                type="checkbox"
                formControlName="agreeToTerms"
                [class.is-invalid]="isFieldInvalid('agreeToTerms')">
              <span>{{ t('agreeToTerms') }}
                <a href="#" target="_blank">{{ t('termsAndConditions') }}</a>
              </span>
            </label>
            <small class="form-text error" *ngIf="isFieldInvalid('agreeToTerms')">
              {{ t('agreeToTermsRequired') }}
            </small>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            class="btn btn-primary btn-large"
            [disabled]="isSubmitting || !registrationForm.valid">
            <span *ngIf="!isSubmitting">{{ t('createAccount') }}</span>
            <span *ngIf="isSubmitting" class="spinner">⏳ {{ t('registering') }}</span>
          </button>
        </form>

        <!-- Login Link -->
        <div class="form-footer">
          <p>{{ t('alreadyHaveAccount') }} 
            <a [routerLink]="['/login']">{{ t('login') }}</a>
          </p>
        </div>
      </div>
    </div>
  `,
  styles: [`
    .registration-container {
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background: linear-gradient(135deg, #2e7d32 0%, #1b5e20 100%);
      padding: 20px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
    }

    .registration-card {
      background: white;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
      padding: 40px;
      max-width: 500px;
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

    .registration-header {
      text-align: center;
      margin-bottom: 30px;
    }

    .registration-header h1 {
      color: #2e7d32;
      font-size: 28px;
      font-weight: bold;
      margin: 0 0 10px 0;
    }

    .registration-header .subtitle {
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

    /* Form Sections */
    .form-section {
      margin-bottom: 25px;
      padding-bottom: 20px;
      border-bottom: 1px solid #eee;
    }

    .form-section:last-of-type {
      border-bottom: none;
    }

    .section-title {
      font-size: 16px;
      font-weight: 600;
      color: #333;
      margin: 0 0 15px 0;
      padding-bottom: 10px;
      border-bottom: 2px solid #2e7d32;
    }

    /* Form Groups */
    .form-group {
      margin-bottom: 15px;
    }

    .form-group label {
      display: block;
      font-weight: 500;
      color: #333;
      margin-bottom: 6px;
      font-size: 14px;
    }

    .required {
      color: #d32f2f;
      font-weight: bold;
    }

    .form-control {
      width: 100%;
      padding: 10px 12px;
      border: 1px solid #ddd;
      border-radius: 6px;
      font-size: 14px;
      font-family: inherit;
      transition: border-color 0.3s, box-shadow 0.3s;
      box-sizing: border-box;
    }

    .form-control:focus {
      outline: none;
      border-color: #2e7d32;
      box-shadow: 0 0 0 3px rgba(46, 125, 50, 0.1);
    }

    .form-control.is-invalid {
      border-color: #d32f2f;
      background-color: #ffebee;
    }

    .form-control.is-invalid:focus {
      box-shadow: 0 0 0 3px rgba(211, 47, 47, 0.1);
    }

    .form-text {
      display: block;
      font-size: 12px;
      margin-top: 4px;
    }

    .form-text.help {
      color: #666;
    }

    .form-text.error {
      color: #d32f2f;
      margin-top: 6px;
    }

    /* Password Strength */
    .password-strength {
      margin-top: 10px;
    }

    .strength-bar {
      width: 100%;
      height: 4px;
      background: #e0e0e0;
      border-radius: 2px;
      overflow: hidden;
      margin-bottom: 6px;
    }

    .strength-fill {
      height: 100%;
      transition: width 0.3s, background-color 0.3s;
    }

    .strength-fill.strength-1 { background-color: #d32f2f; }
    .strength-fill.strength-2 { background-color: #f57c00; }
    .strength-fill.strength-3 { background-color: #fbc02d; }
    .strength-fill.strength-4 { background-color: #2e7d32; }

    .strength-text {
      font-size: 12px;
      font-weight: 500;
    }

    .strength-text.strength-1 { color: #d32f2f; }
    .strength-text.strength-2 { color: #f57c00; }
    .strength-text.strength-3 { color: #fbc02d; }
    .strength-text.strength-4 { color: #2e7d32; }

    /* Checkbox Group */
    .checkbox-group label {
      display: flex;
      align-items: center;
      gap: 10px;
      margin: 0;
      font-weight: normal;
      cursor: pointer;
    }

    .checkbox-group input[type="checkbox"] {
      width: 18px;
      height: 18px;
      cursor: pointer;
    }

    .checkbox-group a {
      color: #2e7d32;
      text-decoration: none;
    }

    .checkbox-group a:hover {
      text-decoration: underline;
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
      margin-top: 20px;
    }

    .spinner {
      display: inline-block;
      opacity: 0.7;
    }

    /* Form Footer */
    .form-footer {
      text-align: center;
      margin-top: 20px;
      padding-top: 20px;
      border-top: 1px solid #eee;
    }

    .form-footer p {
      color: #666;
      font-size: 14px;
      margin: 0;
    }

    .form-footer a {
      color: #2e7d32;
      text-decoration: none;
      font-weight: 600;
    }

    .form-footer a:hover {
      text-decoration: underline;
    }

    /* Responsive */
    @media (max-width: 600px) {
      .registration-card {
        padding: 25px;
      }

      .registration-header h1 {
        font-size: 24px;
      }
    }
  `]
})
export class RegistrationComponent implements OnInit, OnDestroy {
  registrationForm!: FormGroup;
  isSubmitting = false;
  successMessage = '';
  errorMessage = '';
  passwordStrength = 0;
  direction = 'ltr';

  private destroy$ = new Subject<void>();

  constructor(
    private formBuilder: FormBuilder,
    private authApi: AuthApiService,
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
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Create registration form
   */
  private createForm(): void {
    this.registrationForm = this.formBuilder.group({
      firstName: ['', [Validators.required]],
      lastName: ['', [Validators.required]],
      email: ['', [Validators.required, Validators.email]],
      phoneNumber: ['', [Validators.required, Validators.pattern(/^\+?[1-9]\d{1,14}$/)]],
      dateOfBirth: ['', [Validators.required]],
      gender: ['', [Validators.required]],
      password: ['', [Validators.required, this.passwordStrengthValidator.bind(this)]],
      confirmPassword: ['', [Validators.required]],
      agreeToTerms: [false, [Validators.requiredTrue]]
    }, {
      validators: this.passwordMatchValidator.bind(this)
    });
  }

  /**
   * Password strength validator
   */
  private passwordStrengthValidator(control: any): { [key: string]: boolean } | null {
    const value = control.value;
    if (!value) return null;

    const hasUpperCase = /[A-Z]/.test(value);
    const hasLowerCase = /[a-z]/.test(value);
    const hasNumeric = /[0-9]/.test(value);
    const hasSpecialChar = /[!@#$%^&*_\-+]/.test(value);
    const isLengthValid = value.length >= 8;

    const isValid = hasUpperCase && hasLowerCase && hasNumeric && hasSpecialChar && isLengthValid;

    if (!isValid) {
      return { 'weakPassword': true };
    }

    return null;
  }

  /**
   * Password match validator
   */
  private passwordMatchValidator(group: FormGroup): { [key: string]: boolean } | null {
    const password = group.get('password')?.value;
    const confirmPassword = group.get('confirmPassword')?.value;

    if (password && confirmPassword && password !== confirmPassword) {
      return { 'passwordMismatch': true };
    }

    return null;
  }

  /**
   * Update password strength
   */
  updatePasswordStrength(): void {
    const password = this.registrationForm.get('password')?.value || '';
    let strength = 0;

    if (password.length >= 8) strength++;
    if (/[A-Z]/.test(password)) strength++;
    if (/[a-z]/.test(password)) strength++;
    if (/[0-9]/.test(password)) strength++;
    if (/[!@#$%^&*_\-+]/.test(password)) strength++;

    this.passwordStrength = Math.min(Math.ceil((strength / 5) * 4), 4);
  }

  /**
   * Get password strength text
   */
  getPasswordStrengthText(): string {
    const texts = {
      1: this.t('weak'),
      2: this.t('fair'),
      3: this.t('good'),
      4: this.t('strong')
    };
    return texts[this.passwordStrength as keyof typeof texts] || '';
  }

  /**
   * Check if field is invalid and touched
   */
  isFieldInvalid(fieldName: string): boolean {
    const field = this.registrationForm.get(fieldName);
    return !!(field && field.invalid && (field.dirty || field.touched));
  }

  /**
   * Handle form submission
   */
  onSubmit(): void {
    if (this.registrationForm.invalid || this.isSubmitting) {
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';
    this.successMessage = '';

    const formValue = this.registrationForm.value;
    const request: RegistrationRequest = {
      email: formValue.email,
      phone_number: formValue.phoneNumber,
      password: formValue.password,
      first_name: formValue.firstName,
      last_name: formValue.lastName,
      date_of_birth: formValue.dateOfBirth,
      gender: formValue.gender
    };

    this.authApi.register(request).pipe(
      takeUntil(this.destroy$)
    ).subscribe({
      next: (response: RegistrationResponse) => {
        this.successMessage = this.t('registrationSuccess');
        console.log('Registration successful:', response);
        
        // Redirect to login after 2 seconds
        setTimeout(() => {
          this.router.navigate(['/login']);
        }, 2000);
      },
      error: (error: any) => {
        this.isSubmitting = false;
        this.errorMessage = error?.message || this.t('registrationFailed');
        console.error('Registration error:', error);
      }
    });
  }

  /**
   * Translation helper
   */
  t(key: string): string {
    return this.translation.translate(key);
  }
}
