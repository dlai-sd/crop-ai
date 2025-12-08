"""
CRUD operations for registration service.

Database operations for:
- User profiles (all roles)
- Role-specific profiles (Farmer, Partner, Customer)
- SSO accounts
- Verification tokens
- Registration metadata
"""
from datetime import datetime, timedelta
from typing import List, Optional

from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from crop_ai.registration.models import (
    CustomerProfile,
    FarmerProfile,
    PartnerProfile,
    RegistrationMetadata,
    RegistrationStatus,
    SSOAccount,
    UserProfile,
    UserRole,
    VerificationToken,
)

# ============================================================================
# User Profile CRUD
# ============================================================================

def create_user_profile(
    db: Session,
    role: UserRole,
    name: str,
    email: str,
    mobile: str,
    address: str,
    city: str,
    state: str,
    postal_code: str,
    country: str,
    latitude: float,
    longitude: float,
    language_preference: str = "en",
) -> UserProfile:
    """Create new user profile."""
    user_profile = UserProfile(
        role=role,
        status=RegistrationStatus.PENDING,
        name=name,
        email=email,
        mobile=mobile,
        address=address,
        city=city,
        state=state,
        postal_code=postal_code,
        country=country,
        latitude=latitude,
        longitude=longitude,
        language_preference=language_preference,
    )
    db.add(user_profile)
    db.commit()
    db.refresh(user_profile)
    return user_profile


def get_user_profile(db: Session, user_id: int) -> Optional[UserProfile]:
    """Get user profile by ID."""
    return db.query(UserProfile).filter(UserProfile.id == user_id).first()


def get_user_profile_by_email(db: Session, email: str) -> Optional[UserProfile]:
    """Get user profile by email."""
    return db.query(UserProfile).filter(UserProfile.email == email).first()


def get_user_profile_by_mobile(db: Session, mobile: str) -> Optional[UserProfile]:
    """Get user profile by mobile number."""
    return db.query(UserProfile).filter(UserProfile.mobile == mobile).first()


def update_user_profile(
    db: Session,
    user_id: int,
    **updates,
) -> Optional[UserProfile]:
    """Update user profile."""
    profile = get_user_profile(db, user_id)
    if not profile:
        return None
    
    for key, value in updates.items():
        if hasattr(profile, key) and value is not None:
            setattr(profile, key, value)
    
    db.commit()
    db.refresh(profile)
    return profile


def update_user_profile_status(
    db: Session,
    user_id: int,
    status: RegistrationStatus,
) -> Optional[UserProfile]:
    """Update user registration status."""
    profile = get_user_profile(db, user_id)
    if not profile:
        return None
    
    profile.status = status
    
    # Update verification timestamps
    if status == RegistrationStatus.EMAIL_VERIFIED:
        profile.email_verified_at = datetime.utcnow()
    elif status == RegistrationStatus.MOBILE_VERIFIED:
        profile.mobile_verified_at = datetime.utcnow()
    elif status == RegistrationStatus.COMPLETED:
        profile.updated_at = datetime.utcnow()
    
    db.commit()
    db.refresh(profile)
    return profile


def list_user_profiles(
    db: Session,
    role: Optional[UserRole] = None,
    status: Optional[RegistrationStatus] = None,
    city: Optional[str] = None,
    limit: int = 100,
    offset: int = 0,
) -> List[UserProfile]:
    """List user profiles with optional filters."""
    query = db.query(UserProfile)
    
    if role:
        query = query.filter(UserProfile.role == role)
    if status:
        query = query.filter(UserProfile.status == status)
    if city:
        query = query.filter(UserProfile.city == city)
    
    return query.limit(limit).offset(offset).all()


# ============================================================================
# Farmer Profile CRUD
# ============================================================================

def create_farmer_profile(
    db: Session,
    user_id: int,
    farm_size: float,
    farm_size_unit: str,
    primary_crop: str,
    farm_type: str,
    **optional_fields,
) -> FarmerProfile:
    """Create farmer profile."""
    farmer = FarmerProfile(
        user_id=user_id,
        farm_size=farm_size,
        farm_size_unit=farm_size_unit,
        primary_crop=primary_crop,
        farm_type=farm_type,
        **optional_fields,
    )
    db.add(farmer)
    db.commit()
    db.refresh(farmer)
    return farmer


def get_farmer_profile(db: Session, user_id: int) -> Optional[FarmerProfile]:
    """Get farmer profile by user ID."""
    return db.query(FarmerProfile).filter(FarmerProfile.user_id == user_id).first()


def update_farmer_profile(
    db: Session,
    user_id: int,
    **updates,
) -> Optional[FarmerProfile]:
    """Update farmer profile."""
    profile = get_farmer_profile(db, user_id)
    if not profile:
        return None
    
    for key, value in updates.items():
        if hasattr(profile, key) and value is not None:
            setattr(profile, key, value)
    
    db.commit()
    db.refresh(profile)
    return profile


def list_farmers_by_crop(
    db: Session,
    crop: str,
    limit: int = 100,
) -> List[FarmerProfile]:
    """List farmers by primary crop."""
    return (
        db.query(FarmerProfile)
        .filter(FarmerProfile.primary_crop == crop)
        .limit(limit)
        .all()
    )


# ============================================================================
# Partner Profile CRUD
# ============================================================================

def create_partner_profile(
    db: Session,
    user_id: int,
    company_name: str,
    business_type: str,
    registration_number: str,
    tax_id: str,
    contact_person: str,
    **optional_fields,
) -> PartnerProfile:
    """Create partner profile."""
    partner = PartnerProfile(
        user_id=user_id,
        company_name=company_name,
        business_type=business_type,
        registration_number=registration_number,
        tax_id=tax_id,
        contact_person=contact_person,
        **optional_fields,
    )
    db.add(partner)
    db.commit()
    db.refresh(partner)
    return partner


def get_partner_profile(db: Session, user_id: int) -> Optional[PartnerProfile]:
    """Get partner profile by user ID."""
    return db.query(PartnerProfile).filter(PartnerProfile.user_id == user_id).first()


def update_partner_profile(
    db: Session,
    user_id: int,
    **updates,
) -> Optional[PartnerProfile]:
    """Update partner profile."""
    profile = get_partner_profile(db, user_id)
    if not profile:
        return None
    
    for key, value in updates.items():
        if hasattr(profile, key) and value is not None:
            setattr(profile, key, value)
    
    db.commit()
    db.refresh(profile)
    return profile


def get_partner_by_tax_id(db: Session, tax_id: str) -> Optional[PartnerProfile]:
    """Get partner by tax ID."""
    return db.query(PartnerProfile).filter(PartnerProfile.tax_id == tax_id).first()


# ============================================================================
# Customer Profile CRUD
# ============================================================================

def create_customer_profile(
    db: Session,
    user_id: int,
    **optional_fields,
) -> CustomerProfile:
    """Create customer profile."""
    customer = CustomerProfile(
        user_id=user_id,
        **optional_fields,
    )
    db.add(customer)
    db.commit()
    db.refresh(customer)
    return customer


def get_customer_profile(db: Session, user_id: int) -> Optional[CustomerProfile]:
    """Get customer profile by user ID."""
    return db.query(CustomerProfile).filter(CustomerProfile.user_id == user_id).first()


def update_customer_profile(
    db: Session,
    user_id: int,
    **updates,
) -> Optional[CustomerProfile]:
    """Update customer profile."""
    profile = get_customer_profile(db, user_id)
    if not profile:
        return None
    
    for key, value in updates.items():
        if hasattr(profile, key) and value is not None:
            setattr(profile, key, value)
    
    db.commit()
    db.refresh(profile)
    return profile


# ============================================================================
# SSO Account CRUD
# ============================================================================

def create_sso_account(
    db: Session,
    user_id: int,
    provider: str,
    provider_user_id: str,
    email: str,
    name: str,
    profile_picture_url: Optional[str] = None,
    access_token: Optional[str] = None,
    refresh_token: Optional[str] = None,
    token_expiry: Optional[datetime] = None,
) -> SSOAccount:
    """Create SSO account link."""
    sso = SSOAccount(
        user_id=user_id,
        provider=provider,
        provider_user_id=provider_user_id,
        email=email,
        name=name,
        profile_picture_url=profile_picture_url,
        access_token=access_token,
        refresh_token=refresh_token,
        token_expiry=token_expiry,
        linked_at=datetime.utcnow(),
        last_used=datetime.utcnow(),
    )
    db.add(sso)
    db.commit()
    db.refresh(sso)
    return sso


def get_sso_account(db: Session, user_id: int, provider: str) -> Optional[SSOAccount]:
    """Get SSO account by user and provider."""
    return (
        db.query(SSOAccount)
        .filter(and_(SSOAccount.user_id == user_id, SSOAccount.provider == provider))
        .first()
    )


def get_sso_account_by_provider_id(
    db: Session,
    provider: str,
    provider_user_id: str,
) -> Optional[SSOAccount]:
    """Get SSO account by provider and provider user ID."""
    return (
        db.query(SSOAccount)
        .filter(
            and_(
                SSOAccount.provider == provider,
                SSOAccount.provider_user_id == provider_user_id,
            )
        )
        .first()
    )


def list_sso_accounts(db: Session, user_id: int) -> List[SSOAccount]:
    """List all SSO accounts for user."""
    return db.query(SSOAccount).filter(SSOAccount.user_id == user_id).all()


def update_sso_account_last_used(db: Session, sso_id: int) -> Optional[SSOAccount]:
    """Update last used timestamp for SSO account."""
    sso = db.query(SSOAccount).filter(SSOAccount.id == sso_id).first()
    if sso:
        sso.last_used = datetime.utcnow()
        db.commit()
        db.refresh(sso)
    return sso


# ============================================================================
# Verification Token CRUD
# ============================================================================

def create_verification_token(
    db: Session,
    user_id: int,
    token_type: str,
    token: str,
    expires_at: datetime,
    channel: str,
) -> VerificationToken:
    """Create verification token."""
    verification = VerificationToken(
        user_id=user_id,
        token_type=token_type,
        token=token,
        expires_at=expires_at,
        channel=channel,
        attempts=0,
        max_attempts=5,
    )
    db.add(verification)
    db.commit()
    db.refresh(verification)
    return verification


def get_verification_token(
    db: Session,
    user_id: int,
    token_type: str,
) -> Optional[VerificationToken]:
    """Get latest verification token for user."""
    return (
        db.query(VerificationToken)
        .filter(
            and_(
                VerificationToken.user_id == user_id,
                VerificationToken.token_type == token_type,
                VerificationToken.verified_at.is_(None),
            )
        )
        .order_by(VerificationToken.created_at.desc())
        .first()
    )


def increment_verification_attempts(
    db: Session,
    verification_id: int,
) -> Optional[VerificationToken]:
    """Increment verification attempts."""
    verification = (
        db.query(VerificationToken)
        .filter(VerificationToken.id == verification_id)
        .first()
    )
    if verification:
        verification.attempts += 1
        db.commit()
        db.refresh(verification)
    return verification


def mark_verification_complete(
    db: Session,
    verification_id: int,
) -> Optional[VerificationToken]:
    """Mark verification token as verified."""
    verification = (
        db.query(VerificationToken)
        .filter(VerificationToken.id == verification_id)
        .first()
    )
    if verification:
        verification.verified_at = datetime.utcnow()
        db.commit()
        db.refresh(verification)
    return verification


def cleanup_expired_tokens(db: Session) -> int:
    """Clean up expired verification tokens."""
    deleted = db.query(VerificationToken).filter(
        VerificationToken.expires_at < datetime.utcnow()
    ).delete()
    db.commit()
    return deleted


# ============================================================================
# Registration Metadata CRUD
# ============================================================================

def create_registration_metadata(
    db: Session,
    user_id: int,
    registration_method: str,
    device_type: Optional[str] = None,
    device_os: Optional[str] = None,
    browser: Optional[str] = None,
    ip_address: Optional[str] = None,
    country: Optional[str] = None,
    referrer: Optional[str] = None,
    **optional_fields,
) -> RegistrationMetadata:
    """Create registration metadata."""
    metadata = RegistrationMetadata(
        user_id=user_id,
        registration_method=registration_method,
        device_type=device_type,
        device_os=device_os,
        browser=browser,
        ip_address=ip_address,
        country=country,
        referrer=referrer,
        **optional_fields,
    )
    db.add(metadata)
    db.commit()
    db.refresh(metadata)
    return metadata


def get_registration_metadata(db: Session, user_id: int) -> Optional[RegistrationMetadata]:
    """Get registration metadata for user."""
    return (
        db.query(RegistrationMetadata)
        .filter(RegistrationMetadata.user_id == user_id)
        .order_by(RegistrationMetadata.created_at.desc())
        .first()
    )


def update_registration_metadata(
    db: Session,
    user_id: int,
    **updates,
) -> Optional[RegistrationMetadata]:
    """Update registration metadata."""
    metadata = get_registration_metadata(db, user_id)
    if not metadata:
        return None
    
    for key, value in updates.items():
        if hasattr(metadata, key) and value is not None:
            setattr(metadata, key, value)
    
    db.commit()
    db.refresh(metadata)
    return metadata


def get_registration_stats(db: Session, days: int = 30) -> dict:
    """Get registration statistics for the last N days."""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    
    total = db.query(UserProfile).filter(
        UserProfile.created_at >= cutoff_date
    ).count()
    
    by_role = db.query(UserProfile.role, func.count(UserProfile.id)).filter(
        UserProfile.created_at >= cutoff_date
    ).group_by(UserProfile.role).all()
    
    by_method = db.query(
        RegistrationMetadata.registration_method,
        func.count(RegistrationMetadata.id),
    ).filter(
        RegistrationMetadata.created_at >= cutoff_date
    ).group_by(
        RegistrationMetadata.registration_method
    ).all()
    
    completed = db.query(UserProfile).filter(
        and_(
            UserProfile.created_at >= cutoff_date,
            UserProfile.status == RegistrationStatus.COMPLETED,
        )
    ).count()
    
    return {
        "total_registrations": total,
        "completed_registrations": completed,
        "completion_rate": (completed / total * 100) if total > 0 else 0,
        "by_role": {role: count for role, count in by_role},
        "by_method": {method: count for method, count in by_method},
    }
