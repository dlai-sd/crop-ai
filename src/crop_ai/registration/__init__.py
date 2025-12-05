"""
Registration microservice module.

Provides:
- User registration for multiple roles (Farmer, Partner, Customer)
- Multi-provider SSO (Google, Microsoft, Facebook)
- Email and SMS verification
- Registration analytics and tracking
"""

from crop_ai.registration.models import (
    UserProfile,
    FarmerProfile,
    PartnerProfile,
    CustomerProfile,
    SSOAccount,
    VerificationToken,
    RegistrationMetadata,
    UserRole,
    RegistrationStatus,
    FarmType,
    PartnerBusinessType,
)

from crop_ai.registration.schemas import (
    UserRoleSchema,
    RegistrationStatusSchema,
    FarmTypeSchema,
    PartnerBusinessTypeSchema,
    RegistrationStartRequest,
    RegistrationStartResponse,
    VerifyTokenRequest,
    VerifyTokenResponse,
    FarmerRegistrationRequest,
    FarmerProfileResponse,
    PartnerRegistrationRequest,
    PartnerProfileResponse,
    CustomerRegistrationRequest,
    CustomerProfileResponse,
    RegistrationCompleteResponse,
    RegistrationErrorResponse,
    RegistrationStatusResponse,
    SSOLoginRequest,
    SSOCallbackResponse,
)

from crop_ai.registration.sso import (
    GoogleOAuthProvider,
    MicrosoftOAuthProvider,
    FacebookOAuthProvider,
    SSOProviderManager,
    SSOUserInfo,
    SSOTokenResponse,
    get_sso_manager,
)

from crop_ai.registration.verification import (
    VerificationService,
    VerificationTokenGenerator,
    VerificationConfig,
    SMSProvider,
    TwilioSMSProvider,
    AmazonSNSSMSProvider,
    EmailProvider,
    SMTPEmailProvider,
    MockEmailProvider,
    get_verification_service,
)

from crop_ai.registration.location import (
    LocationService,
    LocationValidator,
    LocationData,
    GPSCoordinates,
    Address,
    DistanceCalculator,
    GeocodeProvider,
    GoogleMapsGeocoder,
    MockGeocoder,
    get_location_service,
)

from crop_ai.registration import crud

from crop_ai.registration import init_db

from crop_ai.registration.routes import router as registration_router


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
