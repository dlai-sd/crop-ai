import { Injectable } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError, tap } from 'rxjs/operators';

/**
 * Auth API Service
 * Handles all API calls to backend authentication endpoints
 * Includes: Login, Registration, MFA, Password Management, Device Management
 */

// Request/Response Interfaces
export interface RegistrationRequest {
  email: string;
  phone_number: string;
  password: string;
  first_name: string;
  last_name: string;
  date_of_birth: string;
  gender: string;
  profile_picture_url?: string;
}

export interface RegistrationResponse {
  id: string;
  email: string;
  phone_number: string;
  first_name: string;
  last_name: string;
  date_of_birth: string;
  gender: string;
  created_at: string;
  message: string;
}

export interface LoginRequest {
  email_or_username: string;
  password: string;
  remember_me?: boolean;
  device_name?: string;
}

export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
  user_id: string;
  email: string;
  role: string;
  name: string;
  requires_mfa?: boolean;
  device_token?: string;
  challenge_id?: string;
  mfa_method?: string;
}

export interface MFAVerificationRequest {
  challenge_id: string;
  code: string;
}

export interface SetupMFARequest {
  mfa_method: 'totp' | 'sms' | 'email';
  phone_number?: string;
  backup_email?: string;
}

export interface MFASetupResponse {
  setup_token: string;
  mfa_method: string;
  qr_code?: string;
  secret?: string;
  backup_codes?: string[];
  delivery_method?: string;
}

export interface VerifyMFASetupRequest {
  code: string;
}

export interface ChangePasswordRequest {
  current_password: string;
  new_password: string;
  confirm_password: string;
}

export interface ResetPasswordRequest {
  email_or_username: string;
}

export interface ResetPasswordVerifyRequest {
  reset_token: string;
  new_password: string;
  confirm_password: string;
}

export interface DeviceRegistrationRequest {
  device_id: string;
  device_name: string;
  device_type: 'WEB' | 'MOBILE_IOS' | 'MOBILE_ANDROID' | 'DESKTOP' | 'TABLET' | 'OTHER';
}

export interface LoginDevice {
  device_id: string;
  device_name: string;
  device_type: string;
  is_trusted: boolean;
  last_used_at: string;
  created_at: string;
}

export interface LoginHistory {
  id: string;
  status: string;
  method: string;
  ip_address: string;
  user_agent: string;
  device_type: string;
  location_city: string;
  location_country: string;
  created_at: string;
  failure_reason?: string;
}

export interface ErrorResponse {
  error_code: string;
  message: string;
  details?: Record<string, any>;
}

@Injectable({
  providedIn: 'root'
})
export class AuthApiService {
  private readonly baseUrl = '/api/v1';

  constructor(private http: HttpClient) {}

  /**
   * Register a new user
   */
  register(data: RegistrationRequest): Observable<RegistrationResponse> {
    return this.http.post<RegistrationResponse>(
      `${this.baseUrl}/register`,
      data
    ).pipe(
      tap(() => console.log('Registration successful')),
      catchError(this.handleError)
    );
  }

  /**
   * Login with email/username and password
   */
  login(data: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(
      `${this.baseUrl}/login`,
      data
    ).pipe(
      tap(response => {
        if (response.access_token) {
          localStorage.setItem('access_token', response.access_token);
          localStorage.setItem('refresh_token', response.refresh_token);
          localStorage.setItem('user_id', response.user_id);
        }
      }),
      catchError(this.handleError)
    );
  }

  /**
   * Verify MFA code
   */
  verifyMFA(data: MFAVerificationRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(
      `${this.baseUrl}/login/mfa/verify`,
      data
    ).pipe(
      tap(response => {
        if (response.access_token) {
          localStorage.setItem('access_token', response.access_token);
          localStorage.setItem('refresh_token', response.refresh_token);
        }
      }),
      catchError(this.handleError)
    );
  }

  /**
   * Setup MFA (TOTP, SMS, or Email)
   */
  setupMFA(data: SetupMFARequest): Observable<MFASetupResponse> {
    return this.http.post<MFASetupResponse>(
      `${this.baseUrl}/login/mfa/setup`,
      data,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Verify MFA setup and enable MFA
   */
  verifyMFASetup(data: VerifyMFASetupRequest): Observable<any> {
    return this.http.post<any>(
      `${this.baseUrl}/login/mfa/verify-setup`,
      data,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Disable MFA
   */
  disableMFA(password: string): Observable<any> {
    return this.http.post<any>(
      `${this.baseUrl}/login/mfa/disable`,
      { password },
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Change password
   */
  changePassword(data: ChangePasswordRequest): Observable<any> {
    return this.http.post<any>(
      `${this.baseUrl}/login/password/change`,
      data,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Request password reset
   */
  requestPasswordReset(data: ResetPasswordRequest): Observable<any> {
    return this.http.post<any>(
      `${this.baseUrl}/login/password/reset-request`,
      data
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Verify password reset token and set new password
   */
  verifyPasswordReset(data: ResetPasswordVerifyRequest): Observable<any> {
    return this.http.post<any>(
      `${this.baseUrl}/login/password/reset-verify`,
      data
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Register a trusted device
   */
  registerDevice(data: DeviceRegistrationRequest): Observable<LoginDevice> {
    return this.http.post<LoginDevice>(
      `${this.baseUrl}/login/devices/register`,
      data,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Get all trusted devices
   */
  getDevices(): Observable<{ devices: LoginDevice[]; total: number }> {
    return this.http.get<{ devices: LoginDevice[]; total: number }>(
      `${this.baseUrl}/login/devices`,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Trust/untrust a device
   */
  setDeviceTrust(deviceId: string, trust: boolean): Observable<LoginDevice> {
    return this.http.post<LoginDevice>(
      `${this.baseUrl}/login/devices/${deviceId}/trust`,
      { trust },
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Remove a device
   */
  removeDevice(deviceId: string): Observable<any> {
    return this.http.delete<any>(
      `${this.baseUrl}/login/devices/${deviceId}`,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Get login history
   */
  getLoginHistory(page: number = 1, limit: number = 50): Observable<{ records: LoginHistory[]; total: number; page: number }> {
    return this.http.get<{ records: LoginHistory[]; total: number; page: number }>(
      `${this.baseUrl}/login/history?page=${page}&limit=${limit}`,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Get current user credentials
   */
  getCredentials(): Observable<any> {
    return this.http.get<any>(
      `${this.baseUrl}/login/credentials`,
      { headers: { 'Authorization': `Bearer ${this.getAccessToken()}` } }
    ).pipe(
      catchError(this.handleError)
    );
  }

  /**
   * Logout
   */
  logout(): void {
    localStorage.removeItem('access_token');
    localStorage.removeItem('refresh_token');
    localStorage.removeItem('user_id');
  }

  /**
   * Get access token from storage
   */
  getAccessToken(): string {
    return localStorage.getItem('access_token') || '';
  }

  /**
   * Check if user is authenticated
   */
  isAuthenticated(): boolean {
    return !!this.getAccessToken();
  }

  /**
   * Handle HTTP errors
   */
  private handleError(error: HttpErrorResponse) {
    let errorMessage = 'An error occurred';
    let errorCode = 'UNKNOWN_ERROR';

    if (error.error instanceof ErrorEvent) {
      // Client-side error
      errorMessage = error.error.message;
    } else {
      // Server-side error
      errorCode = error.error?.error_code || `HTTP_${error.status}`;
      errorMessage = error.error?.message || error.statusText;
    }

    console.error('Auth API Error:', {
      code: errorCode,
      message: errorMessage,
      status: error.status,
      details: error.error?.details
    });

    return throwError(() => ({
      error_code: errorCode,
      message: errorMessage,
      status: error.status,
      details: error.error?.details
    }));
  }
}
