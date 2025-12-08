"""
Login service CRUD operations.

Handles database operations for:
- Login credentials (username, MFA settings)
- Login history (audit trail)
- Trusted devices
- MFA challenges
- Rate limiting/throttling
"""

from datetime import datetime, timedelta
from typing import List, Optional, Tuple

from sqlalchemy import and_, desc
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from .models import (
    LoginAttemptThrottle,
    LoginDevice,
    LoginHistory,
    LoginStatus,
    MFAChallenge,
    UserLoginCredential,
)

# ============================================================================
# USER LOGIN CREDENTIALS
# ============================================================================

async def create_login_credential(
    db: Session,
    user_id: int,
    username: str,
    email: str,
    mfa_enabled: bool = False,
    mfa_method: str = "none",
) -> UserLoginCredential:
    """
    Create login credential for new user.
    
    Args:
        db: Database session
        user_id: User ID (from auth.users)
        username: Login username (lowercase)
        email: User email (for login fallback)
        mfa_enabled: Enable MFA by default
        mfa_method: Default MFA method
    
    Returns:
        UserLoginCredential object
    
    Raises:
        IntegrityError: If username already exists
    """
    username = username.lower()
    credential = UserLoginCredential(
        user_id=user_id,
        username=username,
        mfa_enabled=mfa_enabled,
        mfa_method=mfa_method,
        preferred_login_method="email"
    )
    db.add(credential)
    try:
        db.commit()
        db.refresh(credential)
        return credential
    except IntegrityError:
        db.rollback()
        raise ValueError(f"Username '{username}' already exists")


async def get_login_credential(db: Session, credential_id: int) -> Optional[UserLoginCredential]:
    """Get login credential by ID."""
    return db.query(UserLoginCredential).filter(
        UserLoginCredential.id == credential_id
    ).first()


async def get_login_credential_by_user_id(db: Session, user_id: int) -> Optional[UserLoginCredential]:
    """Get login credential by user ID."""
    return db.query(UserLoginCredential).filter(
        UserLoginCredential.user_id == user_id
    ).first()


async def get_login_credential_by_username(db: Session, username: str) -> Optional[UserLoginCredential]:
    """Get login credential by username (case-insensitive)."""
    username = username.lower()
    return db.query(UserLoginCredential).filter(
        UserLoginCredential.username == username
    ).first()


async def get_login_credential_by_email(db: Session, email: str) -> Optional[UserLoginCredential]:
    """
    Get login credential by email address.
    
    Searches both primary email (from backup_email field) and
    can integrate with auth.users email.
    """
    return db.query(UserLoginCredential).filter(
        UserLoginCredential.backup_email == email
    ).first()


async def update_mfa_settings(
    db: Session,
    user_id: int,
    mfa_enabled: bool,
    mfa_method: str,
    mfa_verified: bool = False,
    totp_secret: Optional[bytes] = None,
    backup_codes: Optional[bytes] = None,
) -> UserLoginCredential:
    """
    Update MFA settings for user.
    
    Args:
        db: Database session
        user_id: User ID
        mfa_enabled: Enable/disable MFA
        mfa_method: MFA method (totp, sms, email, none)
        mfa_verified: Has MFA been verified/setup
        totp_secret: Encrypted TOTP secret
        backup_codes: Encrypted backup codes
    
    Returns:
        Updated UserLoginCredential
    """
    credential = await get_login_credential_by_user_id(db, user_id)
    if not credential:
        raise ValueError(f"Credential not found for user_id {user_id}")
    
    credential.mfa_enabled = mfa_enabled
    credential.mfa_method = mfa_method
    credential.mfa_verified = mfa_verified
    if totp_secret:
        credential.totp_secret = totp_secret
    if backup_codes:
        credential.backup_codes = backup_codes
    
    db.commit()
    db.refresh(credential)
    return credential


async def update_last_login(db: Session, user_id: int) -> UserLoginCredential:
    """Update last login timestamp."""
    credential = await get_login_credential_by_user_id(db, user_id)
    if credential:
        credential.last_login_at = datetime.utcnow()
        db.commit()
        db.refresh(credential)
    return credential


async def lock_account(db: Session, user_id: int, duration_minutes: int = 30) -> UserLoginCredential:
    """
    Lock account for failed login attempts (brute force protection).
    
    Args:
        db: Database session
        user_id: User ID
        duration_minutes: Lock duration in minutes
    
    Returns:
        Updated UserLoginCredential
    """
    credential = await get_login_credential_by_user_id(db, user_id)
    if credential:
        credential.locked_until = datetime.utcnow() + timedelta(minutes=duration_minutes)
        db.commit()
        db.refresh(credential)
    return credential


async def unlock_account(db: Session, user_id: int) -> UserLoginCredential:
    """Unlock account (clear lockout)."""
    credential = await get_login_credential_by_user_id(db, user_id)
    if credential:
        credential.locked_until = None
        db.commit()
        db.refresh(credential)
    return credential


async def is_account_locked(db: Session, user_id: int) -> bool:
    """Check if account is currently locked."""
    credential = await get_login_credential_by_user_id(db, user_id)
    if not credential or not credential.locked_until:
        return False
    return credential.locked_until > datetime.utcnow()


# ============================================================================
# LOGIN HISTORY
# ============================================================================

async def create_login_history(
    db: Session,
    user_id: int,
    status: str,
    method: str,
    ip_address: str,
    user_agent: str,
    device_type: str = "web",
    device_name: Optional[str] = None,
    location_city: Optional[str] = None,
    location_country: Optional[str] = None,
    mfa_used: bool = False,
    mfa_method: Optional[str] = None,
    failure_reason: Optional[str] = None,
) -> LoginHistory:
    """
    Create login history record.
    
    Args:
        db: Database session
        user_id: User ID
        status: Login status (success, failed, blocked, mfa_required, mfa_failed)
        method: Login method (email, username, google, microsoft, facebook)
        ip_address: Client IP address
        user_agent: Browser/app user agent
        device_type: Device type
        device_name: Device name
        location_city: Geolocation city
        location_country: Geolocation country
        mfa_used: Was MFA used
        mfa_method: MFA method used
        failure_reason: Reason for failure (if status is failed/blocked)
    
    Returns:
        LoginHistory record
    """
    history = LoginHistory(
        user_id=user_id,
        status=status,
        method=method,
        ip_address=ip_address,
        user_agent=user_agent,
        device_type=device_type,
        device_name=device_name,
        location_city=location_city,
        location_country=location_country,
        mfa_used=mfa_used,
        mfa_method=mfa_method,
        failure_reason=failure_reason,
    )
    db.add(history)
    db.commit()
    db.refresh(history)
    return history


async def get_login_history(db: Session, history_id: int) -> Optional[LoginHistory]:
    """Get login history record by ID."""
    return db.query(LoginHistory).filter(
        LoginHistory.id == history_id
    ).first()


async def get_user_login_history(
    db: Session,
    user_id: int,
    limit: int = 50,
    offset: int = 0,
) -> Tuple[int, List[LoginHistory]]:
    """
    Get user's login history (paginated).
    
    Returns:
        Tuple of (total_count, records)
    """
    query = db.query(LoginHistory).filter(
        LoginHistory.user_id == user_id
    )
    total = query.count()
    records = query.order_by(desc(LoginHistory.created_at)).limit(limit).offset(offset).all()
    return total, records


async def get_recent_logins_by_ip(
    db: Session,
    ip_address: str,
    hours: int = 24,
    limit: int = 10,
) -> List[LoginHistory]:
    """
    Get recent login attempts from IP address.
    
    Used for rate limiting analysis and security checks.
    """
    cutoff_time = datetime.utcnow() - timedelta(hours=hours)
    return db.query(LoginHistory).filter(
        and_(
            LoginHistory.ip_address == ip_address,
            LoginHistory.created_at >= cutoff_time,
        )
    ).order_by(desc(LoginHistory.created_at)).limit(limit).all()


async def count_failed_logins(
    db: Session,
    user_id: int,
    hours: int = 24,
) -> int:
    """Count failed login attempts in last N hours."""
    cutoff_time = datetime.utcnow() - timedelta(hours=hours)
    return db.query(LoginHistory).filter(
        and_(
            LoginHistory.user_id == user_id,
            LoginHistory.status.in_([LoginStatus.FAILED.value, LoginStatus.BLOCKED.value]),
            LoginHistory.created_at >= cutoff_time,
        )
    ).count()


# ============================================================================
# TRUSTED DEVICES
# ============================================================================

async def register_device(
    db: Session,
    user_id: int,
    device_id: str,
    device_name: Optional[str] = None,
    device_type: str = "web",
    device_fingerprint: Optional[str] = None,
    expires_in_days: int = 30,
) -> LoginDevice:
    """
    Register a device for user.
    
    Args:
        db: Database session
        user_id: User ID
        device_id: Unique device identifier
        device_name: Human-readable device name
        device_type: Device type
        device_fingerprint: Device fingerprint hash
        expires_in_days: Token expiration (default: 30 days)
    
    Returns:
        LoginDevice record
    """
    device = LoginDevice(
        user_id=user_id,
        device_id=device_id,
        device_name=device_name,
        device_type=device_type,
        device_fingerprint=device_fingerprint,
        expires_at=datetime.utcnow() + timedelta(days=expires_in_days),
    )
    db.add(device)
    try:
        db.commit()
        db.refresh(device)
        return device
    except IntegrityError:
        db.rollback()
        # Device already exists, return it
        return await get_device(db, user_id, device_id)


async def get_device(
    db: Session,
    user_id: int,
    device_id: str,
) -> Optional[LoginDevice]:
    """Get device by user ID and device ID."""
    return db.query(LoginDevice).filter(
        and_(
            LoginDevice.user_id == user_id,
            LoginDevice.device_id == device_id,
        )
    ).first()


async def get_user_devices(
    db: Session,
    user_id: int,
    only_trusted: bool = False,
) -> List[LoginDevice]:
    """
    Get user's registered devices.
    
    Args:
        db: Database session
        user_id: User ID
        only_trusted: Return only trusted devices
    
    Returns:
        List of LoginDevice records
    """
    query = db.query(LoginDevice).filter(
        LoginDevice.user_id == user_id
    )
    if only_trusted:
        query = query.filter(LoginDevice.is_trusted == True)
    return query.order_by(desc(LoginDevice.last_used_at)).all()


async def set_device_trusted(
    db: Session,
    user_id: int,
    device_id: str,
    trusted: bool = True,
) -> Optional[LoginDevice]:
    """Mark device as trusted/untrusted."""
    device = await get_device(db, user_id, device_id)
    if device:
        device.is_trusted = trusted
        db.commit()
        db.refresh(device)
    return device


async def update_device_last_used(
    db: Session,
    user_id: int,
    device_id: str,
) -> Optional[LoginDevice]:
    """Update device last_used_at timestamp."""
    device = await get_device(db, user_id, device_id)
    if device:
        device.last_used_at = datetime.utcnow()
        db.commit()
        db.refresh(device)
    return device


async def remove_device(
    db: Session,
    user_id: int,
    device_id: str,
) -> bool:
    """Remove device from trusted list."""
    device = await get_device(db, user_id, device_id)
    if device:
        db.delete(device)
        db.commit()
        return True
    return False


async def remove_all_user_devices(db: Session, user_id: int) -> int:
    """Remove all devices for user."""
    count = db.query(LoginDevice).filter(
        LoginDevice.user_id == user_id
    ).delete()
    db.commit()
    return count


# ============================================================================
# MFA CHALLENGES
# ============================================================================

async def create_mfa_challenge(
    db: Session,
    user_id: int,
    challenge_id: str,
    mfa_method: str,
    challenge_code: bytes,
    max_attempts: int = 5,
    expires_in_minutes: int = 10,
) -> MFAChallenge:
    """
    Create MFA challenge for user verification.
    
    Args:
        db: Database session
        user_id: User ID
        challenge_id: Unique challenge identifier
        mfa_method: MFA method (totp, sms, email)
        challenge_code: Encrypted challenge code
        max_attempts: Maximum verification attempts
        expires_in_minutes: Challenge expiration time
    
    Returns:
        MFAChallenge record
    """
    challenge = MFAChallenge(
        user_id=user_id,
        challenge_id=challenge_id,
        mfa_method=mfa_method,
        challenge_code=challenge_code,
        max_attempts=max_attempts,
        expires_at=datetime.utcnow() + timedelta(minutes=expires_in_minutes),
    )
    db.add(challenge)
    db.commit()
    db.refresh(challenge)
    return challenge


async def get_mfa_challenge(
    db: Session,
    challenge_id: str,
) -> Optional[MFAChallenge]:
    """Get MFA challenge by ID."""
    return db.query(MFAChallenge).filter(
        MFAChallenge.challenge_id == challenge_id
    ).first()


async def verify_mfa_challenge(
    db: Session,
    challenge_id: str,
) -> Optional[MFAChallenge]:
    """Mark MFA challenge as verified."""
    challenge = await get_mfa_challenge(db, challenge_id)
    if challenge:
        challenge.verified = True
        db.commit()
        db.refresh(challenge)
    return challenge


async def increment_challenge_attempts(
    db: Session,
    challenge_id: str,
) -> Optional[MFAChallenge]:
    """Increment challenge verification attempts."""
    challenge = await get_mfa_challenge(db, challenge_id)
    if challenge:
        challenge.attempts += 1
        db.commit()
        db.refresh(challenge)
    return challenge


async def is_challenge_expired(db: Session, challenge_id: str) -> bool:
    """Check if MFA challenge has expired."""
    challenge = await get_mfa_challenge(db, challenge_id)
    if not challenge:
        return True
    return challenge.expires_at <= datetime.utcnow()


async def is_challenge_exhausted(db: Session, challenge_id: str) -> bool:
    """Check if MFA challenge attempts exhausted."""
    challenge = await get_mfa_challenge(db, challenge_id)
    if not challenge:
        return True
    return challenge.attempts >= challenge.max_attempts


async def delete_mfa_challenge(db: Session, challenge_id: str) -> bool:
    """Delete MFA challenge (after successful verification)."""
    challenge = await get_mfa_challenge(db, challenge_id)
    if challenge:
        db.delete(challenge)
        db.commit()
        return True
    return False


# ============================================================================
# RATE LIMITING / THROTTLING
# ============================================================================

async def record_throttle_attempt(
    db: Session,
    user_id: Optional[int],
    ip_address: str,
) -> LoginAttemptThrottle:
    """
    Record login attempt for rate limiting.
    
    Args:
        db: Database session
        user_id: User ID (optional, can throttle by IP alone)
        ip_address: Client IP address
    
    Returns:
        LoginAttemptThrottle record
    """
    throttle = db.query(LoginAttemptThrottle).filter(
        and_(
            LoginAttemptThrottle.user_id == user_id,
            LoginAttemptThrottle.ip_address == ip_address,
        )
    ).first()
    
    if not throttle:
        throttle = LoginAttemptThrottle(
            user_id=user_id,
            ip_address=ip_address,
            failed_attempts=1,
            last_attempt_at=datetime.utcnow(),
        )
        db.add(throttle)
    else:
        throttle.failed_attempts += 1
        throttle.last_attempt_at = datetime.utcnow()
    
    db.commit()
    db.refresh(throttle)
    return throttle


async def get_throttle_record(
    db: Session,
    user_id: Optional[int],
    ip_address: str,
) -> Optional[LoginAttemptThrottle]:
    """Get throttle record for user/IP combination."""
    return db.query(LoginAttemptThrottle).filter(
        and_(
            LoginAttemptThrottle.user_id == user_id,
            LoginAttemptThrottle.ip_address == ip_address,
        )
    ).first()


async def should_throttle(
    db: Session,
    user_id: Optional[int],
    ip_address: str,
    max_attempts: int = 5,
    lockout_minutes: int = 30,
) -> Tuple[bool, Optional[datetime]]:
    """
    Check if login should be throttled.
    
    Returns:
        Tuple of (should_throttle, locked_until)
    """
    throttle = await get_throttle_record(db, user_id, ip_address)
    if not throttle:
        return False, None
    
    # Check if lockout has expired
    if throttle.blocked_until and throttle.blocked_until > datetime.utcnow():
        return True, throttle.blocked_until
    
    # Check if attempts exceeded
    if throttle.failed_attempts >= max_attempts:
        throttle.blocked_until = datetime.utcnow() + timedelta(minutes=lockout_minutes)
        db.commit()
        return True, throttle.blocked_until
    
    return False, None


async def reset_throttle_record(
    db: Session,
    user_id: Optional[int],
    ip_address: str,
) -> bool:
    """
    Reset throttle record (after successful login).
    
    Args:
        db: Database session
        user_id: User ID
        ip_address: Client IP address
    
    Returns:
        True if reset, False if record not found
    """
    throttle = await get_throttle_record(db, user_id, ip_address)
    if throttle:
        throttle.failed_attempts = 0
        throttle.blocked_until = None
        db.commit()
        return True
    return False


async def cleanup_expired_throttle_records(db: Session, older_than_hours: int = 24) -> int:
    """
    Delete expired throttle records (maintenance).
    
    Args:
        db: Database session
        older_than_hours: Delete records older than this
    
    Returns:
        Number of records deleted
    """
    cutoff_time = datetime.utcnow() - timedelta(hours=older_than_hours)
    count = db.query(LoginAttemptThrottle).filter(
        LoginAttemptThrottle.last_attempt_at < cutoff_time
    ).delete()
    db.commit()
    return count
