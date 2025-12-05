"""
Login service Pydantic schemas for request/response validation.

Provides comprehensive validation for:
- Credential-based login
- Multi-factor authentication (TOTP, SMS, Email)
- Device management
- Login history queries
"""

from typing import Optional, List
from pydantic import BaseModel, EmailStr, Field, field_validator
from datetime import datetime
import re


# ============================================================================
# LOGIN REQUESTS
# ============================================================================

class LoginRequest(BaseModel):
    """
    Credential-based login request.
    
    Attributes:
        email_or_username: Email address or username
        password: Plain text password (validated, not stored)
        remember_me: Keep user logged in (device token)
        device_name: Optional device identifier for device tracking
    """
    email_or_username: str = Field(..., min_length=3, max_length=255)
    password: str = Field(..., min_length=8, max_length=128)
    remember_me: bool = False
    device_name: Optional[str] = Field(None, max_length=255)
    
    @field_validator("email_or_username")
    @classmethod
    def validate_email_or_username(cls, v):
        """Email or username must be valid."""
        if "@" in v:
            # Email format
            email_regex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
            if not re.match(email_regex, v):
                raise ValueError("Invalid email format")
        else:
            # Username format (alphanumeric, underscore, hyphen)
            username_regex = r"^[a-zA-Z0-9_-]{3,100}$"
            if not re.match(username_regex, v):
                raise ValueError("Username must be 3-100 chars (alphanumeric, underscore, hyphen)")
        return v.lower()


class MFAVerificationRequest(BaseModel):
    """
    Multi-factor authentication verification.
    
    Attributes:
        challenge_id: MFA challenge identifier
        code: Verification code (6 digits for TOTP/SMS, or email link token)
    """
    challenge_id: str = Field(..., min_length=20, max_length=100)
    code: str = Field(..., min_length=6, max_length=50)
    
    @field_validator("code")
    @classmethod
    def validate_code(cls, v):
        """Code should be numeric or alphanumeric token."""
        return v.strip()


class SetupMFARequest(BaseModel):
    """
    Request to setup/enable MFA for user account.
    
    Attributes:
        mfa_method: MFA method to setup (totp, sms, email)
        phone_number: For SMS method (E.164 format)
        backup_email: For Email method
    """
    mfa_method: str = Field(..., pattern="^(totp|sms|email)$")
    phone_number: Optional[str] = None
    backup_email: Optional[str] = None
    
    @field_validator("phone_number")
    @classmethod
    def validate_phone(cls, v):
        """Phone must be in E.164 format."""
        if v and not re.match(r"^\+\d{1,3}\d{4,14}$", v):
            raise ValueError("Phone must be in E.164 format (e.g., +91XXXXXXXXXX)")
        return v
    
    @field_validator("backup_email")
    @classmethod
    def validate_backup_email(cls, v):
        """Email must be valid."""
        if v:
            email_regex = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
            if not re.match(email_regex, v):
                raise ValueError("Invalid email format")
        return v


class VerifyMFASetupRequest(BaseModel):
    """
    Verify MFA setup by providing test code.
    
    Attributes:
        code: Verification code from authenticator/SMS/Email
    """
    code: str = Field(..., min_length=6, max_length=6)
    
    @field_validator("code")
    @classmethod
    def validate_code(cls, v):
        """Code must be 6 digits."""
        if not v.isdigit():
            raise ValueError("Code must be 6 digits")
        return v


class DisableMFARequest(BaseModel):
    """
    Request to disable MFA (requires password for security).
    
    Attributes:
        password: Current password (to verify account ownership)
    """
    password: str = Field(..., min_length=8, max_length=128)


class ChangePasswordRequest(BaseModel):
    """
    Change user password.
    
    Attributes:
        current_password: Current password (for verification)
        new_password: New password (must meet requirements)
        confirm_password: Password confirmation
    """
    current_password: str = Field(..., min_length=8, max_length=128)
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)
    
    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v):
        """New password must be strong."""
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least 1 uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least 1 lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least 1 digit")
        if not any(c in "!@#$%^&*_-+" for c in v):
            raise ValueError("Password must contain at least 1 special character (!@#$%^&*_-+)")
        return v
    
    def verify_match(self) -> bool:
        """Verify new_password matches confirm_password."""
        return self.new_password == self.confirm_password


class ResetPasswordRequest(BaseModel):
    """
    Request password reset via email/SMS.
    
    Attributes:
        email_or_username: Email or username to reset password for
    """
    email_or_username: str = Field(..., min_length=3, max_length=255)


class ResetPasswordVerifyRequest(BaseModel):
    """
    Verify password reset token and set new password.
    
    Attributes:
        reset_token: Token from reset email/SMS
        new_password: New password (must meet requirements)
        confirm_password: Password confirmation
    """
    reset_token: str = Field(..., min_length=50, max_length=500)
    new_password: str = Field(..., min_length=8, max_length=128)
    confirm_password: str = Field(..., min_length=8, max_length=128)


class DeviceRegistrationRequest(BaseModel):
    """
    Register/trust a device for easier future login.
    
    Attributes:
        device_id: Unique device identifier
        device_name: Human-readable device name (e.g., "My iPhone 14")
        device_type: Type of device (web, mobile_ios, mobile_android, desktop, tablet)
    """
    device_id: str = Field(..., min_length=20, max_length=100)
    device_name: str = Field(..., min_length=3, max_length=255)
    device_type: str = Field(..., pattern="^(web|mobile_ios|mobile_android|desktop|tablet|other)$")


class TrustedDeviceRequest(BaseModel):
    """
    Mark device as trusted for passwordless login.
    
    Attributes:
        device_id: Device to trust
        trust: Trust/untrust the device
    """
    device_id: str = Field(..., min_length=20, max_length=100)
    trust: bool = True


# ============================================================================
# LOGIN RESPONSES
# ============================================================================

class LoginResponse(BaseModel):
    """
    Successful login response.
    
    Attributes:
        access_token: JWT access token (15 minutes)
        refresh_token: JWT refresh token (7 days)
        token_type: Token type (always "bearer")
        expires_in: Access token expiration (seconds)
        user_id: Authenticated user ID
        email: User email
        role: User role (farmer, partner, customer)
        name: User full name
        requires_mfa: Does user require MFA verification
        device_token: Device token (if remember_me=True)
    """
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user_id: int
    email: str
    role: str
    name: str
    requires_mfa: bool = False
    device_token: Optional[str] = None


class MFAChallengeResponse(BaseModel):
    """
    MFA challenge issued (requires verification).
    
    Attributes:
        challenge_id: Challenge identifier
        mfa_method: Method used (totp, sms, email)
        delivery_method: How code was delivered (totp shows hint, sms/email shows destination)
        expires_in: Seconds until challenge expires
        remaining_attempts: Attempts remaining before lockout
    """
    challenge_id: str
    mfa_method: str
    delivery_method: str
    expires_in: int
    remaining_attempts: int


class MFASetupResponse(BaseModel):
    """
    MFA setup response (for TOTP QR code display).
    
    Attributes:
        setup_token: Token for completing setup
        mfa_method: Method being setup
        qr_code: QR code image (for TOTP)
        secret: Manual entry secret (for TOTP)
        backup_codes: Backup codes for account recovery
    """
    setup_token: str
    mfa_method: str
    qr_code: Optional[str] = None
    secret: Optional[str] = None
    backup_codes: Optional[List[str]] = None


class LoginCredentialResponse(BaseModel):
    """
    User login credential info (for account settings).
    
    Attributes:
        user_id: User ID
        username: Login username
        email: Primary email
        backup_email: Backup email
        mfa_enabled: Is MFA enabled
        mfa_method: Current MFA method
        preferred_login_method: Preferred login identifier
        last_login_at: Last successful login
        created_at: Credential creation
    """
    user_id: int
    username: str
    email: str
    backup_email: Optional[str]
    mfa_enabled: bool
    mfa_method: str
    preferred_login_method: str
    last_login_at: Optional[datetime]
    created_at: datetime


class LoginHistoryResponse(BaseModel):
    """
    Single login history entry.
    
    Attributes:
        id: History record ID
        status: Login status (success, failed, blocked, etc.)
        method: Login method used
        ip_address: Client IP address
        device_type: Device type
        device_name: Device name
        location_city: Location city
        location_country: Location country
        mfa_used: Was MFA used
        created_at: Attempt timestamp
    """
    id: int
    status: str
    method: str
    ip_address: str
    device_type: str
    device_name: Optional[str]
    location_city: Optional[str]
    location_country: Optional[str]
    mfa_used: bool
    created_at: datetime


class LoginDeviceResponse(BaseModel):
    """
    User login device info.
    
    Attributes:
        id: Device record ID
        device_id: Unique device ID
        device_name: Human-readable name
        device_type: Device type
        is_trusted: Is device trusted
        last_used_at: Last login from device
        created_at: Device registration
    """
    id: int
    device_id: str
    device_name: Optional[str]
    device_type: str
    is_trusted: bool
    last_used_at: Optional[datetime]
    created_at: datetime


class PasswordResetResponse(BaseModel):
    """
    Password reset initiation response.
    
    Attributes:
        message: Confirmation message
        reset_token_sent_to: Where reset token was sent
    """
    message: str
    reset_token_sent_to: str


class ErrorResponse(BaseModel):
    """
    Error response for login failures.
    
    Attributes:
        error: Error code/type
        message: Human-readable error message
        details: Additional details
    """
    error: str
    message: str
    details: Optional[str] = None


# ============================================================================
# BULK RESPONSE MODELS
# ============================================================================

class LoginHistoryListResponse(BaseModel):
    """
    Paginated login history list.
    
    Attributes:
        total: Total number of records
        page: Current page (1-indexed)
        limit: Results per page
        records: List of LoginHistoryResponse
    """
    total: int
    page: int
    limit: int
    records: List[LoginHistoryResponse]


class LoginDeviceListResponse(BaseModel):
    """
    List of trusted/registered devices.
    
    Attributes:
        total: Total number of devices
        devices: List of LoginDeviceResponse
    """
    total: int
    devices: List[LoginDeviceResponse]
