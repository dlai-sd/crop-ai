"""
Login service database models.

Supports:
- Credential-based login (email/username + password)
- Multi-factor authentication (MFA) with TOTP/SMS
- Login history and audit trail
- Device tracking and management
- Session management
- Login attempt throttling
"""

import enum
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Index,
    Integer,
    LargeBinary,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class MFAMethod(str, enum.Enum):
    """MFA method enumeration."""
    TOTP = "totp"  # Time-based One-Time Password (Google Authenticator)
    SMS = "sms"    # SMS OTP
    EMAIL = "email"  # Email OTP
    NONE = "none"  # No MFA


class LoginDeviceType(str, enum.Enum):
    """Device type enumeration."""
    WEB = "web"
    MOBILE_IOS = "mobile_ios"
    MOBILE_ANDROID = "mobile_android"
    DESKTOP = "desktop"
    TABLET = "tablet"
    OTHER = "other"


class LoginStatus(str, enum.Enum):
    """Login attempt status."""
    SUCCESS = "success"
    FAILED = "failed"
    BLOCKED = "blocked"
    MFA_REQUIRED = "mfa_required"
    MFA_FAILED = "mfa_failed"


class UserLoginCredential(Base):
    """
    User login credentials (separate from auth.users for security).
    
    Stores:
    - Username (for credential-based login)
    - Backup email for login
    - MFA settings
    - Login preferences
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users (unique)
        username: Login username (unique, lowercase)
        backup_email: Secondary email for login recovery
        mfa_enabled: Is MFA enabled
        mfa_method: Current MFA method
        mfa_verified: Is MFA verified/setup complete
        totp_secret: Encrypted TOTP secret
        backup_codes: Encrypted backup codes
        preferred_login_method: Preferred login (email/username)
        allow_insecure_login: Allow login without MFA (if MFA enabled)
        created_at: Credential creation
        updated_at: Last credential update
        last_login_at: Last successful login
        locked_until: Account locked until (for brute force protection)
    """
    __tablename__ = "user_login_credentials"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True, nullable=False, index=True)
    
    # Login identifiers
    username = Column(String(100), unique=True, nullable=False, index=True)
    backup_email = Column(String(255), nullable=True, index=True)
    
    # MFA settings
    mfa_enabled = Column(Boolean, default=False, index=True)
    mfa_method = Column(Enum(MFAMethod), default=MFAMethod.NONE)
    mfa_verified = Column(Boolean, default=False)
    
    # Encrypted secrets (in production, use field-level encryption)
    totp_secret = Column(LargeBinary, nullable=True)  # Encrypted
    backup_codes = Column(LargeBinary, nullable=True)  # Encrypted (comma-separated)
    
    # Login preferences
    preferred_login_method = Column(String(50), default="email")  # email/username
    allow_insecure_login = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login_at = Column(DateTime, nullable=True)
    locked_until = Column(DateTime, nullable=True)  # NULL if not locked
    
    __table_args__ = (
        Index("ix_user_id", "user_id"),
        Index("ix_username", "username"),
    )


class LoginHistory(Base):
    """
    Login attempt audit trail.
    
    Records every login attempt for security analysis and user tracking.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        status: Login success/failure/blocked
        method: Login method (email, username, sso_provider)
        ip_address: Client IP address
        user_agent: Browser/app user agent
        device_type: Device type (web, mobile, etc.)
        device_name: Device name/description
        location_city: Geolocation city (from IP)
        location_country: Geolocation country (from IP)
        mfa_used: Was MFA used
        mfa_method: Which MFA method used
        failure_reason: Reason for failure (invalid credentials, account locked, etc.)
        created_at: Attempt timestamp
    """
    __tablename__ = "login_history"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # Login attempt details
    status = Column(Enum(LoginStatus), nullable=False, index=True)
    method = Column(String(50), nullable=False)  # email, username, google, etc.
    
    # Client information
    ip_address = Column(String(45), nullable=False, index=True)  # IPv4/IPv6
    user_agent = Column(Text, nullable=False)
    device_type = Column(Enum(LoginDeviceType), default=LoginDeviceType.OTHER)
    device_name = Column(String(255), nullable=True)
    
    # Geolocation
    location_city = Column(String(100), nullable=True)
    location_country = Column(String(100), nullable=True)
    location_latitude = Column(String(50), nullable=True)
    location_longitude = Column(String(50), nullable=True)
    
    # MFA details
    mfa_used = Column(Boolean, default=False)
    mfa_method = Column(String(50), nullable=True)
    
    # Failure details
    failure_reason = Column(String(255), nullable=True)
    
    # Timestamp
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    __table_args__ = (
        Index("ix_user_id_created", "user_id", "created_at"),
        Index("ix_ip_address_created", "ip_address", "created_at"),
    )


class LoginDevice(Base):
    """
    Trusted devices for passwordless/enhanced login.
    
    Stores:
    - Device fingerprints
    - Device tokens for trusted login
    - Device history
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        device_id: Unique device identifier (UUID)
        device_name: User-friendly device name (e.g., "My iPhone")
        device_type: Device type (web, mobile, desktop, etc.)
        device_fingerprint: Device fingerprint hash
        trust_token: Token for trusted device login
        is_trusted: Is device marked as trusted
        last_used_at: Last successful login from device
        expires_at: Token expiration
        created_at: Device registration
        updated_at: Last update
    """
    __tablename__ = "login_devices"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # Device identification
    device_id = Column(String(100), unique=True, nullable=False, index=True)
    device_name = Column(String(255), nullable=True)
    device_type = Column(Enum(LoginDeviceType), default=LoginDeviceType.OTHER)
    device_fingerprint = Column(String(255), nullable=True)  # Device fingerprint hash
    
    # Trust and tokens
    trust_token = Column(String(500), unique=True, nullable=True)  # JWT token
    is_trusted = Column(Boolean, default=False, index=True)
    
    # Usage tracking
    last_used_at = Column(DateTime, nullable=True)
    expires_at = Column(DateTime, nullable=False)  # Token expiration (30 days default)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index("ix_user_id_device", "user_id", "device_id"),
        UniqueConstraint("user_id", "device_id", name="uq_user_device"),
    )


class MFAChallenge(Base):
    """
    MFA challenges (TOTP, SMS OTP, Email OTP) in progress.
    
    Temporary records for multi-step MFA verification.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        challenge_id: Unique challenge identifier
        mfa_method: MFA method (totp, sms, email)
        challenge_code: Encrypted challenge code/secret
        attempts: Number of verification attempts
        max_attempts: Maximum allowed attempts (default: 5)
        verified: Has challenge been verified
        created_at: Challenge creation
        expires_at: Challenge expiration (usually 10 minutes)
    """
    __tablename__ = "mfa_challenges"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    
    # Challenge details
    challenge_id = Column(String(100), unique=True, nullable=False, index=True)
    mfa_method = Column(Enum(MFAMethod), nullable=False)
    challenge_code = Column(LargeBinary, nullable=False)  # Encrypted
    
    # Attempt tracking
    attempts = Column(Integer, default=0)
    max_attempts = Column(Integer, default=5)
    verified = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False)  # Usually created_at + 10 min
    
    __table_args__ = (
        Index("ix_user_id_created", "user_id", "created_at"),
    )


class LoginAttemptThrottle(Base):
    """
    Rate limiting for login attempts (brute force protection).
    
    Tracks failed login attempts per IP/user combination.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users (nullable if IP-based throttle)
        ip_address: Client IP address
        failed_attempts: Number of failed attempts
        last_attempt_at: Last failed attempt
        blocked_until: Blocked until time (NULL if not blocked)
    """
    __tablename__ = "login_attempt_throttle"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=True, index=True)
    
    # Throttle identifiers
    ip_address = Column(String(45), nullable=False, index=True)
    
    # Attempt tracking
    failed_attempts = Column(Integer, default=0)
    last_attempt_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    blocked_until = Column(DateTime, nullable=True)
    
    __table_args__ = (
        Index("ix_user_ip", "user_id", "ip_address"),
        UniqueConstraint("user_id", "ip_address", name="uq_user_ip_throttle"),
    )
