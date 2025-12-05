# Authentication & Authorization Implementation

**Status:** 🔴 PRIORITY 1 - Before MVP Launch  
**Decision Date:** December 5, 2025  
**Last Updated:** December 5, 2025

---

## Executive Summary

We need a **secure, scalable authentication & authorization system** for Crop AI. This document recommends **JWT (JSON Web Tokens) + PostgreSQL for MVP**, with a clear migration path to **OAuth2 + OIDC for enterprise**.

### Decision Matrix

| Criterion | JWT (MVP) | OAuth2 | OIDC | API Key |
|-----------|-----------|--------|------|---------|
| MVP Ready | ✅ (5h) | ⚠️ (40h) | ⚠️ (50h) | ✅ (2h) |
| Security | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Scalability | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Team Complexity | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Enterprise Ready | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| Cost (monthly) | $0 | $0 | $0 | $0 |

### Recommendation

**MVP (Months 1-3):** JWT + PostgreSQL
- Fast implementation (5 hours)
- Production-ready security
- Built on FastAPI's native capabilities
- Team immediately productive

**Growth (Months 3-6):** Migrate to OAuth2 + OIDC
- Enterprise customers demand it
- Better multi-device handling
- Easier integration with third-party apps
- Migration path is straightforward

---

## Problem Statement

The Crop AI platform needs to:

1. **Authenticate users** - Verify who they are (username/password, API keys)
2. **Authorize requests** - Verify what they can do (roles, permissions)
3. **Protect API endpoints** - Require valid tokens for access
4. **Handle token refresh** - Prevent frequent re-login
5. **Support multiple clients** - Web (Angular SPA), mobile, desktop, integrations
6. **Scale to enterprise** - Multiple organizations, delegated access, audit trails

---

## Option Analysis

### Option 1: JWT + PostgreSQL (RECOMMENDED FOR MVP)

**How it works:**
```
1. User submits username + password
2. Server validates against PostgreSQL
3. Server issues JWT token (expires in 15 min)
4. Client stores JWT in localStorage
5. Client sends JWT in Authorization header for each request
6. Server validates JWT signature
7. If JWT expires, client uses refresh token to get new one
```

**Pros:**
- ✅ Fast to implement (5 hours)
- ✅ Stateless (servers don't need to share session state)
- ✅ Perfect for FastAPI + async/await
- ✅ Works with SPA (Angular stores in localStorage)
- ✅ Works with mobile (no cookies needed)
- ✅ Works with AI/ML workflows (API calls, scripts)
- ✅ No external services required
- ✅ Can be deployed immediately
- ✅ Scales to 10K+ concurrent users easily
- ✅ Clear upgrade path to OAuth2

**Cons:**
- ❌ Logout doesn't invalidate tokens (stored client-side)
  - Workaround: Short token lifetime (15 min) + refresh token
- ❌ Token revocation requires service-side token blacklist
  - Workaround: Implement optional Redis blacklist for critical operations
- ❌ No multi-device awareness out-of-the-box
  - Workaround: Add manual device tracking

**Security Considerations:**
- Tokens are signed (HMAC-SHA256) but NOT encrypted
- Anyone can read the payload (don't put secrets in JWT)
- Use HTTPS only (tokens in Authorization header)
- Short expiration time (15 minutes)
- Refresh token stored separately (httpOnly cookie or localStorage)

**Implementation Details:**

**Tokens:**
```
Access Token (JWT):
- Expires: 15 minutes
- Content: user_id, email, roles, permissions
- Signed: HMAC-SHA256 with SECRET_KEY
- Storage: localStorage (SPA)

Refresh Token:
- Expires: 7 days
- Content: user_id, token_version
- Signed: HMAC-SHA256 with REFRESH_SECRET_KEY
- Storage: httpOnly secure cookie (best) or localStorage (SPA-friendly)
```

**Database Schema (PostgreSQL):**
```sql
-- Users table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,  -- Argon2 hash
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Roles table
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT
);

-- User roles (many-to-many)
CREATE TABLE user_roles (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
  UNIQUE(user_id, role_id)
);

-- Permissions table
CREATE TABLE permissions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT
);

-- Role permissions (many-to-many)
CREATE TABLE role_permissions (
  id SERIAL PRIMARY KEY,
  role_id INTEGER REFERENCES roles(id) ON DELETE CASCADE,
  permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
  UNIQUE(role_id, permission_id)
);

-- Token blacklist (for logout, optional but recommended)
CREATE TABLE token_blacklist (
  id SERIAL PRIMARY KEY,
  token_jti VARCHAR(255) UNIQUE NOT NULL,  -- JWT ID claim
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Session tracking (optional, for device management)
CREATE TABLE sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  device_name VARCHAR(255),
  device_type VARCHAR(50),  -- web, mobile, api
  ip_address VARCHAR(45),
  user_agent TEXT,
  last_activity TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  expired_at TIMESTAMP
);
```

**FastAPI Implementation:**

```python
# auth/schemas.py
from pydantic import BaseModel, EmailStr
from typing import List, Optional

class TokenRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    expires_in: int = 900  # 15 minutes

class UserResponse(BaseModel):
    id: int
    email: str
    username: str
    roles: List[str]
    permissions: List[str]

# auth/utils.py
from datetime import datetime, timedelta
from typing import Optional
import jwt
from passlib.context import CryptContext

SECRET_KEY = "your-secret-key-change-in-production"
REFRESH_SECRET_KEY = "your-refresh-secret-key"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 7

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(
    user_id: int,
    email: str,
    roles: List[str],
    permissions: List[str],
    expires_delta: Optional[timedelta] = None
) -> str:
    if expires_delta is None:
        expires_delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    expire = datetime.utcnow() + expires_delta
    to_encode = {
        "sub": str(user_id),
        "email": email,
        "roles": roles,
        "permissions": permissions,
        "exp": expire,
        "iat": datetime.utcnow(),
        "jti": uuid4().hex  # JWT ID for blacklist
    }
    
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(user_id: int) -> str:
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode = {
        "sub": str(user_id),
        "exp": expire,
        "type": "refresh",
        "jti": uuid4().hex
    }
    
    encoded_jwt = jwt.encode(to_encode, REFRESH_SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# auth/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthCredentials

security = HTTPBearer()

async def get_current_user(credentials: HTTPAuthCredentials = Depends(security)):
    token = credentials.credentials
    payload = decode_token(token)
    user_id = int(payload.get("sub"))
    
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    return {
        "user_id": user_id,
        "email": payload.get("email"),
        "roles": payload.get("roles", []),
        "permissions": payload.get("permissions", [])
    }

async def require_permission(permission: str):
    async def check_permission(current_user: dict = Depends(get_current_user)):
        if permission not in current_user.get("permissions", []):
            raise HTTPException(
                status_code=403,
                detail=f"Permission '{permission}' required"
            )
        return current_user
    
    return check_permission

# auth/routes.py
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from . import schemas, utils
from ..database import get_db
from ..models import User

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/login", response_model=schemas.TokenResponse)
async def login(
    request: schemas.TokenRequest,
    db: Session = Depends(get_db)
):
    # Find user
    user = db.query(User).filter(User.email == request.email).first()
    
    if not user or not utils.verify_password(request.password, user.password_hash):
        raise HTTPException(
            status_code=401,
            detail="Invalid email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="User account is disabled"
        )
    
    # Get user roles and permissions
    roles = [role.name for role in user.roles]
    permissions = []
    for role in user.roles:
        permissions.extend([perm.name for perm in role.permissions])
    
    # Create tokens
    access_token = utils.create_access_token(
        user_id=user.id,
        email=user.email,
        roles=roles,
        permissions=list(set(permissions))
    )
    
    refresh_token = utils.create_refresh_token(user.id)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": utils.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@router.post("/refresh", response_model=schemas.TokenResponse)
async def refresh_token(
    request: schemas.RefreshTokenRequest,
    db: Session = Depends(get_db)
):
    try:
        payload = jwt.decode(
            request.refresh_token,
            utils.REFRESH_SECRET_KEY,
            algorithms=[utils.ALGORITHM]
        )
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Refresh token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    
    user_id = int(payload.get("sub"))
    user = db.query(User).filter(User.id == user_id).first()
    
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User not found or inactive")
    
    # Get roles and permissions
    roles = [role.name for role in user.roles]
    permissions = []
    for role in user.roles:
        permissions.extend([perm.name for perm in role.permissions])
    
    # Create new access token
    access_token = utils.create_access_token(
        user_id=user.id,
        email=user.email,
        roles=roles,
        permissions=list(set(permissions))
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "expires_in": utils.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    }

@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    # Optional: Add token to blacklist
    # This is only needed for immediate logout (prevent re-use)
    # With short token lifetime (15 min), this is less critical
    return {"message": "Logged out successfully"}

@router.get("/me", response_model=schemas.UserResponse)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == current_user["user_id"]).first()
    return {
        "id": user.id,
        "email": user.email,
        "username": user.username,
        "roles": [role.name for role in user.roles],
        "permissions": current_user.get("permissions", [])
    }
```

**Usage in API Endpoints:**

```python
# crops/routes.py
from fastapi import APIRouter, Depends
from ..auth.dependencies import get_current_user, require_permission

router = APIRouter(prefix="/crops", tags=["crops"])

@router.get("/")
async def list_crops(current_user: dict = Depends(get_current_user)):
    # User must be authenticated
    return {"crops": []}

@router.post("/")
async def create_crop(
    crop: CropCreate,
    current_user: dict = Depends(require_permission("crops:create"))
):
    # User must have "crops:create" permission
    return {"crop_id": 1}

@router.delete("/{crop_id}")
async def delete_crop(
    crop_id: int,
    current_user: dict = Depends(require_permission("crops:delete"))
):
    # User must have "crops:delete" permission
    return {"message": "Deleted"}
```

**Cost:**
- Implementation: 5 hours (included in sprint)
- Infrastructure: $0 (PostgreSQL already exists, Redis optional for blacklist)
- Monthly operational: $0

---

### Option 2: OAuth2 + OIDC (Enterprise Ready)

**How it works:**
```
1. User clicks "Login with Microsoft/Google/Azure AD"
2. Browser redirected to provider
3. User authenticates with provider
4. Provider redirects back with authorization code
5. Server exchanges code for ID token + access token
6. Server validates tokens with provider's public key
7. Server creates session
```

**Pros:**
- ✅ Enterprise-standard (all Fortune 500 companies use this)
- ✅ No password management (delegated to provider)
- ✅ Multi-factor authentication (if provider supports)
- ✅ Device management built-in
- ✅ Audit trails (provider logs everything)
- ✅ Works across multiple organizations
- ✅ OpenID Connect for identity verification

**Cons:**
- ❌ 40+ hours to implement correctly
- ❌ Complex (authorization flows, token validation, refresh logic)
- ❌ Requires external service (Azure AD, Okta, Auth0, etc.)
- ❌ Additional costs ($100-500/month for managed service)
- ❌ Need to be careful with CORS, state validation, PKCE
- ❌ Not needed for MVP (customers don't demand it yet)

**When to use:**
- Enterprise customers require SSO
- Multi-tenant SaaS environment
- Integration with corporate identity systems
- Regulatory compliance (audit trails)

**Cost:**
- Implementation: 40+ hours
- Infrastructure: $0-500/month (if using managed provider like Auth0)
- Delay to MVP: 2-3 weeks

---

### Option 3: API Keys (Simple, Limited)

**How it works:**
```
1. User generates API key in settings
2. API key stored in PostgreSQL (hashed)
3. Client includes key in X-API-Key header
4. Server validates key against database
5. No expiration (long-lived)
```

**Pros:**
- ✅ Super simple to implement (2 hours)
- ✅ Perfect for machine-to-machine communication
- ✅ Works for CI/CD pipelines, integrations
- ✅ No browser UI needed

**Cons:**
- ❌ No automatic expiration (security risk)
- ❌ Hard to revoke retroactively
- ❌ Single secret for all requests (no multi-device awareness)
- ❌ No built-in token refresh
- ❌ Not suitable for user-facing app

**When to use:**
- Only for service-to-service communication
- Combined with JWT for user authentication

**Cost:**
- Implementation: 2 hours
- Infrastructure: $0

---

## Recommended Implementation Plan

### Phase 1: MVP JWT Implementation (Week 1)

**Effort:** 5 hours  
**Team:** 1 backend developer  
**Deliverables:**

```
Day 1 (2 hours):
├─ Create auth module structure
├─ Implement password hashing (Argon2)
├─ Write JWT token creation/validation utilities
└─ Create SQLAlchemy models (User, Role, Permission)

Day 2 (2 hours):
├─ Implement login endpoint
├─ Implement token refresh endpoint
├─ Add authentication dependency
├─ Add permission checking decorator

Day 3 (1 hour):
├─ Integration tests for auth flow
├─ Documentation
└─ Deploy to production
```

**Testing Checklist:**

```python
# test_auth.py
def test_login_success():
    # User logs in, receives JWT token
    pass

def test_login_invalid_password():
    # Invalid password returns 401
    pass

def test_login_nonexistent_user():
    # Non-existent user returns 401
    pass

def test_protected_endpoint_with_token():
    # Valid token allows access
    pass

def test_protected_endpoint_without_token():
    # Missing token returns 401
    pass

def test_protected_endpoint_with_expired_token():
    # Expired token returns 401
    pass

def test_refresh_token():
    # Can get new access token
    pass

def test_permission_check():
    # User without permission returns 403
    pass

def test_role_based_access():
    # Only admin role can perform admin actions
    pass
```

### Phase 2: Role-Based Access Control (RBAC) - Week 1-2

**Effort:** 3 hours  
**Deliverables:**

```
Predefined roles:
├─ ADMIN: All permissions
├─ MANAGER: Can approve analyses, manage team
├─ ANALYST: Can run analyses, view results
└─ VIEWER: Read-only access

Permissions:
├─ crops:create, crops:read, crops:update, crops:delete
├─ analyses:create, analyses:read, analyses:update, analyses:delete
├─ users:manage
├─ settings:manage
└─ reports:generate
```

**Database Setup:**

```python
# Initialize roles and permissions
from app.models import Role, Permission, db

def init_auth_data():
    # Create permissions
    permissions = [
        Permission(name="crops:create"),
        Permission(name="crops:read"),
        Permission(name="crops:update"),
        Permission(name="crops:delete"),
        Permission(name="analyses:create"),
        Permission(name="analyses:read"),
        Permission(name="analyses:update"),
        Permission(name="analyses:delete"),
        Permission(name="users:manage"),
        Permission(name="settings:manage"),
        Permission(name="reports:generate"),
    ]
    
    # Create roles
    admin_role = Role(name="ADMIN")
    manager_role = Role(name="MANAGER")
    analyst_role = Role(name="ANALYST")
    viewer_role = Role(name="VIEWER")
    
    # Assign permissions to roles
    admin_role.permissions = permissions  # All
    manager_role.permissions = [
        p for p in permissions 
        if p.name in ["crops:read", "analyses:read", "analyses:create", 
                      "users:manage", "reports:generate"]
    ]
    analyst_role.permissions = [
        p for p in permissions 
        if p.name in ["crops:read", "analyses:create", "analyses:read"]
    ]
    viewer_role.permissions = [
        p for p in permissions 
        if "read" in p.name
    ]
    
    db.session.add_all(permissions + [admin_role, manager_role, analyst_role, viewer_role])
    db.session.commit()
```

### Phase 3: User Management UI (Week 2-3)

**Effort:** 4 hours  
**Deliverables:**

```
Endpoints:
├─ POST /admin/users - Create user
├─ GET /admin/users - List users
├─ PUT /admin/users/{user_id} - Update user
├─ DELETE /admin/users/{user_id} - Delete user
├─ POST /admin/users/{user_id}/roles - Assign roles
└─ GET /admin/users/{user_id} - User details

Angular components:
├─ Login page
├─ Password reset flow
├─ User profile page
├─ Admin user management
└─ Role assignment UI
```

### Phase 4: Migration to OAuth2 (Month 3-4)

**Effort:** 40+ hours  
**Timeline:** 3-4 weeks  
**Trigger:** Enterprise customer demands SSO

```
Strategy:
1. Keep JWT as primary (existing users)
2. Add OAuth2 alongside (new enterprise customers)
3. Use Auth0 or Azure AD as provider
4. Gradually migrate existing users
5. Eventually deprecate JWT for web app
```

---

## Security Best Practices

### Password Storage
```python
# Use Argon2 (modern, slow, memory-hard)
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

# Hash password
hashed = pwd_context.hash("user_password")

# Verify password
is_valid = pwd_context.verify("user_password", hashed)
```

### Token Storage (Client-Side)
```javascript
// DO: Store in localStorage (accessible via JavaScript)
localStorage.setItem('access_token', token);

// DO: Store sensitive tokens in httpOnly cookies (not accessible via JS)
// (Server sets this automatically)

// DON'T: Store in sessionStorage (lost on tab close)
// DON'T: Store in plain text in URL

// DON'T: Store in non-httpOnly cookie (accessible to JavaScript, XSS risk)
```

### Token Transmission
```
✅ CORRECT: Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
❌ WRONG: Authorization: JWT eyJhbGciOiJIUzI1NiIs...
❌ WRONG: X-Auth-Token: eyJhbGciOiJIUzI1NiIs...
```

### CORS Configuration
```python
# FastAPI main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://crop-ai-demo.com"],  # Specific origins
    allow_credentials=True,  # Allow cookies
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)
```

### Rate Limiting
```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.post("/auth/login")
@limiter.limit("5/minute")  # Max 5 login attempts per minute
async def login(request: TokenRequest):
    pass
```

### Audit Logging
```python
# Log all authentication events
import logging

logger = logging.getLogger("auth")

@router.post("/login")
async def login(request: TokenRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == request.email).first()
    
    if user and utils.verify_password(request.password, user.password_hash):
        logger.info(f"User {user.email} logged in from {request.client.host}")
    else:
        logger.warning(f"Failed login attempt for {request.email}")
```

---

## Implementation Checklist

### Week 1: JWT Implementation
- [ ] Design database schema (users, roles, permissions, sessions)
- [ ] Create PostgreSQL tables and indexes
- [ ] Implement password hashing (Argon2)
- [ ] Implement JWT token creation and validation
- [ ] Create login endpoint
- [ ] Create token refresh endpoint
- [ ] Create logout endpoint (optional)
- [ ] Add authentication dependency for protected routes
- [ ] Add permission checking decorator
- [ ] Write integration tests (8 test cases minimum)
- [ ] Deploy to staging environment
- [ ] Performance test (1000 concurrent logins)
- [ ] Security review

### Week 2: RBAC & User Management
- [ ] Define roles (ADMIN, MANAGER, ANALYST, VIEWER)
- [ ] Define permissions (40+ base permissions)
- [ ] Create user management endpoints
- [ ] Create role assignment endpoints
- [ ] Add user listing and filtering
- [ ] Add user enable/disable
- [ ] Write tests for RBAC (10+ test cases)
- [ ] Documentation

### Week 3: UI & Integration
- [ ] Create login page (Angular)
- [ ] Create user profile page
- [ ] Create password change page
- [ ] Create admin user management UI
- [ ] Integrate with existing API endpoints
- [ ] Test end-to-end flows
- [ ] User acceptance testing

### Week 4: Production Hardening
- [ ] Enable HTTPS only (certificates)
- [ ] Enable CORS properly
- [ ] Rate limiting on /login
- [ ] Audit logging setup
- [ ] Backup strategy for user data
- [ ] Data retention policy
- [ ] Incident response plan

---

## Cost Analysis

### MVP Phase (Months 1-3): JWT
| Component | Cost | Notes |
|-----------|------|-------|
| PostgreSQL (existing) | $0 | Already deployed |
| Redis (optional, for blacklist) | $0 | Reuse existing instance |
| Development (5h backend) | Included | Part of sprint |
| **Total Monthly** | **$0** | No additional costs |

### Growth Phase (Months 3-6): RBAC + User Management
| Component | Cost | Notes |
|-----------|------|-------|
| PostgreSQL (existing) | $0 | Same database |
| Development (3h backend, 4h frontend) | Included | Part of sprint |
| **Total Monthly** | **$0** | No additional costs |

### Enterprise Phase (Months 6-9): OAuth2
| Component | Cost | Notes |
|-----------|------|-------|
| Auth0 or Azure AD | $0-300/month | If using managed provider |
| Development (40h refactor) | Included | Major sprint |
| **Total Monthly** | **$0-300** | Optional, only when needed |

---

## Testing Strategy

### Unit Tests (JWT Utils)
```python
def test_hash_password():
    # Password hashing is consistent
    pass

def test_verify_password():
    # Password verification works
    pass

def test_create_access_token():
    # Token contains correct claims
    pass

def test_create_refresh_token():
    # Refresh token is separate from access token
    pass

def test_decode_token_success():
    # Valid token decodes correctly
    pass

def test_decode_token_expired():
    # Expired token raises exception
    pass
```

### Integration Tests (API Endpoints)
```python
def test_login_flow_success():
    # 1. Create user
    # 2. Login with correct password
    # 3. Receive access + refresh tokens
    # 4. Verify tokens are valid
    pass

def test_login_flow_invalid_credentials():
    # Invalid password returns 401
    pass

def test_protected_endpoint_with_auth():
    # Authenticated request succeeds
    pass

def test_protected_endpoint_without_auth():
    # Unauthenticated request returns 401
    pass

def test_refresh_token_flow():
    # Can refresh expired access token
    pass

def test_permission_based_access():
    # User without permission returns 403
    pass

def test_role_based_access():
    # User with correct role can perform action
    pass
```

### Load Testing
```bash
# Using Apache Bench
ab -n 1000 -c 50 -p login.json -T application/json http://localhost:8000/auth/login

# Using k6 (more realistic)
import http from 'k6/http';
import { check } from 'k6';

export let options = {
  vus: 100,  // 100 virtual users
  duration: '30s',
};

export default function () {
  let response = http.post('http://localhost:8000/auth/login', {
    email: 'user@example.com',
    password: 'password'
  });
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'has token': (r) => r.json('access_token') !== null,
  });
}
```

---

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing (unit + integration)
- [ ] Code review approved
- [ ] Security review completed
- [ ] Load testing validated
- [ ] Rollback plan in place
- [ ] Database migrations tested

### Production Deployment
- [ ] Deploy to production during low-traffic window
- [ ] Monitor error rates (should be <0.01%)
- [ ] Monitor latency (should be <100ms p99)
- [ ] Monitor token validation failures
- [ ] Have quick rollback plan ready
- [ ] Announce new feature to users

### Post-Deployment
- [ ] Monitor for 24 hours
- [ ] Gather user feedback
- [ ] Fix any immediate issues
- [ ] Schedule follow-up: RBAC implementation (1 week)

---

## Known Issues & Workarounds

### Issue 1: Token Cannot Be Revoked Immediately
**Problem:** JWT tokens are stateless—once issued, they're valid until expiration.  
**Scenario:** Admin revokes a user's access, but they can still use their token for 15 minutes.

**Workarounds:**
1. Use short token lifetime (15 min) so damage is limited
2. Implement optional Redis blacklist for critical operations
3. Client-side logout clears localStorage immediately

```python
# Optional: Redis blacklist for critical operations
from redis import Redis

redis_client = Redis(host='localhost', port=6379)

def add_token_to_blacklist(token_jti: str, expiration_time: int):
    """Add token to blacklist so it can't be reused"""
    redis_client.setex(f"blacklist:{token_jti}", expiration_time, "true")

def is_token_blacklisted(token_jti: str) -> bool:
    """Check if token is in blacklist"""
    return redis_client.exists(f"blacklist:{token_jti}") > 0

@router.post("/logout")
async def logout(current_user: dict = Depends(get_current_user)):
    # Get JTI from token
    jti = current_user.get("jti")
    
    # Add to blacklist (expires when token would anyway)
    add_token_to_blacklist(jti, ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    
    return {"message": "Logged out"}
```

### Issue 2: No Built-in Multi-Device Awareness
**Problem:** User logs in from phone and laptop—both have valid tokens.  
**Scenario:** How do we know which device is which? Can we revoke one device?

**Workaround:** Add optional device tracking

```python
# Add to /auth/login
from uuid import uuid4

@router.post("/login")
async def login(request: TokenRequest, db: Session = Depends(get_db)):
    # ... existing code ...
    
    # Create session (device tracking)
    session = Session(
        user_id=user.id,
        device_name=request.device_name or "Unknown",
        device_type=request.device_type or "web",
        ip_address=request.client.host,
        user_agent=request.headers.get("user-agent"),
    )
    db.add(session)
    db.commit()
    
    # Include session ID in token
    access_token = utils.create_access_token(
        user_id=user.id,
        email=user.email,
        session_id=session.id,  # NEW
        roles=roles,
        permissions=permissions
    )
```

### Issue 3: Token Hijacking (CSRF)
**Problem:** If token is stolen (XSS attack), attacker can use it.

**Mitigations:**
1. Use HTTPS always (prevents man-in-the-middle)
2. Store tokens in httpOnly cookies (prevents XSS access)
3. Add CSRF token for state-changing operations
4. Short token lifetime (15 min)
5. Content Security Policy headers

---

## Monitoring & Metrics

### Key Metrics to Track
```
1. Authentication Success Rate
   - Target: >99.9% login attempts succeed
   - Alert: <99% success rate

2. Authentication Latency
   - Target: <100ms p99
   - Alert: >500ms p99

3. Token Refresh Rate
   - Target: <10% of requests are refresh
   - Alert: >30% refresh rate (indicates users re-logging in)

4. Failed Login Attempts
   - Track by user, IP, email
   - Alert: >5 failed attempts in 1 minute (brute force attempt)

5. Token Validation Errors
   - Track invalid token type, expired, malformed
   - Alert: >0.1% error rate
```

### Logging
```python
# Configure logging
import logging
from pythonjsonlogger import jsonlogger

logger = logging.getLogger("auth")
logHandler = logging.FileHandler('auth.log')
formatter = jsonlogger.JsonFormatter()
logHandler.setFormatter(formatter)
logger.addHandler(logHandler)

# Log all auth events
logger.info("login_success", extra={
    "user_id": user.id,
    "email": user.email,
    "ip": request.client.host,
    "timestamp": datetime.utcnow()
})

logger.warning("failed_login", extra={
    "email": request.email,
    "ip": request.client.host,
    "reason": "invalid_password"
})

logger.warning("token_validation_failed", extra={
    "token_type": "access",
    "error": "expired",
    "user_id": payload.get("sub")
})
```

---

## Migration Path to OAuth2

When time comes to migrate to OAuth2 (enterprise customers demand it):

```
Phase 1: Add OAuth2 alongside JWT (Week 1-2)
├─ Implement OAuth2 authorization code flow
├─ Setup Azure AD / Auth0 connection
├─ Create "Login with Microsoft" button
└─ New enterprise customers use OAuth2

Phase 2: Migrate existing JWT users (Week 3-4)
├─ Send email: "Migrate to Single Sign-On"
├─ Offer 1-click migration link
├─ Link Azure AD account to existing user
└─ Keep JWT as fallback for transition period

Phase 3: Sunset JWT (Optional, after 6 months)
├─ Move JWT users to OAuth2
├─ Deprecate JWT endpoints
├─ Keep API keys for CI/CD
└─ OAuth2 becomes primary auth method
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Recommended Approach** | JWT + PostgreSQL for MVP |
| **Timeline** | 5 hours implementation |
| **Team** | 1 backend developer |
| **Cost** | $0 (reuse existing infrastructure) |
| **Security** | Production-ready with best practices |
| **Scalability** | Handles 10,000+ concurrent users |
| **Enterprise Ready** | Clear migration path to OAuth2 |
| **Deployment** | Week 1 of MVP |

---

## References

- JWT: https://jwt.io/introduction/
- OWASP Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- FastAPI Security: https://fastapi.tiangolo.com/tutorial/security/
- Argon2: https://en.wikipedia.org/wiki/Argon2
- OAuth2 Specification: https://tools.ietf.org/html/rfc6749
- OpenID Connect: https://openid.net/connect/

---

**Next:** Once Authentication & Authorization is locked in, proceed to Blob Storage & Lifecycle Management (Priority 2).
