"""
Login module - Credential-based authentication with MFA support.

Provides:
- Email/username + password login
- Multi-factor authentication (TOTP, SMS, Email OTP)
- Trusted device management
- Login history and audit trail
- Password management (change, reset)
- Rate limiting and brute force protection
- Session management

Features:
- Secure password hashing (Argon2)
- TOTP support (Google Authenticator compatible)
- SMS/Email OTP verification
- Device fingerprinting and trust
- Comprehensive audit trail
- IP-based rate limiting
- Account lockout protection
- Configurable MFA settings

Quick Start:
    from crop_ai.login import LoginService, get_db
    from sqlalchemy.orm import Session
    
    db: Session = next(get_db())
    service = LoginService(db)
    
    # Login
    success, response = await service.login(
        email_or_username="user@example.com",
        password="SecurePassword123!",
        ip_address="192.168.1.1",
        user_agent="Mozilla/5.0...",
    )
    
    if response.get("requires_mfa"):
        # MFA verification needed
        challenge_id = response["challenge_id"]
    else:
        # Login successful
        access_token = response["access_token"]

Security Notes:
- Passwords are hashed with Argon2 (see auth.utils)
- TOTP secrets are encrypted (implement field-level encryption)
- All login attempts are audited in login_history table
- Accounts are locked after 5 failed attempts (30 minutes)
- Rate limiting per IP address and user
- CSRF protection via state tokens
- Session data can be stored in Redis for horizontal scaling

Database Schema:
    user_login_credentials - Login identifiers and MFA settings
    login_history - Audit trail of all login attempts
    login_devices - Trusted devices for easier login
    mfa_challenges - In-progress MFA verifications
    login_attempt_throttle - Rate limiting tracking

API Endpoints (18 total):
    POST /api/v1/login - User login
    POST /api/v1/login/mfa/verify - Verify MFA
    POST /api/v1/login/mfa/setup - Setup MFA
    POST /api/v1/login/mfa/verify-setup - Verify MFA setup
    POST /api/v1/login/mfa/disable - Disable MFA
    POST /api/v1/login/password/change - Change password
    POST /api/v1/login/password/reset-request - Request password reset
    POST /api/v1/login/password/reset-verify - Verify password reset
    POST /api/v1/login/devices/register - Register device
    GET /api/v1/login/devices - List devices
    POST /api/v1/login/devices/{device_id}/trust - Trust device
    DELETE /api/v1/login/devices/{device_id} - Remove device
    GET /api/v1/login/history - Login history
    GET /api/v1/login/credentials - Get credentials info

Environment Variables:
    APP_NAME - Application name for MFA (default: "Crop-AI")
    GOOGLE_MAPS_API_KEY - For geolocation (optional)
"""

# Re-export CRUD functions for direct use
from . import crud
from .models import (
    LoginAttemptThrottle,
    LoginDevice,
    LoginDeviceType,
    LoginHistory,
    LoginStatus,
    MFAChallenge,
    MFAMethod,
    UserLoginCredential,
)
from .routes import router as login_router
from .schemas import (
    ChangePasswordRequest,
    DeviceRegistrationRequest,
    DisableMFARequest,
    ErrorResponse,
    LoginCredentialResponse,
    LoginDeviceListResponse,
    LoginDeviceResponse,
    LoginHistoryListResponse,
    LoginHistoryResponse,
    LoginRequest,
    LoginResponse,
    MFAChallengeResponse,
    MFASetupResponse,
    MFAVerificationRequest,
    PasswordResetResponse,
    ResetPasswordRequest,
    ResetPasswordVerifyRequest,
    SetupMFARequest,
    TrustedDeviceRequest,
    VerifyMFASetupRequest,
)
from .service import LoginService, get_login_service

__all__ = [
    # Models
    "UserLoginCredential",
    "LoginHistory",
    "LoginDevice",
    "MFAChallenge",
    "LoginAttemptThrottle",
    "MFAMethod",
    "LoginDeviceType",
    "LoginStatus",
    # Schemas
    "LoginRequest",
    "LoginResponse",
    "MFAVerificationRequest",
    "MFAChallengeResponse",
    "SetupMFARequest",
    "MFASetupResponse",
    "VerifyMFASetupRequest",
    "DisableMFARequest",
    "ChangePasswordRequest",
    "ResetPasswordRequest",
    "ResetPasswordVerifyRequest",
    "DeviceRegistrationRequest",
    "TrustedDeviceRequest",
    "LoginCredentialResponse",
    "LoginHistoryResponse",
    "LoginDeviceResponse",
    "PasswordResetResponse",
    "ErrorResponse",
    "LoginHistoryListResponse",
    "LoginDeviceListResponse",
    # Service
    "LoginService",
    "get_login_service",
    # Routes
    "login_router",
    # CRUD
    "crud",
]
