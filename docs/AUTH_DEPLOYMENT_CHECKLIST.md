# Authentication Module - Deployment Checklist

Complete implementation status and deployment guide for production.

## ✅ Implementation Status

### Core Components
- ✅ SQLAlchemy models (User, Role, Permission, Session, TokenBlacklist)
- ✅ Pydantic schemas (validation and serialization)
- ✅ Password hashing utilities (Argon2)
- ✅ JWT token generation and validation
- ✅ FastAPI dependencies (authentication decorators)
- ✅ CRUD operations (user, role, permission management)
- ✅ Database initialization (roles, permissions, admin user)
- ✅ Authentication routes (login, refresh, logout, me, verify)
- ✅ Comprehensive error handling
- ✅ Logging and monitoring

### Features
- ✅ JWT access tokens (15 minutes)
- ✅ Refresh tokens (7 days)
- ✅ Token blacklisting (logout support)
- ✅ Role-Based Access Control (RBAC)
- ✅ 4 predefined roles (ADMIN, MANAGER, ANALYST, VIEWER)
- ✅ 24+ granular permissions
- ✅ Session tracking (device info)
- ✅ User management
- ✅ Rate limiting support

### Testing
- ✅ Password hashing tests (6 test cases)
- ✅ JWT token tests (7 test cases)
- ✅ User management tests (3 test cases)
- ✅ Role management tests (2 test cases)
- ✅ Permission management tests (3 test cases)
- ✅ Database initialization tests (3 test cases)
- ✅ Authentication flow tests (1 comprehensive test)
- ✅ Total: 25+ unit and integration tests

### Documentation
- ✅ Module README with quick start
- ✅ Integration guide for main API
- ✅ API endpoint documentation
- ✅ Usage examples
- ✅ Configuration guide
- ✅ Troubleshooting section
- ✅ Security best practices

## 📋 Pre-Deployment Checklist

### Code Quality
- [ ] Run all tests: `pytest tests/test_auth.py -v`
- [ ] Check code coverage: `pytest --cov=crop_ai.auth tests/test_auth.py`
- [ ] Run linting: `ruff check src/crop_ai/auth/`
- [ ] Run type checking: `mypy src/crop_ai/auth/`
- [ ] Review all auth files for hardcoded secrets

### Security
- [ ] Change default admin password
- [ ] Set strong SECRET_KEY (min 32 characters)
- [ ] Set strong REFRESH_SECRET_KEY (min 32 characters)
- [ ] Configure HTTPS only in production
- [ ] Set CORS_ORIGINS to specific domains
- [ ] Enable HSTS headers
- [ ] Implement rate limiting on /login
- [ ] Set up audit logging
- [ ] Review error messages (don't leak sensitive info)
- [ ] Configure token expiration times
- [ ] Set up token rotation policy
- [ ] Enable CSRF protection if using cookies

### Database
- [ ] Choose database backend (SQLite for dev, PostgreSQL for prod)
- [ ] Configure database URL in environment
- [ ] Run database migrations
- [ ] Create initial admin user
- [ ] Verify database backups configured
- [ ] Test database recovery procedure
- [ ] Set up database connection pooling
- [ ] Configure database logging

### Infrastructure
- [ ] Set up environment variables on deployment platform
- [ ] Configure SECRET_KEY and REFRESH_SECRET_KEY
- [ ] Configure database connection string
- [ ] Configure CORS origins
- [ ] Set up log aggregation
- [ ] Configure monitoring/alerting
- [ ] Set up automatic backups
- [ ] Configure load balancing (if multi-instance)
- [ ] Set up SSL certificates

### Integration
- [ ] Integrate auth routes into main FastAPI app
- [ ] Add auth middleware to app
- [ ] Configure CORS middleware
- [ ] Add rate limiting middleware
- [ ] Update main API documentation
- [ ] Protect existing endpoints
- [ ] Update frontend to use auth endpoints
- [ ] Test end-to-end authentication flow

### Documentation
- [ ] Update main README with auth setup
- [ ] Document environment variables
- [ ] Document deployment procedure
- [ ] Document troubleshooting for ops team
- [ ] Create runbooks for common issues
- [ ] Document password reset procedure
- [ ] Document user creation procedure
- [ ] Document admin account recovery

## 🚀 Deployment Steps

### 1. Pre-Deployment (Dev Environment)

```bash
# Install dependencies
pip install -r requirements.txt

# Run tests
pytest tests/test_auth.py -v

# Check coverage
pytest --cov=crop_ai.auth tests/test_auth.py --cov-report=html

# Verify linting
ruff check src/crop_ai/auth/
mypy src/crop_ai/auth/
```

### 2. Configuration (Before Deployment)

Create `.env` file (or set environment variables):

```bash
# Auth Configuration
SECRET_KEY=your-super-secret-key-min-32-chars-change-this
REFRESH_SECRET_KEY=your-refresh-secret-key-min-32-chars-change-this
AUTH_DATABASE_URL=sqlite:///auth.db  # Change to PostgreSQL for production
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
```

### 3. Database Setup

```python
# Initialize auth database
from crop_ai.auth import init_auth_db
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from crop_ai.auth.models import Base

engine = create_engine("postgresql://user:pass@localhost/crop_ai_auth")
Base.metadata.create_all(engine)
session = sessionmaker(bind=engine)()
init_auth_db(session, create_admin=True)

print("Database initialized!")
print("Admin user: admin@cropai.dev")
print("Admin password: admin123!  <-- CHANGE THIS!")
```

### 4. API Integration

Update `src/crop_ai/api.py`:

```python
from fastapi.middleware.cors import CORSMiddleware
from crop_ai.auth import auth_router, init_auth_db
from crop_ai.auth.models import Base as AuthBase
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Initialize auth database
auth_engine = create_engine(os.getenv("AUTH_DATABASE_URL", "sqlite:///auth.db"))
AuthBase.metadata.create_all(auth_engine)
AuthSessionLocal = sessionmaker(bind=auth_engine)
auth_session = AuthSessionLocal()
init_auth_db(auth_session, create_admin=True)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include auth routes
app.include_router(auth_router)
```

### 5. Protect Endpoints

```python
from crop_ai.auth import require_permission

@app.post("/predict")
async def predict(
    request: PredictionRequest,
    current_user: dict = Depends(require_permission("crops:read")),
):
    # Endpoint now requires authentication and crops:read permission
    return prediction_result
```

### 6. Test Deployment

```bash
# Start server
uvicorn crop_ai.api:app --reload

# Test login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@cropai.dev", "password": "admin123!"}'

# Test protected endpoint
curl -X POST http://localhost:8000/predict \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"image_url": "http://example.com/image.jpg"}'

# Test token refresh
curl -X POST http://localhost:8000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "YOUR_REFRESH_TOKEN"}'

# Test logout
curl -X POST http://localhost:8000/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 7. Production Deployment

```bash
# For Docker deployment
docker build -t crop-ai:latest .
docker run -p 8000:8000 \
  -e SECRET_KEY="prod-secret-key" \
  -e REFRESH_SECRET_KEY="prod-refresh-key" \
  -e AUTH_DATABASE_URL="postgresql://user:pass@prod-db:5432/crop_ai" \
  -e CORS_ORIGINS="https://yourdomain.com" \
  crop-ai:latest

# For Kubernetes
kubectl apply -f k8s/auth-deployment.yaml
kubectl apply -f k8s/auth-service.yaml

# For serverless (Azure Functions, AWS Lambda, etc.)
# See deployment-specific documentation
```

## 🔐 Security Hardening

### Before Going to Production

1. **Change Default Credentials**
   ```python
   # Login and change admin password immediately
   # Or set new admin password during initialization
   ```

2. **Configure Strong Keys**
   ```bash
   # Generate strong secret keys
   python -c "import secrets; print(secrets.token_urlsafe(32))"
   ```

3. **Set Up Monitoring**
   ```python
   # Track failed login attempts
   # Alert on multiple failed attempts
   # Monitor token refresh patterns
   ```

4. **Configure Rate Limiting**
   ```python
   # Limit login attempts: 5 per minute per IP
   # Limit token refresh: 10 per hour per user
   # Limit API calls: Based on role
   ```

5. **Enable Audit Logging**
   ```python
   # Log all authentication events
   # Log all role/permission changes
   # Log all user creation/deletion
   ```

6. **Set Up Certificate Management**
   ```bash
   # Use Let's Encrypt for HTTPS
   # Auto-renew certificates
   # Set HSTS headers
   ```

## 📊 Monitoring & Alerts

### Key Metrics to Monitor

- Login success/failure rate
- Token refresh rate
- Permission denial rate
- Database query times
- Auth endpoint response times
- Failed password attempts per user

### Alerts to Configure

- Multiple failed logins from same IP (potential attack)
- Unusual token refresh patterns (potential account compromise)
- High permission denial rate (potential misconfiguration)
- Database connection failures
- Auth service errors

## 📝 Operational Procedures

### User Management

```bash
# Create new user (via API or admin panel)
curl -X POST http://localhost:8000/auth/admin/users \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "username": "newuser",
    "password": "SecurePass123!"
  }'

# Assign role to user
curl -X POST http://localhost:8000/auth/admin/users/1/roles \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role_id": 2}'

# Reset user password
curl -X POST http://localhost:8000/auth/admin/users/1/reset-password \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"new_password": "NewSecurePass123!"}'

# Disable user account
curl -X PATCH http://localhost:8000/auth/admin/users/1 \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_active": false}'
```

### Troubleshooting

```bash
# Check database connection
python -c "from sqlalchemy import create_engine; engine = create_engine('postgresql://...'); engine.connect()"

# Verify token validity
curl -X POST http://localhost:8000/auth/verify \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check user permissions
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"

# View logs
tail -f /var/log/crop-ai/auth.log
```

## 📞 Support

### Common Issues

1. **"Invalid email or password"** - Check credentials, verify user exists
2. **"Token expired"** - Use refresh token to get new access token
3. **"Permission denied"** - Check user roles and permissions
4. **"User not found"** - Verify user was created in admin
5. **"Database connection error"** - Check database URL and connectivity

### Escalation

- Check logs for detailed error information
- Run diagnostic tests (see Testing section)
- Review security policies if compromised
- Contact development team for complex issues

## 🎯 Success Criteria

- [ ] All 25+ tests passing
- [ ] Zero failed logins in first 24 hours (normal operation)
- [ ] Token refresh working correctly
- [ ] Protected endpoints returning 403 for unauthorized users
- [ ] All API endpoints documented and accessible
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery procedures tested
- [ ] Security audit passed

## 📅 Post-Deployment

### First Week
- Monitor login patterns
- Check error logs daily
- Verify database backups
- Test user creation workflow
- Verify CORS working correctly

### First Month
- Review auth metrics
- Analyze performance
- Optimize database queries
- Implement any feedback
- Update documentation based on actual usage

### Ongoing
- Keep dependencies updated
- Monitor security advisories
- Review access logs
- Rotate secrets periodically
- Test disaster recovery quarterly
