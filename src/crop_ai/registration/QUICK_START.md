"""
REGISTRATION SERVICE - QUICK START GUIDE

This guide helps you quickly understand and use the registration service.
============================================================================
"""

# Quick API Overview
# ==================

## 1. Start Registration
POST /api/v1/register/start
{
  "role": "farmer",
  "registration_method": "email",
  "email": "farmer@example.com"
}

Response:
{
  "registration_id": "abc123def456",
  "role": "farmer",
  "registration_method": "email",
  "verification_required": "email",
  "expires_at": "2025-12-06T12:00:00"
}

## 2. Verify Email/SMS
POST /api/v1/register/verify-token
{
  "registration_id": "abc123def456",
  "token": "email_token_or_6digit_otp",
  "token_type": "email"
}

Response:
{
  "verified": true,
  "registration_id": "abc123def456",
  "next_step": "complete_profile"
}

## 3. Complete Farmer Registration
POST /api/v1/register/farmer/complete
{
  "registration_id": "abc123def456",
  "name": "John Farmer",
  "email": "farmer@example.com",
  "mobile": "+919876543210",
  "country_code": "+91",
  "address": {
    "address": "123 Farm Lane",
    "city": "Bangalore",
    "state": "Karnataka",
    "postal_code": "560001",
    "country": "India"
  },
  "location": {
    "latitude": 12.9716,
    "longitude": 77.5946,
    "location_accuracy": 10,
    "location_source": "gps"
  },
  "farm_data": {
    "farm_size": 5.5,
    "farm_size_unit": "acres",
    "primary_crop": "Rice",
    "farm_type": "commercial",
    "experience_level": 10,
    "irrigation_type": "drip"
  },
  "preferences": {
    "notification_email": true,
    "notification_sms": true,
    "language_preference": "en"
  },
  "accept_tos": true,
  "accept_privacy": true
}

Response:
{
  "success": true,
  "user_id": 1,
  "role": "farmer",
  "email": "farmer@example.com",
  "mobile": "+919876543210",
  "profile_type": "farmer",
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "refresh_token_here",
  "next_steps": ["complete_kyc", "setup_alerts"]
}


# Database Models
# ===============

## UserProfile (Base for all roles)
  - id: int (PK)
  - role: UserRole (FARMER | PARTNER | CUSTOMER)
  - status: RegistrationStatus (PENDING → EMAIL_VERIFIED → MOBILE_VERIFIED → COMPLETED)
  - name: str
  - email: str (unique)
  - mobile: str (unique)
  - address, city, state, postal_code, country: str
  - latitude, longitude: float
  - location_accuracy: float (meters)
  - language_preference: str
  - notification_email, notification_sms, notification_whatsapp: bool
  - created_at, updated_at: datetime
  - mobile_verified_at, email_verified_at: datetime

## FarmerProfile (Role-specific)
  - user_id: int (FK → UserProfile)
  - farm_size: float
  - farm_size_unit: str (acres | hectares)
  - primary_crop: str (indexed)
  - farm_type: str (commercial | subsistence | organic | mixed)
  - experience_level: int (years)
  - irrigation_type: str
  - secondary_crops: str (comma-separated)
  - adhaar_token: str (future)
  - adhaar_status: str (pending | verified | rejected)
  - verified: bool
  - verified_at: datetime

## PartnerProfile (Role-specific)
  - user_id: int (FK → UserProfile)
  - company_name: str (unique)
  - business_type: str (indexed)
  - registration_number: str (unique)
  - tax_id: str (unique, GST in India)
  - contact_person: str
  - service_area: str (comma-separated)
  - website: str
  - certifications: str (comma-separated)
  - verified: bool
  - registration_verified: bool
  - tax_verified: bool
  - verified_at: datetime

## CustomerProfile (Role-specific)
  - user_id: int (FK → UserProfile)
  - interests: str (comma-separated)
  - use_case: str
  - preferred_contact: str (email | sms | whatsapp | phone)
  - organization: str
  - budget_range: str (low | medium | high)
  - profile_photo_url: str
  - referral_code: str (unique)
  - referred_by: str

## SSOAccount (OAuth provider linking)
  - id: int (PK)
  - user_id: int (FK → UserProfile)
  - provider: str (google | microsoft | facebook)
  - provider_user_id: str (unique per provider)
  - email: str
  - name: str
  - profile_picture_url: str
  - access_token: str (encrypted)
  - refresh_token: str (encrypted)
  - token_expiry: datetime
  - linked_at: datetime
  - last_used: datetime

## VerificationToken (Email/SMS verification)
  - id: int (PK)
  - user_id: int (FK → UserProfile)
  - token_type: str (email | sms)
  - token: str (verification token or OTP)
  - expires_at: datetime
  - verified_at: datetime
  - attempts: int (0-5)
  - max_attempts: int (5)
  - channel: str (email address or phone number)
  - created_at: datetime

## RegistrationMetadata (Analytics & tracking)
  - id: int (PK)
  - user_id: int (FK → UserProfile)
  - registration_method: str (email | mobile | sso_google | sso_microsoft | sso_facebook)
  - referrer: str (campaign source)
  - device_type: str (mobile | desktop | tablet)
  - device_os: str (Android | iOS | Windows | macOS | Linux)
  - browser: str (Chrome | Safari | Firefox | Edge)
  - ip_address: str
  - country: str (from geoIP)
  - form_completion_time: int (seconds)
  - form_abandonment_stage: str (if incomplete)
  - language_code: str
  - created_at: datetime


# SSO Provider Setup
# ==================

## Google OAuth
1. Go to: https://console.cloud.google.com
2. Create new project
3. Enable OAuth 2.0
4. Create OAuth 2.0 credentials (Web application)
5. Set authorized redirect URIs: http://localhost:8000/auth/sso/google/callback
6. Get Client ID and Client Secret
7. Set environment variables:
   - GOOGLE_CLIENT_ID=your_client_id
   - GOOGLE_CLIENT_SECRET=your_client_secret
   - GOOGLE_REDIRECT_URI=http://localhost:8000/auth/sso/google/callback

## Microsoft OAuth
1. Go to: https://portal.azure.com
2. Register new application
3. Create Web API application registration
4. Add redirect URI: http://localhost:8000/auth/sso/microsoft/callback
5. Create client secret
6. Get Application (client) ID and secret
7. Set environment variables:
   - MICROSOFT_CLIENT_ID=your_client_id
   - MICROSOFT_CLIENT_SECRET=your_client_secret
   - MICROSOFT_REDIRECT_URI=http://localhost:8000/auth/sso/microsoft/callback

## Facebook OAuth
1. Go to: https://developers.facebook.com
2. Create new app
3. Add Facebook Login product
4. Configure OAuth Redirect URIs: http://localhost:8000/auth/sso/facebook/callback
5. Get App ID and App Secret
6. Set environment variables:
   - FACEBOOK_CLIENT_ID=your_app_id
   - FACEBOOK_CLIENT_SECRET=your_app_secret
   - FACEBOOK_REDIRECT_URI=http://localhost:8000/auth/sso/facebook/callback


# Email Configuration
# ====================

## Production (SMTP)
Set environment variables:
  - SMTP_SERVER=smtp.gmail.com (or your provider)
  - SMTP_PORT=587
  - SENDER_EMAIL=your_email@example.com
  - SENDER_PASSWORD=your_app_password
  - SENDER_NAME=CropAI
  - APP_URL=https://yourapp.com

## Development (Mock)
Leave SMTP_SERVER unset. Emails will be printed to console.


# SMS Configuration
# ==================

## Production (Twilio)
Set environment variables:
  - TWILIO_ACCOUNT_SID=your_account_sid
  - TWILIO_AUTH_TOKEN=your_auth_token
  - TWILIO_PHONE_NUMBER=+1234567890 (your Twilio number)

## Production (Amazon SNS)
Set environment variables:
  - AWS_REGION=us-east-1 (or your region)
  - Uses AWS credentials from environment or IAM role

## Development (Mock)
Leave SMS provider env vars unset. OTPs will be printed to console.


# Python Code Examples
# ====================

## Using the Registration Service

from crop_ai.registration import (
    get_user_profile,
    get_farmer_profile,
    create_user_profile,
    create_farmer_profile,
    UserRole,
    RegistrationStatus,
)
from crop_ai.core.database import SessionLocal

db = SessionLocal()

# Create user profile
user = create_user_profile(
    db,
    role=UserRole.FARMER,
    name="John Farmer",
    email="farmer@example.com",
    mobile="+919876543210",
    address="123 Farm Lane",
    city="Bangalore",
    state="Karnataka",
    postal_code="560001",
    country="India",
    latitude=12.9716,
    longitude=77.5946,
)

# Create farmer profile
farmer = create_farmer_profile(
    db,
    user_id=user.id,
    farm_size=5.5,
    farm_size_unit="acres",
    primary_crop="Rice",
    farm_type="commercial",
    experience_level=10,
)

# Retrieve profile
retrieved = get_farmer_profile(db, user.id)
print(f"Farmer: {retrieved.primary_crop}, Size: {retrieved.farm_size} acres")


## Using SSO Manager

from crop_ai.registration import get_sso_manager

sso_manager = get_sso_manager()

# Get authorization URL
url, state = sso_manager.get_authorization_url("google", registration_id="abc123")
print(f"Redirect user to: {url}")

# Handle OAuth callback
try:
    user_info, token_response = await sso_manager.handle_callback(
        provider_name="google",
        code=auth_code,
        state=state,
    )
    print(f"User email: {user_info.email}")
    print(f"Access token: {token_response.access_token}")
except Exception as e:
    print(f"Error: {e}")


## Using Verification Service

from crop_ai.registration import get_verification_service

verification = get_verification_service()

# Send email verification
try:
    token, expires_at = await verification.send_email_verification(
        email="user@example.com",
        name="User Name",
        registration_id="abc123",
    )
    print(f"Verification email sent. Token expires at: {expires_at}")
except Exception as e:
    print(f"Error sending email: {e}")

# Send SMS OTP
try:
    otp, expires_at = await verification.send_sms_otp(
        phone_number="+919876543210",
    )
    print(f"OTP sent. Expires at: {expires_at}")
except Exception as e:
    print(f"Error sending SMS: {e}")

# Verify token
is_valid, error = verification.verify_token(
    provided_token=user_provided_token,
    stored_token=stored_token,
    expires_at=token_expiry,
    attempts=current_attempts,
)
if is_valid:
    print("Token verified successfully")
else:
    print(f"Token verification failed: {error}")


# Production Checklist
# ====================

Before deploying to production:

[ ] Database
  [ ] Run migrations (Alembic)
  [ ] Create indexes
  [ ] Set up backups
  [ ] Configure connection pooling

[ ] Environment Variables
  [ ] Configure SMTP (email provider)
  [ ] Configure SMS (Twilio or SNS)
  [ ] Configure SSO (Google, Microsoft, Facebook)
  [ ] Set APP_URL
  [ ] Set secure JWT_SECRET_KEY
  [ ] Set database URL

[ ] Security
  [ ] Enable HTTPS/TLS
  [ ] Set strong JWT secrets
  [ ] Implement rate limiting
  [ ] Enable CORS properly
  [ ] Validate all inputs

[ ] Scaling
  [ ] Set up Redis (session storage)
  [ ] Configure connection pooling
  [ ] Set up load balancer
  [ ] Monitor database queries

[ ] Monitoring
  [ ] Set up logging
  [ ] Configure alerts
  [ ] Monitor registration metrics
  [ ] Track conversion rates

[ ] Testing
  [ ] Run unit tests
  [ ] Run integration tests
  [ ] Load testing (seasonal peaks)
  [ ] Security testing


# Support & Troubleshooting
# =========================

## Email not sending
- Check SMTP credentials
- Verify SMTP_SERVER and SMTP_PORT
- Check email provider settings (Gmail requires app password)
- Enable "Less secure app access" if using Gmail

## SMS not sending
- Check Twilio/SNS credentials
- Verify phone number format (E.164: +country_code number)
- Check Twilio phone number is verified
- Check SMS balance/quota

## SSO not working
- Check OAuth credentials (client_id, client_secret)
- Verify redirect URI matches provider configuration
- Check state token validation
- Verify HTTPS for production (OAuth requires HTTPS)

## Registration session expired
- Increase session timeout in VerificationConfig
- Implement Redis for distributed sessions
- Check database for orphaned sessions

## Database errors
- Verify database connection
- Check unique constraint violations (email, mobile, tax_id)
- Run migrations
- Check connection pooling settings
