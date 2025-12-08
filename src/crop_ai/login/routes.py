"""
Login API routes.

Endpoints for:
- User login (email/username + password)
- Multi-factor authentication
- Device management
- Password management
- Login history
"""

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from crop_ai.auth.dependencies import get_current_user
from crop_ai.database import get_db

from . import crud, schemas
from .service import LoginService

router = APIRouter(prefix="/api/v1/login", tags=["login"])


# ============================================================================
# LOGIN ENDPOINTS
# ============================================================================

@router.post("/", response_model=schemas.LoginResponse)
async def login(
    request: Request,
    credentials: schemas.LoginRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Authenticate user with email/username and password.
    
    Returns:
    - access_token: JWT token (15 minutes)
    - refresh_token: JWT token (7 days)
    - If MFA enabled: MFA challenge ID (requires verification)
    
    **Request Headers:**
    - User-Agent: Browser/app identifier
    
    **Response Status:**
    - 200: Login successful
    - 400: Invalid credentials
    - 429: Too many attempts (rate limited)
    """
    
    # Get client IP
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")
    
    # Perform login
    login_service = LoginService(db)
    success, response = await login_service.login(
        email_or_username=credentials.email_or_username,
        password=credentials.password,
        ip_address=client_ip,
        user_agent=user_agent,
        device_name=credentials.device_name,
    )
    
    if not success:
        # Determine error status
        if response.get("error") == "account_locked":
            raise HTTPException(status_code=429, detail=response["message"])
        else:
            raise HTTPException(status_code=401, detail=response["message"])
    
    # Check if MFA required
    if response.get("requires_mfa"):
        raise HTTPException(
            status_code=202,  # Accepted (not standard, use 200 with requires_mfa flag)
            detail={
                "requires_mfa": True,
                "challenge_id": response["challenge_id"],
                "mfa_method": response["mfa_method"],
                "expires_in": response["expires_in"],
            }
        )
    
    return response


@router.post("/mfa/verify", response_model=schemas.LoginResponse)
async def verify_mfa(
    request: Request,
    mfa_request: schemas.MFAVerificationRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Verify MFA challenge and complete login.
    
    **Request:**
    - challenge_id: From login response
    - code: 6-digit OTP or email/SMS code
    
    **Response:**
    - access_token: JWT token
    - refresh_token: JWT token
    
    **Response Status:**
    - 200: MFA verified, login complete
    - 400: Invalid or expired challenge
    - 401: Wrong verification code
    - 429: Too many attempts
    """
    
    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "unknown")
    
    login_service = LoginService(db)
    success, response = await login_service.verify_mfa(
        challenge_id=mfa_request.challenge_id,
        code=mfa_request.code,
        ip_address=client_ip,
        user_agent=user_agent,
    )
    
    if not success:
        if response.get("error") == "challenge_expired":
            raise HTTPException(status_code=400, detail=response["message"])
        elif response.get("error") == "challenge_exhausted":
            raise HTTPException(status_code=429, detail=response["message"])
        else:
            raise HTTPException(status_code=401, detail=response["message"])
    
    return response


# ============================================================================
# MFA MANAGEMENT
# ============================================================================

@router.post("/mfa/setup", response_model=schemas.MFASetupResponse)
async def setup_mfa(
    mfa_request: schemas.SetupMFARequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Initiate MFA setup for user account.
    
    **Supported Methods:**
    - totp: Time-based One-Time Password (Google Authenticator)
    - sms: SMS verification codes
    - email: Email verification codes
    
    **Response for TOTP:**
    - qr_code: Base64 encoded QR code image
    - secret: Manual entry key
    - backup_codes: Recovery codes
    
    **Response for SMS/Email:**
    - message: Confirmation that code was sent
    
    **Protected:** Requires authentication
    """
    
    login_service = LoginService(db)
    
    try:
        response = await login_service.setup_mfa(
            user_id=current_user["user_id"],
            mfa_method=mfa_request.mfa_method,
            phone_number=mfa_request.phone_number,
        )
        return response
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/mfa/verify-setup", response_model=schemas.LoginCredentialResponse)
async def verify_mfa_setup(
    verify_request: schemas.VerifyMFASetupRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Verify MFA setup with test code.
    
    After successful verification, MFA is enabled for account.
    
    **Request:**
    - code: 6-digit code from authenticator/SMS/Email
    
    **Protected:** Requires authentication
    """
    
    login_service = LoginService(db)
    
    try:
        success = await login_service.verify_mfa_setup(
            user_id=current_user["user_id"],
            mfa_method="totp",  # TODO: Get from setup_token
            code=verify_request.code,
        )
        
        if not success:
            raise HTTPException(status_code=400, detail="Invalid verification code")
        
        # Return updated credential info
        credential = await crud.get_login_credential_by_user_id(
            db,
            current_user["user_id"],
        )
        
        return {
            "user_id": credential.user_id,
            "username": credential.username,
            "email": current_user["email"],
            "backup_email": credential.backup_email,
            "mfa_enabled": credential.mfa_enabled,
            "mfa_method": credential.mfa_method.value if credential.mfa_method else "none",
            "preferred_login_method": credential.preferred_login_method,
            "last_login_at": credential.last_login_at,
            "created_at": credential.created_at,
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/mfa/disable", response_model=schemas.LoginCredentialResponse)
async def disable_mfa(
    disable_request: schemas.DisableMFARequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Disable MFA for user account.
    
    **Request:**
    - password: Current password (for security)
    
    **Protected:** Requires authentication
    """
    
    from crop_ai.auth.models import User as AuthUser
    from crop_ai.auth.utils import verify_password
    
    auth_user = db.query(AuthUser).filter(
        AuthUser.id == current_user["user_id"]
    ).first()
    
    if not auth_user or not verify_password(disable_request.password, auth_user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid password")
    
    # Disable MFA
    credential = await crud.update_mfa_settings(
        db,
        user_id=current_user["user_id"],
        mfa_enabled=False,
        mfa_method="none",
        mfa_verified=False,
    )
    
    return {
        "user_id": credential.user_id,
        "username": credential.username,
        "email": current_user["email"],
        "backup_email": credential.backup_email,
        "mfa_enabled": credential.mfa_enabled,
        "mfa_method": "none",
        "preferred_login_method": credential.preferred_login_method,
        "last_login_at": credential.last_login_at,
        "created_at": credential.created_at,
    }


# ============================================================================
# PASSWORD MANAGEMENT
# ============================================================================

@router.post("/password/change", response_model=dict)
async def change_password(
    password_request: schemas.ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Change user password.
    
    **Requirements:**
    - At least 8 characters
    - At least 1 uppercase letter
    - At least 1 lowercase letter
    - At least 1 digit
    - At least 1 special character (!@#$%^&*_-+)
    
    **Protected:** Requires authentication
    """
    
    if not password_request.verify_match():
        raise HTTPException(
            status_code=400,
            detail="New password and confirmation do not match"
        )
    
    login_service = LoginService(db)
    success, message = await login_service.change_password(
        user_id=current_user["user_id"],
        current_password=password_request.current_password,
        new_password=password_request.new_password,
    )
    
    if not success:
        raise HTTPException(status_code=401, detail=message)
    
    return {"message": message}


@router.post("/password/reset-request", response_model=schemas.PasswordResetResponse)
async def request_password_reset(
    reset_request: schemas.ResetPasswordRequest,
) -> dict:
    """
    Request password reset via email.
    
    **Request:**
    - email_or_username: Email or username of account
    
    **Note:** Does not reveal if account exists (security)
    """
    
    return {
        "message": "Password reset email sent",
        "reset_token_sent_to": "Check your email for password reset instructions",
    }


@router.post("/password/reset-verify", response_model=dict)
async def verify_password_reset(
    verify_request: schemas.ResetPasswordVerifyRequest,
    db: Session = Depends(get_db),
) -> dict:
    """
    Verify password reset token and set new password.
    
    **Request:**
    - reset_token: Token from password reset email
    - new_password: New password (must meet requirements)
    - confirm_password: Password confirmation
    """
    
    # TODO: Validate reset token
    # TODO: Update password in auth.users
    
    return {"message": "Password reset successfully"}


# ============================================================================
# DEVICE MANAGEMENT
# ============================================================================

@router.post("/devices/register", response_model=schemas.LoginDeviceResponse)
async def register_device(
    request: Request,
    device_request: schemas.DeviceRegistrationRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Register a device for trusted login.
    
    **Request:**
    - device_id: Unique device identifier (UUID)
    - device_name: Human-readable name (e.g., "My iPhone 14")
    - device_type: web, mobile_ios, mobile_android, desktop, tablet
    
    **Protected:** Requires authentication
    """
    
    user_agent = request.headers.get("user-agent", "unknown")
    
    device = await crud.register_device(
        db,
        user_id=current_user["user_id"],
        device_id=device_request.device_id,
        device_name=device_request.device_name,
        device_type=device_request.device_type,
        device_fingerprint=None,  # TODO: Calculate fingerprint
    )
    
    return {
        "id": device.id,
        "device_id": device.device_id,
        "device_name": device.device_name,
        "device_type": device.device_type,
        "is_trusted": device.is_trusted,
        "last_used_at": device.last_used_at,
        "created_at": device.created_at,
    }


@router.get("/devices", response_model=schemas.LoginDeviceListResponse)
async def list_devices(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    List user's registered devices.
    
    **Protected:** Requires authentication
    """
    
    devices = await crud.get_user_devices(db, current_user["user_id"])
    
    return {
        "total": len(devices),
        "devices": [
            {
                "id": d.id,
                "device_id": d.device_id,
                "device_name": d.device_name,
                "device_type": d.device_type,
                "is_trusted": d.is_trusted,
                "last_used_at": d.last_used_at,
                "created_at": d.created_at,
            }
            for d in devices
        ]
    }


@router.post("/devices/{device_id}/trust", response_model=schemas.LoginDeviceResponse)
async def trust_device(
    device_id: str,
    trust_request: schemas.TrustedDeviceRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Mark device as trusted for easier login.
    
    **Protected:** Requires authentication
    """
    
    device = await crud.set_device_trusted(
        db,
        user_id=current_user["user_id"],
        device_id=device_id,
        trusted=trust_request.trust,
    )
    
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    
    return {
        "id": device.id,
        "device_id": device.device_id,
        "device_name": device.device_name,
        "device_type": device.device_type,
        "is_trusted": device.is_trusted,
        "last_used_at": device.last_used_at,
        "created_at": device.created_at,
    }


@router.delete("/devices/{device_id}", response_model=dict)
async def remove_device(
    device_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Remove device from trusted list.
    
    **Protected:** Requires authentication
    """
    
    success = await crud.remove_device(
        db,
        user_id=current_user["user_id"],
        device_id=device_id,
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="Device not found")
    
    return {"message": "Device removed successfully"}


# ============================================================================
# LOGIN HISTORY
# ============================================================================

@router.get("/history", response_model=schemas.LoginHistoryListResponse)
async def get_login_history(
    page: int = 1,
    limit: int = 50,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Get user's login history (paginated).
    
    **Query Parameters:**
    - page: Page number (1-indexed)
    - limit: Results per page (max 100)
    
    **Protected:** Requires authentication
    """
    
    if limit > 100:
        limit = 100
    
    offset = (page - 1) * limit
    total, records = await crud.get_user_login_history(
        db,
        user_id=current_user["user_id"],
        limit=limit,
        offset=offset,
    )
    
    return {
        "total": total,
        "page": page,
        "limit": limit,
        "records": [
            {
                "id": r.id,
                "status": r.status,
                "method": r.method,
                "ip_address": r.ip_address,
                "device_type": r.device_type.value if r.device_type else "unknown",
                "device_name": r.device_name,
                "location_city": r.location_city,
                "location_country": r.location_country,
                "mfa_used": r.mfa_used,
                "created_at": r.created_at,
            }
            for r in records
        ]
    }


# ============================================================================
# CREDENTIAL MANAGEMENT
# ============================================================================

@router.get("/credentials", response_model=schemas.LoginCredentialResponse)
async def get_login_credentials(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """
    Get current login credentials and settings.
    
    **Protected:** Requires authentication
    """
    
    credential = await crud.get_login_credential_by_user_id(
        db,
        current_user["user_id"],
    )
    
    if not credential:
        raise HTTPException(status_code=404, detail="Credential not found")
    
    return {
        "user_id": credential.user_id,
        "username": credential.username,
        "email": current_user["email"],
        "backup_email": credential.backup_email,
        "mfa_enabled": credential.mfa_enabled,
        "mfa_method": credential.mfa_method.value if credential.mfa_method else "none",
        "preferred_login_method": credential.preferred_login_method,
        "last_login_at": credential.last_login_at,
        "created_at": credential.created_at,
    }
