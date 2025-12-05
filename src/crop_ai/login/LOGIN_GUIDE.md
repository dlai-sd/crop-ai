# Login Service - Comprehensive Guide

## Overview

The Login service provides credential-based authentication with multi-factor authentication (MFA) support, trusted device management, and comprehensive audit logging.

**Key Features:**
- Email or username + password authentication
- Multi-factor authentication (TOTP, SMS, Email OTP)
- Trusted device management
- Complete login history and audit trail
- Password change and reset functionality
- Rate limiting and brute force protection
- Account lockout mechanisms
- Session management

**Module Structure:**
```
login/
├── models.py          - Database models (5 tables)
├── schemas.py         - Pydantic validation schemas
├── crud.py            - Database CRUD operations
├── service.py         - Core business logic (LoginService)
├── routes.py          - FastAPI endpoints (18 routes)
└── __init__.py        - Module exports
```

## Database Schema

### 1. user_login_credentials

Stores login identifiers and MFA settings.

```sql
CREATE TABLE user_login_credentials (
    id INTEGER PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    backup_email VARCHAR(255),
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_method ENUM(totp|sms|email|none),
    mfa_verified BOOLEAN DEFAULT FALSE,
    totp_secret BINARY,  -- Encrypted
    backup_codes BINARY,  -- Encrypted
    preferred_login_method VARCHAR(50),
    allow_insecure_login BOOLEAN DEFAULT FALSE,
    created_at DATETIME,
    updated_at DATETIME,
    last_login_at DATETIME,
    locked_until DATETIME
);
```

**Key Constraints:**
- `user_id` is unique (one credential per user)
- `username` is unique and indexed
- `mfa_enabled` and `mfa_verified` separate concerns (setup vs. active)

### 2. login_history

Audit trail of all login attempts.

```sql
CREATE TABLE login_history (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    status ENUM(success|failed|blocked|mfa_required|mfa_failed),
    method VARCHAR(50),  -- email, username, sso_provider
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type ENUM(web|mobile_ios|mobile_android|desktop|tablet|other),
    device_name VARCHAR(255),
    location_city VARCHAR(100),
    location_country VARCHAR(100),
    location_latitude VARCHAR(50),
    location_longitude VARCHAR(50),
    mfa_used BOOLEAN,
    mfa_method VARCHAR(50),
    failure_reason VARCHAR(255),
    created_at DATETIME
);
```

**Indexes:**
- `(user_id, created_at)` - For user history queries
- `(ip_address, created_at)` - For IP-based security analysis

### 3. login_devices

Registered/trusted devices for faster login.

```sql
CREATE TABLE login_devices (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    device_id VARCHAR(100) UNIQUE NOT NULL,
    device_name VARCHAR(255),
    device_type ENUM(...),
    device_fingerprint VARCHAR(255),
    trust_token VARCHAR(500),
    is_trusted BOOLEAN,
    last_used_at DATETIME,
    expires_at DATETIME,
    created_at DATETIME,
    updated_at DATETIME
);
```

**Unique Constraint:**
- `(user_id, device_id)` - One device record per user device

### 4. mfa_challenges

In-progress MFA verifications.

```sql
CREATE TABLE mfa_challenges (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    challenge_id VARCHAR(100) UNIQUE NOT NULL,
    mfa_method ENUM(totp|sms|email),
    challenge_code BINARY,  -- Encrypted
    attempts INTEGER,
    max_attempts INTEGER,
    verified BOOLEAN,
    created_at DATETIME,
    expires_at DATETIME
);
```

**Expiry:** Challenges expire after 10 minutes by default.

### 5. login_attempt_throttle

Rate limiting and brute force protection.

```sql
CREATE TABLE login_attempt_throttle (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    ip_address VARCHAR(45),
    failed_attempts INTEGER,
    last_attempt_at DATETIME,
    blocked_until DATETIME
);
```

**Unique Constraint:**
- `(user_id, ip_address)` - Track per user and IP

## API Reference

### Authentication Endpoints

#### 1. POST /api/v1/login

Authenticate user with email/username and password.

**Request:**
```json
{
    "email_or_username": "user@example.com",
    "password": "SecurePassword123!",
    "remember_me": true,
    "device_name": "My iPhone"
}
```

**Response (Success - No MFA):**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 900,
    "user_id": 123,
    "email": "user@example.com",
    "role": "farmer",
    "name": "John Doe",
    "device_token": "base64_encoded_device_token"
}
```

**Response (MFA Required):**
```json
{
    "requires_mfa": true,
    "challenge_id": "chal_1234567890abcdef",
    "mfa_method": "totp",
    "expires_in": 600
}
```

**Error Responses:**
- 401: Invalid credentials
- 429: Too many attempts (rate limited)

---

#### 2. POST /api/v1/login/mfa/verify

Verify MFA challenge and complete login.

**Request:**
```json
{
    "challenge_id": "chal_1234567890abcdef",
    "code": "123456"
}
```

**Response:**
```json
{
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "token_type": "bearer",
    "expires_in": 900,
    "user_id": 123,
    "email": "user@example.com",
    "role": "farmer",
    "name": "John Doe"
}
```

**Error Responses:**
- 400: Challenge expired or not found
- 401: Invalid verification code
- 429: Too many verification attempts

---

### MFA Management

#### 3. POST /api/v1/login/mfa/setup

Initiate MFA setup.

**Request (TOTP):**
```json
{
    "mfa_method": "totp"
}
```

**Response:**
```json
{
    "setup_token": "setup_token_xyz",
    "mfa_method": "totp",
    "qr_code": "data:image/png;base64,...",
    "secret": "JBSWY3DPEBLW64TMMQ",
    "backup_codes": ["ABC123", "DEF456", ...]
}
```

**Request (SMS):**
```json
{
    "mfa_method": "sms",
    "phone_number": "+919876543210"
}
```

**Response:**
```json
{
    "setup_token": "setup_token_xyz",
    "mfa_method": "sms",
    "message": "Verification code sent to +91XXXXXXXXXX"
}
```

---

#### 4. POST /api/v1/login/mfa/verify-setup

Verify MFA setup with test code.

**Request:**
```json
{
    "code": "123456"
}
```

**Response:**
```json
{
    "user_id": 123,
    "username": "johndoe",
    "email": "user@example.com",
    "mfa_enabled": true,
    "mfa_method": "totp",
    "preferred_login_method": "email",
    "last_login_at": "2025-12-05T10:30:00Z",
    "created_at": "2025-11-01T08:00:00Z"
}
```

---

#### 5. POST /api/v1/login/mfa/disable

Disable MFA (requires password verification).

**Request:**
```json
{
    "password": "CurrentPassword123!"
}
```

**Response:**
```json
{
    "user_id": 123,
    "username": "johndoe",
    "mfa_enabled": false,
    "mfa_method": "none"
}
```

---

### Password Management

#### 6. POST /api/v1/login/password/change

Change user password.

**Request:**
```json
{
    "current_password": "OldPassword123!",
    "new_password": "NewPassword456!",
    "confirm_password": "NewPassword456!"
}
```

**Password Requirements:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 digit
- At least 1 special character (!@#$%^&*_-+)

**Response:**
```json
{
    "message": "Password changed successfully"
}
```

---

#### 7. POST /api/v1/login/password/reset-request

Request password reset via email.

**Request:**
```json
{
    "email_or_username": "user@example.com"
}
```

**Response:**
```json
{
    "message": "If account exists, password reset email will be sent",
    "reset_token_sent_to": "Check your email"
}
```

**Note:** Response doesn't reveal if account exists (security).

---

#### 8. POST /api/v1/login/password/reset-verify

Verify password reset token and set new password.

**Request:**
```json
{
    "reset_token": "token_from_email_link",
    "new_password": "NewPassword456!",
    "confirm_password": "NewPassword456!"
}
```

**Response:**
```json
{
    "message": "Password reset successfully"
}
```

---

### Device Management

#### 9. POST /api/v1/login/devices/register

Register a device for trusted login.

**Request:**
```json
{
    "device_id": "device_uuid_12345",
    "device_name": "My iPhone 14 Pro",
    "device_type": "mobile_ios"
}
```

**Response:**
```json
{
    "id": 456,
    "device_id": "device_uuid_12345",
    "device_name": "My iPhone 14 Pro",
    "device_type": "mobile_ios",
    "is_trusted": false,
    "last_used_at": null,
    "created_at": "2025-12-05T10:30:00Z"
}
```

---

#### 10. GET /api/v1/login/devices

List user's registered devices.

**Query Parameters:**
- None

**Response:**
```json
{
    "total": 3,
    "devices": [
        {
            "id": 456,
            "device_id": "device_uuid_12345",
            "device_name": "My iPhone 14 Pro",
            "device_type": "mobile_ios",
            "is_trusted": true,
            "last_used_at": "2025-12-05T15:45:00Z",
            "created_at": "2025-12-01T10:30:00Z"
        },
        ...
    ]
}
```

---

#### 11. POST /api/v1/login/devices/{device_id}/trust

Mark device as trusted for easier login.

**Request:**
```json
{
    "trust": true
}
```

**Response:**
```json
{
    "id": 456,
    "device_id": "device_uuid_12345",
    "is_trusted": true,
    ...
}
```

---

#### 12. DELETE /api/v1/login/devices/{device_id}

Remove device from trusted list.

**Response:**
```json
{
    "message": "Device removed successfully"
}
```

---

### Login History & Credentials

#### 13. GET /api/v1/login/history

Get user's login history (paginated).

**Query Parameters:**
- `page`: Page number (1-indexed, default: 1)
- `limit`: Results per page (max 100, default: 50)

**Response:**
```json
{
    "total": 42,
    "page": 1,
    "limit": 50,
    "records": [
        {
            "id": 1001,
            "status": "success",
            "method": "credential",
            "ip_address": "192.168.1.100",
            "device_type": "web",
            "device_name": "Chrome on Windows",
            "location_city": "Bangalore",
            "location_country": "India",
            "mfa_used": false,
            "created_at": "2025-12-05T10:30:00Z"
        },
        ...
    ]
}
```

**Status Values:**
- `success` - Successful login
- `failed` - Invalid credentials
- `blocked` - Rate limited
- `mfa_required` - MFA verification needed
- `mfa_failed` - MFA verification failed

---

#### 14. GET /api/v1/login/credentials

Get current login credentials and settings.

**Response:**
```json
{
    "user_id": 123,
    "username": "johndoe",
    "email": "user@example.com",
    "backup_email": null,
    "mfa_enabled": true,
    "mfa_method": "totp",
    "preferred_login_method": "email",
    "last_login_at": "2025-12-05T15:45:00Z",
    "created_at": "2025-11-01T08:00:00Z"
}
```

---

## Security Features

### 1. Rate Limiting

**Implementation:**
- Max 5 failed login attempts per IP/user
- 30-minute lockout after threshold
- Tracked in `login_attempt_throttle` table

**Configuration:**
```python
LOGIN_ATTEMPT_LIMIT = 5
LOGIN_LOCKOUT_MINUTES = 30
```

### 2. Brute Force Protection

**Account Lockout:**
- Automatic lockout after 5 failed attempts
- Lockout duration: 30 minutes (configurable)
- Can be manually reset by admin

**Throttle Reset:**
- Successful login resets throttle counter
- Prevents legitimate users from permanent lockout

### 3. Multi-Factor Authentication

**Supported Methods:**
1. **TOTP (Time-based OTP)**
   - Compatible with Google Authenticator, Authy
   - 30-second window tolerance
   - Recovery codes for account access

2. **SMS OTP**
   - 6-digit verification code
   - 10-minute expiry
   - Requires phone number

3. **Email OTP**
   - 6-digit or token-based
   - 10-minute expiry
   - Sent to registered email

**Configuration:**
```python
MFA_CHALLENGE_EXPIRY_MINUTES = 10
MFA_MAX_ATTEMPTS = 5
```

### 4. Password Security

**Hashing:**
- Argon2 algorithm
- Secure salt generation
- Constant-time comparison

**Requirements:**
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 digit
- At least 1 special character

### 5. Audit Logging

**Tracked in login_history:**
- All login attempts (success/failure)
- IP address and user agent
- Device type and name
- Geolocation (if available)
- MFA usage
- Failure reasons

**Usage:**
```python
# Get login history
total, records = await crud.get_user_login_history(db, user_id, limit=50)

for record in records:
    print(f"{record.status} from {record.ip_address} at {record.created_at}")
```

### 6. Session Management

**Token Lifecycle:**
- Access Token: 15 minutes (short-lived)
- Refresh Token: 7 days
- Device Token: 30 days (optional)

**Token Revocation:**
- Logout adds token to blacklist
- Can be integrated with Redis for scalability

### 7. Device Fingerprinting

**Components:**
- Device UUID
- User agent
- Device type
- Screen resolution (client-side)
- Browser/app version

**Usage:**
```python
device = await crud.register_device(
    db,
    user_id=123,
    device_id="device_uuid",
    device_fingerprint="fingerprint_hash"
)
```

## Usage Examples

### Basic Login Flow

```python
from crop_ai.login import LoginService
from crop_ai.database import get_db

# Get database session
db = next(get_db())

# Create service
service = LoginService(db)

# Perform login
success, response = await service.login(
    email_or_username="user@example.com",
    password="SecurePassword123!",
    ip_address="192.168.1.100",
    user_agent="Mozilla/5.0...",
    device_name="My Device"
)

if success:
    if response.get("requires_mfa"):
        # Handle MFA challenge
        challenge_id = response["challenge_id"]
        print(f"MFA required: {response['mfa_method']}")
    else:
        # Login successful
        access_token = response["access_token"]
        print(f"Logged in as {response['name']}")
else:
    print(f"Login failed: {response['message']}")
```

### MFA Setup

```python
# Setup TOTP
mfa_response = await service.setup_mfa(
    user_id=123,
    mfa_method="totp"
)

qr_code = mfa_response["qr_code"]
secret = mfa_response["secret"]
backup_codes = mfa_response["backup_codes"]

# Display QR code to user, have them verify with test code
verified = await service.verify_mfa_setup(
    user_id=123,
    mfa_method="totp",
    code="123456",  # From authenticator app
    totp_secret=secret,
    backup_codes=backup_codes
)
```

### Password Change

```python
success, message = await service.change_password(
    user_id=123,
    current_password="OldPassword123!",
    new_password="NewPassword456!"
)

if success:
    print("Password changed successfully")
else:
    print(f"Error: {message}")
```

### Device Management

```python
from crop_ai.login import crud

# Register device
device = await crud.register_device(
    db,
    user_id=123,
    device_id="device_uuid",
    device_name="My iPhone",
    device_type="mobile_ios"
)

# List devices
devices = await crud.get_user_devices(db, user_id=123)
for device in devices:
    print(f"{device.device_name}: {device.device_type}")

# Trust device
await crud.set_device_trusted(db, user_id=123, device_id="device_uuid", trusted=True)

# Remove device
await crud.remove_device(db, user_id=123, device_id="device_uuid")
```

### Login History Analysis

```python
# Get user's login history
total, records = await crud.get_user_login_history(db, user_id=123, limit=10)

print(f"Total login attempts: {total}")
for record in records:
    print(f"{record.created_at}: {record.status} from {record.ip_address}")

# Get failed logins in last 24 hours
failed_count = await crud.count_failed_logins(db, user_id=123, hours=24)
print(f"Failed attempts in 24h: {failed_count}")

# Check if account is locked
is_locked = await crud.is_account_locked(db, user_id=123)
if is_locked:
    print("Account is temporarily locked")
```

## Configuration

### Environment Variables

```bash
# Application
APP_NAME=Crop-AI

# Database
DATABASE_URL=postgresql://user:password@localhost/crop_ai

# Authentication
AUTH_SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# MFA
MFA_TOTP_ISSUER=Crop-AI
MFA_CHALLENGE_EXPIRY_MINUTES=10
MFA_MAX_ATTEMPTS=5

# Rate Limiting
LOGIN_ATTEMPT_LIMIT=5
LOGIN_LOCKOUT_MINUTES=30

# Email (for password reset)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# SMS (for SMS OTP)
TWILIO_ACCOUNT_SID=your-account-sid
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
```

### Database Initialization

```python
from crop_ai.login.models import Base
from crop_ai.database import engine

# Create tables
Base.metadata.create_all(bind=engine)
```

## Testing

### Unit Tests

```python
import pytest
from crop_ai.login import LoginService, crud
from sqlalchemy.orm import Session

@pytest.fixture
def db():
    # Setup test database
    pass

@pytest.mark.asyncio
async def test_login_success(db: Session):
    service = LoginService(db)
    success, response = await service.login(
        email_or_username="user@example.com",
        password="TestPassword123!",
        ip_address="127.0.0.1",
        user_agent="test-agent"
    )
    assert success
    assert "access_token" in response

@pytest.mark.asyncio
async def test_login_invalid_credentials(db: Session):
    service = LoginService(db)
    success, response = await service.login(
        email_or_username="unknown@example.com",
        password="WrongPassword",
        ip_address="127.0.0.1",
        user_agent="test-agent"
    )
    assert not success
    assert response["error"] == "invalid_credentials"

@pytest.mark.asyncio
async def test_rate_limiting(db: Session):
    service = LoginService(db)
    
    # Simulate 5 failed attempts
    for i in range(5):
        await service.login(
            email_or_username="user@example.com",
            password="WrongPassword",
            ip_address="192.168.1.100",
            user_agent="test-agent"
        )
    
    # 6th attempt should be blocked
    success, response = await service.login(
        email_or_username="user@example.com",
        password="TestPassword123!",
        ip_address="192.168.1.100",
        user_agent="test-agent"
    )
    assert not success
    assert response["error"] == "account_locked"
```

## Troubleshooting

### Common Issues

**1. "Account Locked" Error**
- **Cause:** Too many failed login attempts
- **Solution:** Wait 30 minutes or contact support for manual unlock

**2. MFA Code Expires Quickly**
- **Cause:** Time synchronization issue
- **Solution:** Sync device clock with NTP server

**3. TOTP QR Code Not Displaying**
- **Cause:** Image encoding issue
- **Solution:** Check Base64 encoding and MIME type

**4. SMS/Email Not Received**
- **Cause:** Provider API issue or invalid phone/email
- **Solution:** Check provider credentials and contact logs

**5. "Invalid Device" on Login**
- **Cause:** Device fingerprint mismatch
- **Solution:** Register device again or use new device

## Performance Optimization

### Caching

```python
# Cache login attempts per IP
@lru_cache(maxsize=1000)
def get_throttle_record(ip_address: str):
    return crud.get_throttle_record(db, ip_address)

# Cache user credentials (15 minutes)
cache.set(f"cred:{user_id}", credential, timeout=900)
```

### Horizontal Scaling

1. **Session Storage:** Use Redis instead of in-memory
2. **Rate Limiting:** Implement distributed throttling
3. **Audit Logging:** Use async queue (Celery)
4. **Geolocation:** Cache IP → Location mapping

### Database Optimization

1. **Indexes:** Already created on frequently queried columns
2. **Partitioning:** Partition login_history by date
3. **Archiving:** Archive old records monthly
4. **Cleanup:** Run cleanup tasks to remove expired challenges

## License

This module is part of crop-ai and follows the same license.
