"""
Pydantic schemas for registration validation and serialization.

Supports role-specific registration flows for:
- Farmer
- Partner
- Customer
"""
from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, EmailStr, Field

# ============================================================================
# Enumerations
# ============================================================================

class UserRoleSchema(str, Enum):
    """User role."""
    FARMER = "farmer"
    PARTNER = "partner"
    CUSTOMER = "customer"


class RegistrationStatusSchema(str, Enum):
    """Registration status."""
    PENDING = "pending"
    EMAIL_VERIFIED = "email_verified"
    MOBILE_VERIFIED = "mobile_verified"
    COMPLETED = "completed"
    REJECTED = "rejected"


class FarmTypeSchema(str, Enum):
    """Farm type."""
    COMMERCIAL = "commercial"
    SUBSISTENCE = "subsistence"
    ORGANIC = "organic"
    MIXED = "mixed"


class PartnerBusinessTypeSchema(str, Enum):
    """Partner business type."""
    SUPPLIER = "supplier"
    SERVICE_PROVIDER = "service_provider"
    DISTRIBUTOR = "distributor"
    EQUIPMENT_RENTAL = "equipment_rental"
    TRAINING_PROVIDER = "training_provider"
    OTHER = "other"


# ============================================================================
# Common Schemas
# ============================================================================

class LocationBase(BaseModel):
    """GPS location information."""
    latitude: float = Field(..., ge=-90, le=90, description="Latitude")
    longitude: float = Field(..., ge=-180, le=180, description="Longitude")
    location_accuracy: Optional[float] = Field(None, ge=0, description="Accuracy in meters")
    location_source: Optional[str] = Field("manual", description="GPS, manual, or map_selected")


class AddressBase(BaseModel):
    """Address information."""
    address: str = Field(..., min_length=5, max_length=500, description="Street address")
    city: str = Field(..., min_length=2, max_length=100, description="City")
    state: str = Field(..., min_length=2, max_length=100, description="State/Province")
    postal_code: str = Field(..., min_length=2, max_length=20, description="Postal code")
    country: str = Field(default="India", max_length=100, description="Country")


class NotificationPreferences(BaseModel):
    """User notification preferences."""
    notification_email: bool = Field(default=True, description="Email notifications")
    notification_sms: bool = Field(default=True, description="SMS notifications")
    notification_whatsapp: bool = Field(default=False, description="WhatsApp notifications")
    language_preference: str = Field(default="en", max_length=10, description="Language code")


# ============================================================================
# Registration Start Schemas
# ============================================================================

class RegistrationStartRequest(BaseModel):
    """Start registration process."""
    role: UserRoleSchema = Field(..., description="User role")
    registration_method: str = Field(
        ..., 
        description="Registration method: email, mobile, sso_google, sso_microsoft, sso_facebook"
    )
    email: Optional[EmailStr] = Field(None, description="Email (for email registration)")
    mobile: Optional[str] = Field(None, description="Mobile in E.164 format")
    country_code: Optional[str] = Field(default="+91", description="Country code")
    device_type: Optional[str] = Field(None, description="Device type: mobile, desktop, tablet")
    referrer: Optional[str] = Field(None, description="Campaign source")


class RegistrationStartResponse(BaseModel):
    """Registration start response."""
    registration_id: str = Field(..., description="Unique registration session ID")
    role: UserRoleSchema
    registration_method: str
    verification_required: str = Field(..., description="email or sms")
    expires_at: datetime = Field(..., description="Registration session expiry")


# ============================================================================
# Verification Schemas
# ============================================================================

class VerificationTokenRequest(BaseModel):
    """Request verification token."""
    registration_id: str = Field(..., description="Registration session ID")
    token_type: str = Field(..., description="email or sms")


class VerifyTokenRequest(BaseModel):
    """Verify email/SMS token."""
    registration_id: str = Field(..., description="Registration session ID")
    token: str = Field(..., min_length=4, max_length=255, description="Verification token/OTP")
    token_type: str = Field(..., description="email or sms")


class VerifyTokenResponse(BaseModel):
    """Token verification response."""
    verified: bool
    registration_id: str
    next_step: str = Field(..., description="Next step in registration flow")


# ============================================================================
# SSO Schemas
# ============================================================================

class SSOLoginRequest(BaseModel):
    """SSO login request."""
    role: UserRoleSchema = Field(..., description="Selected user role")
    auth_code: str = Field(..., description="OAuth authorization code")
    provider: str = Field(..., description="SSO provider: google, microsoft, facebook")


class SSOUserInfo(BaseModel):
    """User info from SSO provider."""
    provider_user_id: str
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    profile_picture_url: Optional[str] = None


class SSOCallbackResponse(BaseModel):
    """SSO callback response."""
    registration_id: str
    user_exists: bool
    role: UserRoleSchema
    next_step: str = Field(..., description="complete_profile or verify_contact")


# ============================================================================
# Farmer Registration Schemas
# ============================================================================

class FarmerRegistrationData(BaseModel):
    """Farmer registration data (role-specific)."""
    farm_size: float = Field(..., gt=0, description="Farm size")
    farm_size_unit: str = Field(default="acres", description="acres or hectares")
    primary_crop: str = Field(..., min_length=2, max_length=100, description="Primary crop")
    farm_type: FarmTypeSchema = Field(..., description="Farm type")
    experience_level: Optional[int] = Field(None, ge=0, le=100, description="Years of experience")
    irrigation_type: Optional[str] = Field(None, max_length=100, description="Irrigation method")
    secondary_crops: Optional[str] = Field(None, max_length=500, description="Comma-separated")


class FarmerRegistrationRequest(BaseModel):
    """Complete farmer registration request."""
    registration_id: str = Field(..., description="Registration session ID")
    
    # Basic Information
    name: str = Field(..., min_length=3, max_length=255, description="Full name")
    email: EmailStr
    mobile: str = Field(..., min_length=10, max_length=20, description="E.164 format")
    country_code: str = Field(default="+91")
    
    # Address
    address: AddressBase
    location: LocationBase
    
    # Farm Information
    farm_data: FarmerRegistrationData
    
    # Preferences
    preferences: NotificationPreferences = NotificationPreferences()
    
    # Terms
    accept_tos: bool = Field(..., description="Accept terms of service")
    accept_privacy: bool = Field(..., description="Accept privacy policy")


class FarmerProfileResponse(BaseModel):
    """Farmer profile response."""
    user_id: int
    name: str
    email: EmailStr
    mobile: str
    role: UserRoleSchema = UserRoleSchema.FARMER
    status: RegistrationStatusSchema
    
    # Farm Information
    farm_size: float
    farm_size_unit: str
    primary_crop: str
    farm_type: FarmTypeSchema
    
    # Location
    latitude: float
    longitude: float
    city: str
    state: str
    
    # Status
    mobile_verified: bool
    email_verified: bool
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


# ============================================================================
# Partner Registration Schemas
# ============================================================================

class PartnerRegistrationData(BaseModel):
    """Partner registration data (role-specific)."""
    company_name: str = Field(..., min_length=2, max_length=255, description="Company name")
    business_type: PartnerBusinessTypeSchema = Field(..., description="Business type")
    registration_number: str = Field(..., min_length=5, max_length=100, description="Registration number")
    tax_id: str = Field(..., min_length=5, max_length=50, description="Tax ID")
    contact_person: str = Field(..., min_length=3, max_length=255, description="Contact person")
    service_area: Optional[str] = Field(None, max_length=500, description="Comma-separated regions")
    website: Optional[str] = Field(None, max_length=255, description="Website URL")
    certifications: Optional[str] = Field(None, max_length=500, description="Comma-separated")


class PartnerRegistrationRequest(BaseModel):
    """Complete partner registration request."""
    registration_id: str = Field(..., description="Registration session ID")
    
    # Basic Information
    name: str = Field(..., min_length=3, max_length=255, description="Full name")
    email: EmailStr
    mobile: str = Field(..., min_length=10, max_length=20, description="E.164 format")
    country_code: str = Field(default="+91")
    
    # Address
    address: AddressBase
    location: LocationBase
    
    # Partner Information
    partner_data: PartnerRegistrationData
    
    # Preferences
    preferences: NotificationPreferences = NotificationPreferences()
    
    # Terms
    accept_tos: bool = Field(..., description="Accept terms of service")
    accept_privacy: bool = Field(..., description="Accept privacy policy")


class PartnerProfileResponse(BaseModel):
    """Partner profile response."""
    user_id: int
    name: str
    email: EmailStr
    mobile: str
    role: UserRoleSchema = UserRoleSchema.PARTNER
    status: RegistrationStatusSchema
    
    # Company Information
    company_name: str
    business_type: PartnerBusinessTypeSchema
    tax_id: str
    contact_person: str
    
    # Location
    latitude: float
    longitude: float
    city: str
    state: str
    
    # Status
    mobile_verified: bool
    email_verified: bool
    business_verified: bool
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


# ============================================================================
# Customer Registration Schemas
# ============================================================================

class CustomerRegistrationData(BaseModel):
    """Customer registration data (role-specific)."""
    interests: Optional[str] = Field(None, max_length=500, description="Comma-separated interests")
    use_case: Optional[str] = Field(None, max_length=100, description="Use case")
    preferred_contact: str = Field(default="email", description="Preferred contact method")
    organization: Optional[str] = Field(None, max_length=255, description="Organization")
    budget_range: Optional[str] = Field(None, max_length=50, description="Budget range")
    referral_code: Optional[str] = Field(None, max_length=50, description="Referral code")


class CustomerRegistrationRequest(BaseModel):
    """Complete customer registration request."""
    registration_id: str = Field(..., description="Registration session ID")
    
    # Basic Information
    name: str = Field(..., min_length=3, max_length=255, description="Full name")
    email: EmailStr
    mobile: str = Field(..., min_length=10, max_length=20, description="E.164 format")
    country_code: str = Field(default="+91")
    
    # Address (Optional for customers)
    address: Optional[AddressBase] = None
    location: Optional[LocationBase] = None
    
    # Customer Information
    customer_data: CustomerRegistrationData = CustomerRegistrationData()
    
    # Preferences
    preferences: NotificationPreferences = NotificationPreferences()
    
    # Terms
    accept_tos: bool = Field(..., description="Accept terms of service")
    accept_privacy: bool = Field(..., description="Accept privacy policy")


class CustomerProfileResponse(BaseModel):
    """Customer profile response."""
    user_id: int
    name: str
    email: EmailStr
    mobile: str
    role: UserRoleSchema = UserRoleSchema.CUSTOMER
    status: RegistrationStatusSchema
    
    # Interests
    interests: Optional[str]
    use_case: Optional[str]
    preferred_contact: str
    
    # Location (optional)
    city: Optional[str]
    state: Optional[str]
    
    # Status
    mobile_verified: bool
    email_verified: bool
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


# ============================================================================
# General Registration Response
# ============================================================================

class RegistrationCompleteResponse(BaseModel):
    """Registration completion response."""
    success: bool
    user_id: int
    role: UserRoleSchema
    email: EmailStr
    mobile: str
    profile_type: str = Field(..., description="farmer, partner, or customer")
    
    # Authentication
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer")
    expires_in: int = Field(default=900, description="Access token expiry in seconds")
    
    # Next Steps
    next_steps: List[str] = Field(default=[], description="Recommended next steps")
    onboarding_url: Optional[str] = Field(None, description="Onboarding tutorial URL")


class RegistrationErrorResponse(BaseModel):
    """Registration error response."""
    error: str = Field(..., description="Error code")
    message: str = Field(..., description="Error message")
    details: Optional[dict] = Field(None, description="Additional details")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class RegistrationStatusResponse(BaseModel):
    """Check registration status."""
    registration_id: str
    status: RegistrationStatusSchema
    role: UserRoleSchema
    email: Optional[EmailStr] = None
    mobile: Optional[str] = None
    completed: bool
    progress: int = Field(..., ge=0, le=100, description="Progress percentage")
    current_stage: str = Field(..., description="Current registration stage")
