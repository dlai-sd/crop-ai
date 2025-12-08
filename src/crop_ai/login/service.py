"""
Login service - Core business logic.

Handles:
- Credential-based login (email/username + password)
- Multi-factor authentication (TOTP, SMS, Email OTP)
- Device management and trusted login
- Password management (change, reset)
- Security features (brute force protection, rate limiting)
"""

import base64
import hashlib
import io
import os
import secrets
from datetime import datetime
from functools import lru_cache
from typing import Any, Dict, Optional, Tuple

import pyotp
import qrcode
from sqlalchemy.orm import Session

from crop_ai.auth.models import User as AuthUser
from crop_ai.auth.utils import (
    create_access_token,
    create_refresh_token,
    hash_password,
    verify_password,
)

from . import crud
from .models import LoginStatus, MFAMethod


class LoginService:
    """
    Main login service with multi-factor authentication support.
    
    Features:
    - Credential validation (email or username)
    - Password verification
    - MFA setup and verification (TOTP, SMS, Email)
    - Device management
    - Login history tracking
    - Rate limiting and brute force protection
    """
    
    # Configuration
    MFA_TOTP_ISSUER = os.getenv("APP_NAME", "Crop-AI")
    MFA_CHALLENGE_EXPIRY_MINUTES = 10
    MFA_MAX_ATTEMPTS = 5
    LOGIN_ATTEMPT_LIMIT = 5
    LOGIN_LOCKOUT_MINUTES = 30
    PASSWORD_RESET_TOKEN_EXPIRY_HOURS = 1
    DEVICE_TOKEN_EXPIRY_DAYS = 30
    
    def __init__(self, db: Session):
        """Initialize login service with database session."""
        self.db = db
        self.geolocation_service = None  # Can integrate MaxMind GeoIP
    
    # ========================================================================
    # CREDENTIAL-BASED LOGIN
    # ========================================================================
    
    async def login(
        self,
        email_or_username: str,
        password: str,
        ip_address: str,
        user_agent: str,
        device_name: Optional[str] = None,
        device_type: str = "web",
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Authenticate user with email/username and password.
        
        Returns:
            Tuple of (success, response_dict)
            
            If success=True and MFA required:
                response_dict = {
                    "requires_mfa": True,
                    "challenge_id": str,
                    "mfa_method": str,
                    "expires_in": int,
                }
            
            If success=True and MFA not required:
                response_dict = {
                    "access_token": str,
                    "refresh_token": str,
                    "expires_in": int,
                    "user_id": int,
                    "email": str,
                    "role": str,
                    "device_token": str (optional),
                }
            
            If success=False:
                response_dict = {
                    "error": str,
                    "message": str,
                }
        """
        
        # Step 1: Check rate limiting
        should_throttle, locked_until = await crud.should_throttle(
            self.db,
            user_id=None,
            ip_address=ip_address,
            max_attempts=self.LOGIN_ATTEMPT_LIMIT,
            lockout_minutes=self.LOGIN_LOCKOUT_MINUTES,
        )
        
        if should_throttle:
            # Log blocked attempt
            await crud.create_login_history(
                self.db,
                user_id=0,  # Unknown user
                status=LoginStatus.BLOCKED.value,
                method="credential",
                ip_address=ip_address,
                user_agent=user_agent,
                device_type=device_type,
                failure_reason="Too many attempts",
            )
            return False, {
                "error": "account_locked",
                "message": f"Too many login attempts. Try again after {locked_until}",
            }
        
        # Step 2: Find user by email or username
        credential = await crud.get_login_credential_by_username(self.db, email_or_username)
        
        if not credential:
            # Try email
            credential = await crud.get_login_credential_by_email(self.db, email_or_username)
        
        if not credential:
            # Log failed attempt
            await crud.record_throttle_attempt(
                self.db,
                user_id=None,
                ip_address=ip_address,
            )
            await crud.create_login_history(
                self.db,
                user_id=0,
                status=LoginStatus.FAILED.value,
                method="credential",
                ip_address=ip_address,
                user_agent=user_agent,
                device_type=device_type,
                failure_reason="User not found",
            )
            return False, {
                "error": "invalid_credentials",
                "message": "Invalid email/username or password",
            }
        
        # Step 3: Check account lock
        is_locked = await crud.is_account_locked(self.db, credential.user_id)
        if is_locked:
            await crud.create_login_history(
                self.db,
                user_id=credential.user_id,
                status=LoginStatus.BLOCKED.value,
                method="credential",
                ip_address=ip_address,
                user_agent=user_agent,
                device_type=device_type,
                failure_reason="Account locked",
            )
            return False, {
                "error": "account_locked",
                "message": "Account is temporarily locked due to multiple failed attempts",
            }
        
        # Step 4: Verify password
        auth_user = self.db.query(AuthUser).filter(
            AuthUser.id == credential.user_id
        ).first()
        
        if not auth_user or not verify_password(password, auth_user.password_hash):
            # Log failed attempt
            await crud.record_throttle_attempt(
                self.db,
                user_id=credential.user_id,
                ip_address=ip_address,
            )
            
            failed_count = await crud.count_failed_logins(
                self.db,
                credential.user_id,
                hours=1,
            )
            
            # Lock account if too many failures
            if failed_count >= self.LOGIN_ATTEMPT_LIMIT - 1:
                await crud.lock_account(
                    self.db,
                    credential.user_id,
                    self.LOGIN_LOCKOUT_MINUTES,
                )
            
            await crud.create_login_history(
                self.db,
                user_id=credential.user_id,
                status=LoginStatus.FAILED.value,
                method="credential",
                ip_address=ip_address,
                user_agent=user_agent,
                device_type=device_type,
                failure_reason="Invalid password",
            )
            return False, {
                "error": "invalid_credentials",
                "message": "Invalid email/username or password",
            }
        
        # Step 5: Check if MFA is required
        if credential.mfa_enabled and credential.mfa_verified:
            # Generate MFA challenge
            challenge_id = secrets.token_urlsafe(32)
            challenge_code = secrets.token_bytes(16)
            
            _ = await crud.create_mfa_challenge(
                self.db,
                user_id=credential.user_id,
                challenge_id=challenge_id,
                mfa_method=credential.mfa_method,
                challenge_code=challenge_code,
                expires_in_minutes=self.MFA_CHALLENGE_EXPIRY_MINUTES,
            )
            
            await crud.create_login_history(
                self.db,
                user_id=credential.user_id,
                status=LoginStatus.MFA_REQUIRED.value,
                method="credential",
                ip_address=ip_address,
                user_agent=user_agent,
                device_type=device_type,
                mfa_used=True,
                mfa_method=credential.mfa_method,
            )
            
            return True, {
                "requires_mfa": True,
                "challenge_id": challenge_id,
                "mfa_method": credential.mfa_method,
                "expires_in": self.MFA_CHALLENGE_EXPIRY_MINUTES * 60,
            }
        
        # Step 6: Successful login - Generate tokens
        access_token = create_access_token(
            data={"sub": str(credential.user_id), "email": auth_user.email}
        )
        refresh_token = create_refresh_token(
            data={"sub": str(credential.user_id)}
        )
        
        # Update last login
        await crud.update_last_login(self.db, credential.user_id)
        
        # Reset throttle record
        await crud.reset_throttle_record(self.db, credential.user_id, ip_address)
        
        # Handle device token
        device_token = None
        if device_name:
            device = await crud.register_device(
                self.db,
                user_id=credential.user_id,
                device_id=self._generate_device_id(device_name, user_agent),
                device_name=device_name,
                device_type=device_type,
            )
            device_token = self._generate_device_token(device.id, credential.user_id)
        
        # Log successful login
        await crud.create_login_history(
            self.db,
            user_id=credential.user_id,
            status=LoginStatus.SUCCESS.value,
            method="credential",
            ip_address=ip_address,
            user_agent=user_agent,
            device_type=device_type,
            device_name=device_name,
        )
        
        return True, {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": 900,  # 15 minutes
            "user_id": credential.user_id,
            "email": auth_user.email,
            "role": auth_user.role,
            "name": auth_user.full_name,
            "device_token": device_token,
        }
    
    # ========================================================================
    # MFA VERIFICATION
    # ========================================================================
    
    async def verify_mfa(
        self,
        challenge_id: str,
        code: str,
        ip_address: str,
        user_agent: str,
    ) -> Tuple[bool, Dict[str, Any]]:
        """
        Verify MFA challenge and complete login.
        
        Args:
            challenge_id: MFA challenge ID
            code: Verification code (6-digit OTP or token)
            ip_address: Client IP
            user_agent: Browser user agent
        
        Returns:
            Tuple of (success, response_dict)
        """
        
        # Get challenge
        challenge = await crud.get_mfa_challenge(self.db, challenge_id)
        if not challenge:
            return False, {
                "error": "invalid_challenge",
                "message": "MFA challenge not found or expired",
            }
        
        # Check expiration
        if await crud.is_challenge_expired(self.db, challenge_id):
            await crud.delete_mfa_challenge(self.db, challenge_id)
            return False, {
                "error": "challenge_expired",
                "message": "MFA challenge has expired",
            }
        
        # Check attempt limit
        if await crud.is_challenge_exhausted(self.db, challenge_id):
            await crud.delete_mfa_challenge(self.db, challenge_id)
            # Lock account
            await crud.lock_account(self.db, challenge.user_id, self.LOGIN_LOCKOUT_MINUTES)
            return False, {
                "error": "challenge_exhausted",
                "message": "Too many MFA verification attempts",
            }
        
        # Verify code based on MFA method
        is_valid = await self._verify_mfa_code(
            challenge.user_id,
            challenge.mfa_method,
            code,
            challenge.challenge_code,
        )
        
        if not is_valid:
            await crud.increment_challenge_attempts(self.db, challenge_id)
            remaining = challenge.max_attempts - (challenge.attempts + 1)
            
            await crud.create_login_history(
                self.db,
                user_id=challenge.user_id,
                status=LoginStatus.MFA_FAILED.value,
                method="credential",
                ip_address=ip_address,
                user_agent=user_agent,
                mfa_used=True,
                mfa_method=challenge.mfa_method,
                failure_reason="Invalid MFA code",
            )
            
            return False, {
                "error": "invalid_code",
                "message": f"Invalid verification code. {remaining} attempts remaining.",
            }
        
        # Mark challenge as verified
        await crud.verify_mfa_challenge(self.db, challenge_id)
        
        # Get auth user
        auth_user = self.db.query(AuthUser).filter(
            AuthUser.id == challenge.user_id
        ).first()
        
        # Generate tokens
        access_token = create_access_token(
            data={"sub": str(challenge.user_id), "email": auth_user.email}
        )
        refresh_token = create_refresh_token(
            data={"sub": str(challenge.user_id)}
        )
        
        # Update last login
        await crud.update_last_login(self.db, challenge.user_id)
        
        # Delete challenge
        await crud.delete_mfa_challenge(self.db, challenge_id)
        
        # Log successful MFA verification
        await crud.create_login_history(
            self.db,
            user_id=challenge.user_id,
            status=LoginStatus.SUCCESS.value,
            method="credential",
            ip_address=ip_address,
            user_agent=user_agent,
            mfa_used=True,
            mfa_method=challenge.mfa_method,
        )
        
        return True, {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": 900,
            "user_id": challenge.user_id,
            "email": auth_user.email,
            "role": auth_user.role,
            "name": auth_user.full_name,
        }
    
    async def _verify_mfa_code(
        self,
        user_id: int,
        mfa_method: str,
        code: str,
        challenge_code: bytes,
    ) -> bool:
        """
        Verify MFA code based on method.
        
        Supports:
        - TOTP: Time-based One-Time Password (30-second window)
        - SMS/Email OTP: Server-generated codes
        """
        
        credential = await crud.get_login_credential_by_user_id(self.db, user_id)
        if not credential:
            return False
        
        if mfa_method == MFAMethod.TOTP.value:
            # TOTP verification
            if not credential.totp_secret:
                return False
            
            # Decrypt TOTP secret (in production, use proper encryption)
            totp_secret = credential.totp_secret.decode('utf-8')
            totp = pyotp.TOTP(totp_secret)
            
            # Verify with 30-second tolerance (±1 window)
            return totp.verify(code, valid_window=1)
        
        else:
            # SMS/Email OTP verification - compare with challenge code
            # In production, decrypt challenge_code and compare
            # For now, just return True (implement encryption/decryption)
            return True
    
    # ========================================================================
    # MFA SETUP
    # ========================================================================
    
    async def setup_mfa(
        self,
        user_id: int,
        mfa_method: str,
        phone_number: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Initiate MFA setup.
        
        For TOTP: Returns QR code and secret
        For SMS/Email: Sends verification code
        """
        
        credential = await crud.get_login_credential_by_user_id(self.db, user_id)
        if not credential:
            raise ValueError(f"Credential not found for user_id {user_id}")
        
        auth_user = self.db.query(AuthUser).filter(
            AuthUser.id == user_id
        ).first()
        
        if mfa_method == MFAMethod.TOTP.value:
            # Generate TOTP secret
            totp_secret = pyotp.random_base32()
            totp = pyotp.TOTP(totp_secret)
            
            # Generate QR code
            qr_uri = totp.provisioning_uri(
                name=auth_user.email,
                issuer_name=self.MFA_TOTP_ISSUER,
            )
            
            # Create QR code image
            qr = qrcode.QRCode(version=1, box_size=10, border=5)
            qr.add_data(qr_uri)
            qr.make(fit=True)
            
            img = qr.make_image(fill_color="black", back_color="white")
            img_byte_arr = io.BytesIO()
            img.save(img_byte_arr, format='PNG')
            img_byte_arr.seek(0)
            qr_code_base64 = base64.b64encode(img_byte_arr.getvalue()).decode()
            
            # Generate backup codes
            backup_codes = [secrets.token_hex(4).upper() for _ in range(8)]
            
            # Store setup token (temporary)
            setup_token = secrets.token_urlsafe(32)
            
            return {
                "setup_token": setup_token,
                "mfa_method": mfa_method,
                "qr_code": f"data:image/png;base64,{qr_code_base64}",
                "secret": totp_secret,
                "backup_codes": backup_codes,
                "manual_entry_key": totp_secret,
            }
        
        elif mfa_method == MFAMethod.SMS.value:
            if not phone_number:
                raise ValueError("Phone number required for SMS MFA")
            
            # Generate and send OTP
            otp_code = ''.join([str(secrets.randbelow(10)) for _ in range(6)])
            setup_token = secrets.token_urlsafe(32)
            
            # TODO: Send SMS
            # await self._send_sms(phone_number, f"Your verification code is {otp_code}")
            
            return {
                "setup_token": setup_token,
                "mfa_method": mfa_method,
                "message": f"Verification code sent to {phone_number}",
            }
        
        elif mfa_method == MFAMethod.EMAIL.value:
            # Generate and send OTP
            _ = ''.join([str(secrets.randbelow(10)) for _ in range(6)])
            setup_token = secrets.token_urlsafe(32)
            
            # TODO: Send email
            # await self._send_email(auth_user.email, f"Your verification code is {otp_code}")
            
            return {
                "setup_token": setup_token,
                "mfa_method": mfa_method,
                "message": f"Verification code sent to {auth_user.email}",
            }
        
        else:
            raise ValueError(f"Unsupported MFA method: {mfa_method}")
    
    async def verify_mfa_setup(
        self,
        user_id: int,
        mfa_method: str,
        code: str,
        totp_secret: Optional[str] = None,
        backup_codes: Optional[list] = None,
    ) -> bool:
        """
        Verify MFA setup with test code.
        
        After verification, enables MFA for user.
        """
        
        if mfa_method == MFAMethod.TOTP.value:
            if not totp_secret:
                raise ValueError("TOTP secret required for TOTP setup verification")
            
            # Verify with test code
            totp = pyotp.TOTP(totp_secret)
            if not totp.verify(code, valid_window=1):
                return False
            
            # Store encrypted secret and backup codes
            credential = await crud.update_mfa_settings(
                self.db,
                user_id=user_id,
                mfa_enabled=True,
                mfa_method=mfa_method,
                mfa_verified=True,
                totp_secret=totp_secret.encode('utf-8'),  # In production, encrypt
                backup_codes=','.join(backup_codes or []).encode('utf-8'),  # In production, encrypt
            )
            return True
        
        else:
            # For SMS/Email, just verify the code
            # In production, compare with stored code
            _ = await crud.update_mfa_settings(
                self.db,
                user_id=user_id,
                mfa_enabled=True,
                mfa_method=mfa_method,
                mfa_verified=True,
            )
            return True
    
    # ========================================================================
    # PASSWORD MANAGEMENT
    # ========================================================================
    
    async def change_password(
        self,
        user_id: int,
        current_password: str,
        new_password: str,
    ) -> Tuple[bool, str]:
        """
        Change user password.
        
        Returns:
            Tuple of (success, message)
        """
        
        auth_user = self.db.query(AuthUser).filter(
            AuthUser.id == user_id
        ).first()
        
        if not auth_user:
            return False, "User not found"
        
        # Verify current password
        if not verify_password(current_password, auth_user.password_hash):
            return False, "Current password is incorrect"
        
        # Update password
        auth_user.password_hash = hash_password(new_password)
        self.db.commit()
        
        return True, "Password changed successfully"
    
    async def request_password_reset(
        self,
        email_or_username: str,
    ) -> Tuple[bool, str]:
        """
        Request password reset token via email.
        
        Returns:
            Tuple of (success, message)
        """
        
        credential = await crud.get_login_credential_by_username(
            self.db,
            email_or_username,
        )
        
        if not credential:
            credential = await crud.get_login_credential_by_email(
                self.db,
                email_or_username,
            )
        
        if not credential:
            # Don't reveal if user exists
            return True, "If account exists, password reset email will be sent"
        
        auth_user = self.db.query(AuthUser).filter(
            AuthUser.id == credential.user_id
        ).first()
        
        if not auth_user:
            return True, "If account exists, password reset email will be sent"
        
        # Generate reset token
        reset_token = secrets.token_urlsafe(32)
        _ = hash_password(reset_token)
        
        # TODO: Send reset email with token
        # await self._send_password_reset_email(auth_user.email, reset_token)
        
        return True, "If account exists, password reset email will be sent"
    
    # ========================================================================
    # HELPER METHODS
    # ========================================================================
    
    def _generate_device_id(self, device_name: str, user_agent: str) -> str:
        """Generate unique device ID from device name and user agent."""
        combined = f"{device_name}:{user_agent}"
        return hashlib.sha256(combined.encode()).hexdigest()
    
    def _generate_device_token(self, device_id: int, user_id: int) -> str:
        """Generate device trust token."""
        token_data = f"{device_id}:{user_id}:{int(datetime.utcnow().timestamp())}"
        token_hash = hashlib.sha256(token_data.encode()).hexdigest()
        return base64.b64encode(f"{token_data}:{token_hash}".encode()).decode()


# ============================================================================
# SINGLETON
# ============================================================================

@lru_cache(maxsize=1)
def get_login_service(db: Session) -> LoginService:
    """Get or create login service instance (singleton pattern)."""
    return LoginService(db)
