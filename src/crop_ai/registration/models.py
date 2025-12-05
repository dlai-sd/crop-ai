"""
Registration database models for role-specific user profiles.

Supports three roles:
- Farmer: Agricultural producer
- Partner: Service provider/supplier
- Customer: Consumer/buyer

Each role has distinct registration requirements and profile data.
"""
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, 
    ForeignKey, Enum, Text, UniqueConstraint, Index,
    LargeBinary
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import enum

Base = declarative_base()


class UserRole(str, enum.Enum):
    """User role enumeration."""
    FARMER = "farmer"
    PARTNER = "partner"
    CUSTOMER = "customer"


class RegistrationStatus(str, enum.Enum):
    """Registration status enumeration."""
    PENDING = "pending"
    EMAIL_VERIFIED = "email_verified"
    MOBILE_VERIFIED = "mobile_verified"
    COMPLETED = "completed"
    REJECTED = "rejected"


class FarmType(str, enum.Enum):
    """Farm type enumeration for farmers."""
    COMMERCIAL = "commercial"
    SUBSISTENCE = "subsistence"
    ORGANIC = "organic"
    MIXED = "mixed"


class PartnerBusinessType(str, enum.Enum):
    """Business type enumeration for partners."""
    SUPPLIER = "supplier"
    SERVICE_PROVIDER = "service_provider"
    DISTRIBUTOR = "distributor"
    EQUIPMENT_RENTAL = "equipment_rental"
    TRAINING_PROVIDER = "training_provider"
    OTHER = "other"


class UserProfile(Base):
    """
    Base user profile (common across all roles).
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        role: User role (farmer, partner, customer)
        status: Registration status
        name: Full name
        email: Email address (unique)
        mobile: Phone number with country code (E.164 format)
        country_code: Country code (e.g., +91 for India)
        address: Street address
        city: City
        state: State/Province
        postal_code: Postal/Zip code
        country: Country
        latitude: GPS latitude
        longitude: GPS longitude
        location_accuracy: GPS accuracy in meters
        language_preference: User's preferred language (ISO 639-1, default: en)
        notification_email: Accept email notifications
        notification_sms: Accept SMS notifications
        notification_whatsapp: Accept WhatsApp notifications
        created_at: Account creation timestamp
        updated_at: Last profile update
        mobile_verified_at: Mobile verification timestamp
        email_verified_at: Email verification timestamp
    """
    __tablename__ = "user_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True, nullable=False, index=True)  # FK to auth.users
    role = Column(Enum(UserRole), nullable=False, index=True)
    status = Column(Enum(RegistrationStatus), default=RegistrationStatus.PENDING, index=True)
    
    # Basic Information
    name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False, unique=True, index=True)
    mobile = Column(String(20), nullable=False, unique=True, index=True)  # E.164 format
    country_code = Column(String(5), default="+91")  # Default to India
    
    # Address Information
    address = Column(String(500), nullable=False)
    city = Column(String(100), nullable=False, index=True)
    state = Column(String(100), nullable=False, index=True)
    postal_code = Column(String(20), nullable=False)
    country = Column(String(100), default="India")
    
    # Location (GPS)
    latitude = Column(Float, nullable=False)  # -90 to +90
    longitude = Column(Float, nullable=False)  # -180 to +180
    location_accuracy = Column(Float)  # In meters (from GPS)
    location_source = Column(String(50), default="manual")  # manual, gps, map_selected
    
    # Preferences
    language_preference = Column(String(10), default="en")  # ISO 639-1
    notification_email = Column(Boolean, default=True)
    notification_sms = Column(Boolean, default=True)
    notification_whatsapp = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    mobile_verified_at = Column(DateTime)
    email_verified_at = Column(DateTime)
    
    # Relationships
    farmer_profile = relationship("FarmerProfile", back_populates="user_profile", uselist=False)
    partner_profile = relationship("PartnerProfile", back_populates="user_profile", uselist=False)
    customer_profile = relationship("CustomerProfile", back_populates="user_profile", uselist=False)
    sso_accounts = relationship("SSOAccount", back_populates="user_profile", cascade="all, delete-orphan")
    verification_tokens = relationship("VerificationToken", back_populates="user_profile", cascade="all, delete-orphan")
    
    __table_args__ = (
        UniqueConstraint('email', name='uq_user_profiles_email'),
        UniqueConstraint('mobile', name='uq_user_profiles_mobile'),
        Index('idx_user_profiles_role_status', 'role', 'status'),
        Index('idx_user_profiles_city_state', 'city', 'state'),
    )


class FarmerProfile(Base):
    """
    Farmer-specific profile information.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        farm_size: Size of farm (stored as numerical value)
        farm_size_unit: Unit (acres or hectares)
        primary_crop: Main crop cultivated
        farm_type: Type of farm (commercial, subsistence, organic, mixed)
        experience_level: Years of farming experience (optional)
        irrigation_type: Irrigation method (optional)
        secondary_crops: Comma-separated list (optional)
        adhaar_token: Placeholder for ADHAAR (encrypted, future)
        verified: Whether profile is verified
    """
    __tablename__ = "farmer_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.user_id"), unique=True, nullable=False, index=True)
    
    # Farm Information (Required)
    farm_size = Column(Float, nullable=False)  # Numerical value
    farm_size_unit = Column(String(20), default="acres")  # acres or hectares
    primary_crop = Column(String(100), nullable=False, index=True)
    farm_type = Column(Enum(FarmType), nullable=False)
    
    # Optional Information
    experience_level = Column(Integer)  # Years of experience (0-100)
    irrigation_type = Column(String(100))  # e.g., drip, flood, sprinkler, rain-fed
    secondary_crops = Column(Text)  # Comma-separated
    
    # ADHAAR (Future)
    adhaar_token = Column(String(255))  # Encrypted, placeholder for now
    adhaar_status = Column(String(50), default="pending")  # pending, verified, rejected
    
    # Verification
    verified = Column(Boolean, default=False)
    verified_at = Column(DateTime)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user_profile = relationship("UserProfile", back_populates="farmer_profile")
    
    __table_args__ = (
        Index('idx_farmer_profiles_primary_crop', 'primary_crop'),
        Index('idx_farmer_profiles_farm_type', 'farm_type'),
    )


class PartnerProfile(Base):
    """
    Partner-specific profile information.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        company_name: Official company name
        business_type: Type of business
        registration_number: Business registration/license number
        tax_id: Tax identification number (GST in India)
        contact_person: Primary contact person name
        service_area: Geographic service area (comma-separated)
        website: Company website URL
        certifications: Professional certifications (comma-separated)
        verified: Business verification status
    """
    __tablename__ = "partner_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.user_id"), unique=True, nullable=False, index=True)
    
    # Business Information (Required)
    company_name = Column(String(255), nullable=False, unique=True, index=True)
    business_type = Column(Enum(PartnerBusinessType), nullable=False)
    registration_number = Column(String(100), unique=True, nullable=False)
    tax_id = Column(String(50), unique=True, nullable=False)  # GST ID for India
    contact_person = Column(String(255), nullable=False)
    
    # Business Details
    service_area = Column(Text)  # Comma-separated cities/regions
    website = Column(String(255))
    certifications = Column(Text)  # Comma-separated
    
    # Verification
    verified = Column(Boolean, default=False)
    verified_at = Column(DateTime)
    registration_verified = Column(Boolean, default=False)
    tax_verified = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user_profile = relationship("UserProfile", back_populates="partner_profile")
    
    __table_args__ = (
        UniqueConstraint('company_name', name='uq_partner_profiles_company_name'),
        UniqueConstraint('registration_number', name='uq_partner_profiles_registration'),
        UniqueConstraint('tax_id', name='uq_partner_profiles_tax_id'),
        Index('idx_partner_profiles_business_type', 'business_type'),
    )


class CustomerProfile(Base):
    """
    Customer-specific profile information.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        interests: Comma-separated interests (e.g., crops, equipment, training)
        use_case: Primary use case
        preferred_contact: Preferred contact method
        organization: Associated organization (optional)
        budget_range: Budget indicator (optional)
        profile_photo_url: URL to profile photo (optional)
        referral_code: Used referral code (optional)
    """
    __tablename__ = "customer_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.user_id"), unique=True, nullable=False, index=True)
    
    # Interests & Preferences
    interests = Column(Text)  # Comma-separated: crops, equipment, training, seeds, etc.
    use_case = Column(String(100))  # e.g., personal_use, resale, comparison
    preferred_contact = Column(String(50), default="email")  # email, sms, whatsapp, phone
    
    # Additional Information
    organization = Column(String(255))  # Optional
    budget_range = Column(String(50))  # e.g., low, medium, high
    
    # Profile Media
    profile_photo_url = Column(String(500))
    
    # Engagement
    referral_code = Column(String(50), unique=True)  # Used referral code
    referred_by = Column(String(50))  # Referrer code
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user_profile = relationship("UserProfile", back_populates="customer_profile")
    
    __table_args__ = (
        Index('idx_customer_profiles_interests', 'interests'),
        Index('idx_customer_profiles_use_case', 'use_case'),
    )


class SSOAccount(Base):
    """
    Social Sign-On account linking.
    
    Tracks SSO provider accounts linked to user profiles.
    Supports Google, Microsoft, Facebook, and other OAuth providers.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        provider: OAuth provider name (google, microsoft, facebook, etc.)
        provider_user_id: Sub claim from provider (unique per provider)
        email: Email from provider
        name: Name from provider
        profile_picture_url: Profile picture from provider
        access_token: Encrypted OAuth access token
        refresh_token: Encrypted OAuth refresh token (if applicable)
        token_expiry: Token expiration timestamp
        linked_at: When account was linked
    """
    __tablename__ = "sso_accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.user_id"), nullable=False, index=True)
    
    # Provider Information
    provider = Column(String(50), nullable=False, index=True)  # google, microsoft, facebook, etc.
    provider_user_id = Column(String(500), nullable=False)  # OAuth sub claim
    
    # User Data from Provider
    email = Column(String(255))
    name = Column(String(255))
    profile_picture_url = Column(String(500))
    
    # Token Management
    access_token = Column(Text)  # Encrypted
    refresh_token = Column(Text)  # Encrypted
    token_expiry = Column(DateTime)
    
    # Timestamps
    linked_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    last_used = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('provider', 'provider_user_id', name='uq_sso_provider_user_id'),
        Index('idx_sso_accounts_provider', 'provider'),
    )


class VerificationToken(Base):
    """
    Email and SMS verification tokens.
    
    Stores one-time verification tokens for:
    - Email verification (6-8 char token or link)
    - SMS OTP (6-digit code)
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        token_type: Type of verification (email, sms)
        token: The verification code/token
        expires_at: Token expiration time (10 minutes typical for OTP)
        verified_at: When verification was completed
        attempts: Number of verification attempts
        max_attempts: Maximum allowed attempts (3-5 typically)
    """
    __tablename__ = "verification_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.user_id"), nullable=False, index=True)
    
    # Token Details
    token_type = Column(String(50), nullable=False)  # email, sms
    token = Column(String(255), nullable=False, unique=True, index=True)
    
    # Token Lifecycle
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    verified_at = Column(DateTime)
    
    # Attempt Tracking
    attempts = Column(Integer, default=0)
    max_attempts = Column(Integer, default=5)
    
    # Additional Data
    channel = Column(String(100))  # email_address, phone_number (for audit)
    
    __table_args__ = (
        UniqueConstraint('token', name='uq_verification_tokens_token'),
        Index('idx_verification_tokens_user_type', 'user_id', 'token_type'),
        Index('idx_verification_tokens_expires', 'expires_at'),
    )


class RegistrationMetadata(Base):
    """
    Registration metadata and analytics.
    
    Tracks registration flow data for analytics and debugging.
    
    Attributes:
        id: Primary key
        user_id: Link to auth.users
        registration_method: How user registered (sso_google, sso_microsoft, email, mobile)
        referrer: HTTP referrer/campaign source
        device_type: Device used (mobile, desktop, tablet)
        device_os: Operating system
        browser: Browser name
        ip_address: Registration IP address
        country: Country detected from IP
        form_completion_time: Time taken to complete registration (seconds)
        form_abandonment_stage: Stage at which user abandoned (if incomplete)
        language_code: Language used during registration
        created_at: Registration timestamp
    """
    __tablename__ = "registration_metadata"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("user_profiles.user_id"), nullable=False, index=True)
    
    # Registration Channel
    registration_method = Column(String(50), nullable=False, index=True)
    referrer = Column(String(500))  # Campaign/source
    
    # Device Information
    device_type = Column(String(50))  # mobile, desktop, tablet
    device_os = Column(String(50))  # iOS, Android, Windows, macOS, Linux
    browser = Column(String(100))
    
    # Network Information
    ip_address = Column(String(45))  # IPv4 or IPv6
    country = Column(String(100))
    
    # Form Analytics
    form_completion_time = Column(Integer)  # Seconds
    form_abandonment_stage = Column(String(100))  # If incomplete
    
    # Localization
    language_code = Column(String(10), default="en")
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    __table_args__ = (
        Index('idx_registration_metadata_method', 'registration_method'),
        Index('idx_registration_metadata_country', 'country'),
        Index('idx_registration_metadata_device', 'device_type', 'device_os'),
    )
