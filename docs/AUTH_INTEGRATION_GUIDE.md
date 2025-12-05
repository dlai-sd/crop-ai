"""
Integration guide for adding authentication to the main FastAPI application.

This module shows how to integrate the auth module with the main crop-ai API.
"""

# ============================================================================
# STEP 1: Update api.py with auth imports
# ============================================================================

"""
Add these imports to the top of api.py:

from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter
from slowapi.util import get_remote_address
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .auth.models import Base as AuthBase
from .auth.routes import router as auth_router
from .auth.init_db import init_auth_db
from .auth.dependencies import get_db
"""

# ============================================================================
# STEP 2: Update startup and shutdown in api.py
# ============================================================================

"""
Update the _startup() function to initialize auth database:

async def _startup():
    '''Initialize model, database, and auth on startup.'''
    global model_adapter, db, auth_db_session
    logger.info("crop-ai service starting up...")
    
    try:
        model_adapter = ModelAdapter()
        logger.info("Model adapter initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize model adapter: {e}")
        model_adapter = None
    
    try:
        db = await get_database()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        db = None
    
    # Initialize auth database
    try:
        auth_engine = create_engine(
            os.getenv(
                "AUTH_DATABASE_URL",
                "sqlite:///./auth.db"  # Default to SQLite for demo
            )
        )
        AuthBase.metadata.create_all(auth_engine)
        AuthSessionLocal = sessionmaker(bind=auth_engine)
        auth_db_session = AuthSessionLocal()
        
        # Initialize auth data (roles, permissions, admin user)
        init_auth_db(auth_db_session, create_admin=True)
        logger.info("Auth database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize auth database: {e}")
        auth_db_session = None
"""

# ============================================================================
# STEP 3: Configure CORS in api.py after app creation
# ============================================================================

"""
Add this after creating the FastAPI app:

# Configure CORS for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure rate limiting
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add rate limiting to login endpoint
@app.post("/auth/login")
@limiter.limit("5/minute")
async def login(request, credentials):
    ...
"""

# ============================================================================
# STEP 4: Add auth routes to main app
# ============================================================================

"""
Include the auth router in the main app:

# Include auth routes
app.include_router(auth_router)

# This makes these endpoints available:
# POST   /auth/login       - User login
# POST   /auth/refresh     - Token refresh
# POST   /auth/logout      - User logout
# GET    /auth/me          - Get current user
# POST   /auth/verify      - Verify token
"""

# ============================================================================
# STEP 5: Protect endpoints with auth
# ============================================================================

"""
Use the auth dependencies to protect endpoints:

from .auth.dependencies import (
    get_current_user,
    require_permission,
    require_role,
    require_any_permission,
)

# Example 1: Require authentication
@app.get("/protected")
async def protected_endpoint(current_user: dict = Depends(get_current_user)):
    return {
        "message": "This is protected",
        "user_id": current_user["user_id"],
        "email": current_user["email"],
    }

# Example 2: Require specific role
@app.get("/admin-only")
async def admin_endpoint(current_user: dict = Depends(require_role("ADMIN"))):
    return {"message": "Admin access only"}

# Example 3: Require specific permission
@app.post("/create-crop")
async def create_crop(
    crop_data: dict,
    current_user: dict = Depends(require_permission("crops:create")),
):
    return {"message": "Crop created", "user": current_user["email"]}

# Example 4: Require any permission
@app.get("/crop-analysis")
async def analyze_crop(
    current_user: dict = Depends(
        require_any_permission(["analyses:create", "analyses:read"])
    ),
):
    return {"message": "Analysis data"}

# Example 5: Protect the predict endpoint
@app.post("/predict", response_model=PredictionResponse)
async def predict(
    request: PredictionRequest,
    current_user: dict = Depends(require_permission("crops:read")),
):
    '''Predict crop type from satellite imagery (requires crops:read permission).'''
    # ... existing prediction logic ...
"""

# ============================================================================
# STEP 6: Example complete integration in api.py
# ============================================================================

COMPLETE_API_INTEGRATION = """
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from contextlib import asynccontextmanager
import logging
import sys
import os
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from .predict import ModelAdapter
from .monitoring import get_monitor
from .database import get_database, PredictionRecord
from .telemetry import get_telemetry, init_telemetry_logging, PredictionMetric, HealthMetric
from .auth.models import Base as AuthBase
from .auth.routes import router as auth_router
from .auth.init_db import init_auth_db
from .auth.dependencies import require_permission

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

# Initialize Application Insights telemetry
init_telemetry_logging()
telemetry = get_telemetry()

# Global state
model_adapter = None
db = None
auth_db_session = None
startup_time = datetime.utcnow()
inference_count = 0
monitor = get_monitor()

async def _startup():
    '''Initialize model, database, and auth on startup.'''
    global model_adapter, db, auth_db_session
    logger.info("crop-ai service starting up...")
    
    try:
        model_adapter = ModelAdapter()
        logger.info("Model adapter initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize model adapter: {e}")
        model_adapter = None
    
    try:
        db = await get_database()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        db = None
    
    # Initialize auth database
    try:
        auth_db_url = os.getenv(
            "AUTH_DATABASE_URL",
            "sqlite:///./auth.db"
        )
        auth_engine = create_engine(auth_db_url)
        AuthBase.metadata.create_all(auth_engine)
        AuthSessionLocal = sessionmaker(bind=auth_engine)
        auth_db_session = AuthSessionLocal()
        
        init_auth_db(auth_db_session, create_admin=True)
        logger.info("Auth database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize auth database: {e}")

@asynccontextmanager
async def lifespan(app: FastAPI):
    '''Lifespan context manager for startup/shutdown.'''
    await _startup()
    yield
    logger.info("crop-ai service shutting down...")

# Initialize FastAPI app
app = FastAPI(
    title="crop-ai",
    description="Crop Identification Service using Satellite Imagery",
    version="0.1.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include auth routes
app.include_router(auth_router)

class PredictionRequest(BaseModel):
    '''Request model for crop prediction.'''
    image_url: str
    model_version: str = "latest"

class PredictionResponse(BaseModel):
    '''Response model for crop prediction.'''
    crop_type: str
    confidence: float
    model_version: str
    timestamp: str

# Health check (no auth required)
@app.get("/health")
async def health():
    '''Health check endpoint.'''
    uptime = (datetime.utcnow() - startup_time).total_seconds()
    return {
        "status": "healthy",
        "uptime_seconds": uptime,
        "inference_count": inference_count
    }

# Protected prediction endpoint
@app.post("/predict", response_model=PredictionResponse)
async def predict(
    request: PredictionRequest,
    current_user: dict = Depends(require_permission("crops:read")),
):
    '''Predict crop type (requires crops:read permission).'''
    global inference_count
    
    if model_adapter is None:
        raise HTTPException(status_code=503, detail="Model not initialized")
    
    try:
        logger.info(f"Prediction by {current_user['email']}: {request.image_url}")
        
        crop_type = "wheat"
        confidence = 0.85
        
        inference_count += 1
        
        return PredictionResponse(
            crop_type=crop_type,
            confidence=confidence,
            model_version=request.model_version,
            timestamp=datetime.utcnow().isoformat()
        )
    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail="Prediction failed")
"""

# ============================================================================
# STEP 7: Environment variables to set
# ============================================================================

"""
Set these environment variables:

# Auth configuration
AUTH_DATABASE_URL=postgresql://user:password@localhost/crop_ai_auth
SECRET_KEY=your-super-secret-key-change-in-production
REFRESH_SECRET_KEY=your-refresh-secret-key-change-in-production

# CORS configuration
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# Optional: Rate limiting
RATE_LIMIT_LOGIN=5/minute

For development, you can set these in a .env file and use python-dotenv to load them.
"""

# ============================================================================
# STEP 8: Test the integration
# ============================================================================

"""
Test the complete auth flow:

1. Start the server:
   uvicorn crop_ai.api:app --reload

2. Create an account (or use default admin):
   curl -X POST http://localhost:8000/auth/login \\
     -H "Content-Type: application/json" \\
     -d '{"email": "admin@cropai.dev", "password": "admin123!"}'
   
   Response:
   {
     "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
     "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
     "token_type": "bearer",
     "expires_in": 900
   }

3. Use token to access protected endpoints:
   curl -X GET http://localhost:8000/auth/me \\
     -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
   
   Response:
   {
     "id": 1,
     "email": "admin@cropai.dev",
     "username": "admin",
     "is_active": true,
     "roles": ["ADMIN"],
     "permissions": [...],
     "created_at": "2025-01-01T12:00:00",
     "updated_at": "2025-01-01T12:00:00"
   }

4. Test protected prediction endpoint:
   curl -X POST http://localhost:8000/predict \\
     -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc..." \\
     -H "Content-Type: application/json" \\
     -d '{"image_url": "http://example.com/image.jpg"}'
   
   Response:
   {
     "crop_type": "wheat",
     "confidence": 0.85,
     "model_version": "latest",
     "timestamp": "2025-01-01T12:00:00"
   }
"""

if __name__ == "__main__":
    print("This is an integration guide. See the COMPLETE_API_INTEGRATION variable for example code.")
