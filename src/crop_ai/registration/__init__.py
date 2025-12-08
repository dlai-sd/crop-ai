"""
Registration microservice module.

Provides:
- User registration for multiple roles (Farmer, Partner, Customer)
- Multi-provider SSO (Google, Microsoft, Facebook)
- Email and SMS verification
- Registration analytics and tracking
"""

from crop_ai.registration import crud, init_db
from crop_ai.registration.location import (
    Address,
    DistanceCalculator,
    GeocodeProvider,
    GoogleMapsGeocoder,
    GPSCoordinates,
    LocationData,
    LocationService,
    LocationValidator,
    MockGeocoder,
    get_location_service,
)
from crop_ai.registration.models import (
    CustomerProfile,
    FarmerProfile,
    FarmType,
    PartnerBusinessType,
    PartnerProfile,
    RegistrationMetadata,
    RegistrationStatus,
    SSOAccount,
    UserProfile,
    UserRole,
    VerificationToken,
)
from crop_ai.registration.routes import router as registration_router
from crop_ai.registration.schemas import (
    CustomerProfileResponse,
    CustomerRegistrationRequest,
    FarmerProfileResponse,
    FarmerRegistrationRequest,
    FarmTypeSchema,
    PartnerBusinessTypeSchema,
    PartnerProfileResponse,
    PartnerRegistrationRequest,
    RegistrationCompleteResponse,
    RegistrationErrorResponse,
    RegistrationStartRequest,
    RegistrationStartResponse,
    RegistrationStatusResponse,
    RegistrationStatusSchema,
    SSOCallbackResponse,
    SSOLoginRequest,
    UserRoleSchema,
    VerifyTokenRequest,
    VerifyTokenResponse,
)
from crop_ai.registration.sso import (
    FacebookOAuthProvider,
    GoogleOAuthProvider,
    MicrosoftOAuthProvider,
    SSOProviderManager,
    SSOTokenResponse,
    SSOUserInfo,
    get_sso_manager,
)
from crop_ai.registration.verification import (
    AmazonSNSSMSProvider,
    EmailProvider,
    MockEmailProvider,
    SMSProvider,
    SMTPEmailProvider,
    TwilioSMSProvider,
    VerificationConfig,
    VerificationService,
    VerificationTokenGenerator,
    get_verification_service,
)

__all__ = [
    # Models
    "UserProfile",
    "FarmerProfile",
    "PartnerProfile",
    "CustomerProfile",
    "SSOAccount",
    "VerificationToken",
    "RegistrationMetadata",
    "UserRole",
    "RegistrationStatus",
    "FarmType",
    "PartnerBusinessType",
    
    # Schemas
    "UserRoleSchema",
    "RegistrationStatusSchema",
    "FarmTypeSchema",
    "PartnerBusinessTypeSchema",
    "RegistrationStartRequest",
    "RegistrationStartResponse",
    "VerifyTokenRequest",
    "VerifyTokenResponse",
    "FarmerRegistrationRequest",
    "FarmerProfileResponse",
    "PartnerRegistrationRequest",
    "PartnerProfileResponse",
    "CustomerRegistrationRequest",
    "CustomerProfileResponse",
    "RegistrationCompleteResponse",
    "RegistrationErrorResponse",
    "RegistrationStatusResponse",
    "SSOLoginRequest",
    "SSOCallbackResponse",
    
    # SSO
    "GoogleOAuthProvider",
    "MicrosoftOAuthProvider",
    "FacebookOAuthProvider",
    "SSOProviderManager",
    "SSOUserInfo",
    "SSOTokenResponse",
    "get_sso_manager",
    
    # Verification
    "VerificationService",
    "VerificationTokenGenerator",
    "VerificationConfig",
    "SMSProvider",
    "TwilioSMSProvider",
    "AmazonSNSSMSProvider",
    "EmailProvider",
    "SMTPEmailProvider",
    "MockEmailProvider",
    "get_verification_service",
    
    # Location
    "LocationService",
    "LocationValidator",
    "LocationData",
    "GPSCoordinates",
    "Address",
    "DistanceCalculator",
    "GeocodeProvider",
    "GoogleMapsGeocoder",
    "MockGeocoder",
    "get_location_service",
    
    # Database & Initialization
    "crud",
    "init_db",
    
    # Routes
    "registration_router",
]
