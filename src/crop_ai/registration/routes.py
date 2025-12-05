"""
Registration service API routes.

Endpoints for:
- Start registration
- Verify email/SMS
- Complete registration
- SSO callbacks
- Profile retrieval
"""
from typing import Optional
from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks, Query
from sqlalchemy.orm import Session
from datetime import datetime

from crop_ai.registration.models import UserRole, RegistrationStatus
from crop_ai.registration.schemas import (
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
from crop_ai.registration.sso import get_sso_manager
from crop_ai.registration.verification import get_verification_service
from crop_ai.registration.location import get_location_service
from crop_ai.registration import crud
from crop_ai.registration import init_db


# Create router
router = APIRouter(prefix="/api/v1/register", tags=["registration"])

# In-memory registration sessions (use Redis in production)
registration_sessions = {}


# ============================================================================
# Dependency
# ============================================================================

def get_db() -> Session:
    """Get database session."""
    from crop_ai.core.database import SessionLocal
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ============================================================================
# Helper Functions
# ============================================================================

def create_session_id() -> str:
    """Create unique registration session ID."""
    import secrets
    return secrets.token_urlsafe(16)


def store_session(registration_id: str, data: dict) -> None:
    """Store registration session data."""
    # In production, use Redis with TTL
    registration_sessions[registration_id] = {
        **data,
        "created_at": datetime.utcnow(),
        "expires_at": datetime.utcnow().timestamp() + 3600,  # 1 hour
    }


def get_session(registration_id: str) -> Optional[dict]:
    """Retrieve registration session data."""
    session = registration_sessions.get(registration_id)
    if not session:
        return None
    # Check expiration
    if datetime.utcnow().timestamp() > session["expires_at"]:
        del registration_sessions[registration_id]
        return None
    return session


def cleanup_session(registration_id: str) -> None:
    """Clean up registration session."""
    registration_sessions.pop(registration_id, None)


# ============================================================================
# Registration Start
# ============================================================================

@router.post("/start", response_model=RegistrationStartResponse)
async def start_registration(
    request: RegistrationStartRequest,
    background_tasks: BackgroundTasks,
) -> RegistrationStartResponse:
    """
    Start registration process.
    
    Creates a registration session and sends initial verification (email/SMS).
    """
    registration_id = create_session_id()
    verification_service = get_verification_service()
    
    # Determine verification method
    if request.registration_method == "email":
        if not request.email:
            raise HTTPException(status_code=400, detail="Email required for email registration")
        
        # Send email verification
        try:
            token, expires_at = await verification_service.send_email_verification(
                email=request.email,
                name="User",
                registration_id=registration_id,
            )
            verification_method = "email"
            contact = request.email
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")
    
    elif request.registration_method == "mobile":
        if not request.mobile:
            raise HTTPException(status_code=400, detail="Mobile required for mobile registration")
        
        # Send SMS OTP
        try:
            otp, expires_at = await verification_service.send_sms_otp(request.mobile)
            verification_method = "sms"
            contact = request.mobile
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to send SMS: {str(e)}")
    
    elif request.registration_method.startswith("sso_"):
        # SSO registration doesn't require initial verification
        verification_method = "none"
        contact = None
    
    else:
        raise HTTPException(status_code=400, detail="Invalid registration method")
    
    # Store session
    store_session(
        registration_id,
        {
            "role": request.role,
            "registration_method": request.registration_method,
            "contact": contact,
            "device_type": request.device_type,
            "referrer": request.referrer,
            "status": "pending_verification",
        },
    )
    
    return RegistrationStartResponse(
        registration_id=registration_id,
        role=request.role,
        registration_method=request.registration_method,
        verification_required=verification_method,
        expires_at=datetime.utcnow(),
    )


# ============================================================================
# Verification
# ============================================================================

@router.post("/verify-token", response_model=VerifyTokenResponse)
async def verify_token(
    request: VerifyTokenRequest,
    db: Session = Depends(get_db),
) -> VerifyTokenResponse:
    """Verify email or SMS token."""
    session = get_session(request.registration_id)
    if not session:
        raise HTTPException(status_code=400, detail="Invalid or expired registration session")
    
    verification_service = get_verification_service()
    
    # In production, retrieve token from database
    # For now, simulate with stored session
    token_valid, error = verification_service.verify_token(
        provided_token=request.token,
        stored_token=request.token,  # Simplified for demo
        expires_at=datetime.utcnow(),
        attempts=0,
    )
    
    if not token_valid:
        raise HTTPException(status_code=400, detail=error)
    
    # Update session status
    session["status"] = f"{request.token_type}_verified"
    store_session(request.registration_id, session)
    
    return VerifyTokenResponse(
        verified=True,
        registration_id=request.registration_id,
        next_step="complete_profile",
    )


# ============================================================================
# SSO Callback
# ============================================================================

@router.post("/sso/callback", response_model=SSOCallbackResponse)
async def sso_callback(
    request: SSOLoginRequest,
    code: str = Query(...),
    state: str = Query(...),
    db: Session = Depends(get_db),
) -> SSOCallbackResponse:
    """
    Handle SSO provider callback.
    
    Exchange OAuth code for user info and create/link account.
    """
    sso_manager = get_sso_manager()
    
    try:
        # Handle OAuth callback
        user_info, token_response = await sso_manager.handle_callback(
            provider_name=request.provider,
            code=code,
            state=state,
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"SSO authentication failed: {str(e)}")
    
    # Check if user already exists
    existing_sso = crud.get_sso_account_by_provider_id(
        db,
        provider=user_info.provider,
        provider_user_id=user_info.provider_user_id,
    )
    
    if existing_sso:
        # User exists - update last used
        crud.update_sso_account_last_used(db, existing_sso.id)
        user_profile = crud.get_user_profile(db, existing_sso.user_id)
        return SSOCallbackResponse(
            registration_id="",  # User already exists
            user_exists=True,
            role=user_profile.role,
            next_step="redirect_to_dashboard",
        )
    
    # New user - create registration session
    registration_id = create_session_id()
    store_session(
        registration_id,
        {
            "role": request.role,
            "registration_method": f"sso_{request.provider}",
            "sso_user_info": user_info.dict(),
            "sso_tokens": token_response.dict(),
            "status": "pending_profile_completion",
        },
    )
    
    return SSOCallbackResponse(
        registration_id=registration_id,
        user_exists=False,
        role=request.role,
        next_step="complete_profile",
    )


# ============================================================================
# Complete Registration
# ============================================================================

@router.post("/farmer/complete", response_model=RegistrationCompleteResponse)
async def complete_farmer_registration(
    request: FarmerRegistrationRequest,
    db: Session = Depends(get_db),
) -> RegistrationCompleteResponse:
    """Complete farmer registration."""
    session = get_session(request.registration_id)
    if not session:
        raise HTTPException(status_code=400, detail="Invalid registration session")
    
    # Check for duplicate email/mobile
    if crud.get_user_profile_by_email(db, request.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    if crud.get_user_profile_by_mobile(db, request.mobile):
        raise HTTPException(status_code=400, detail="Mobile already registered")
    
    # Create user profile
    user_profile = crud.create_user_profile(
        db,
        role=UserRole.FARMER,
        name=request.name,
        email=request.email,
        mobile=request.mobile,
        address=request.address.address,
        city=request.address.city,
        state=request.address.state,
        postal_code=request.address.postal_code,
        country=request.address.country,
        latitude=request.location.latitude,
        longitude=request.location.longitude,
        language_preference=request.preferences.language_preference,
    )
    
    # Create farmer profile
    crud.create_farmer_profile(
        db,
        user_id=user_profile.id,
        farm_size=request.farm_data.farm_size,
        farm_size_unit=request.farm_data.farm_size_unit,
        primary_crop=request.farm_data.primary_crop,
        farm_type=request.farm_data.farm_type,
        experience_level=request.farm_data.experience_level,
        irrigation_type=request.farm_data.irrigation_type,
        secondary_crops=request.farm_data.secondary_crops,
    )
    
    # Create metadata
    crud.create_registration_metadata(
        db,
        user_id=user_profile.id,
        registration_method=session.get("registration_method", "email"),
        referrer=session.get("referrer"),
    )
    
    # Update status
    crud.update_user_profile_status(db, user_profile.id, RegistrationStatus.COMPLETED)
    
    # Clean up session
    cleanup_session(request.registration_id)
    
    # Generate tokens (integrate with auth service)
    access_token = "dummy_access_token"  # TODO: Call auth service
    refresh_token = "dummy_refresh_token"
    
    return RegistrationCompleteResponse(
        success=True,
        user_id=user_profile.id,
        role=user_profile.role,
        email=user_profile.email,
        mobile=user_profile.mobile,
        profile_type="farmer",
        access_token=access_token,
        refresh_token=refresh_token,
        next_steps=["complete_kyc", "setup_alerts"],
    )


@router.post("/partner/complete", response_model=RegistrationCompleteResponse)
async def complete_partner_registration(
    request: PartnerRegistrationRequest,
    db: Session = Depends(get_db),
) -> RegistrationCompleteResponse:
    """Complete partner registration."""
    session = get_session(request.registration_id)
    if not session:
        raise HTTPException(status_code=400, detail="Invalid registration session")
    
    # Check for duplicate email/mobile/tax_id
    if crud.get_user_profile_by_email(db, request.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    if crud.get_user_profile_by_mobile(db, request.mobile):
        raise HTTPException(status_code=400, detail="Mobile already registered")
    if crud.get_partner_by_tax_id(db, request.partner_data.tax_id):
        raise HTTPException(status_code=400, detail="Tax ID already registered")
    
    # Create user profile
    user_profile = crud.create_user_profile(
        db,
        role=UserRole.PARTNER,
        name=request.name,
        email=request.email,
        mobile=request.mobile,
        address=request.address.address,
        city=request.address.city,
        state=request.address.state,
        postal_code=request.address.postal_code,
        country=request.address.country,
        latitude=request.location.latitude,
        longitude=request.location.longitude,
        language_preference=request.preferences.language_preference,
    )
    
    # Create partner profile
    crud.create_partner_profile(
        db,
        user_id=user_profile.id,
        company_name=request.partner_data.company_name,
        business_type=request.partner_data.business_type,
        registration_number=request.partner_data.registration_number,
        tax_id=request.partner_data.tax_id,
        contact_person=request.partner_data.contact_person,
        service_area=request.partner_data.service_area,
        website=request.partner_data.website,
        certifications=request.partner_data.certifications,
    )
    
    # Create metadata
    crud.create_registration_metadata(
        db,
        user_id=user_profile.id,
        registration_method=session.get("registration_method", "email"),
        referrer=session.get("referrer"),
    )
    
    # Update status
    crud.update_user_profile_status(db, user_profile.id, RegistrationStatus.COMPLETED)
    
    # Clean up session
    cleanup_session(request.registration_id)
    
    # Generate tokens
    access_token = "dummy_access_token"
    refresh_token = "dummy_refresh_token"
    
    return RegistrationCompleteResponse(
        success=True,
        user_id=user_profile.id,
        role=user_profile.role,
        email=user_profile.email,
        mobile=user_profile.mobile,
        profile_type="partner",
        access_token=access_token,
        refresh_token=refresh_token,
        next_steps=["business_verification", "service_area_setup"],
    )


@router.post("/customer/complete", response_model=RegistrationCompleteResponse)
async def complete_customer_registration(
    request: CustomerRegistrationRequest,
    db: Session = Depends(get_db),
) -> RegistrationCompleteResponse:
    """Complete customer registration."""
    session = get_session(request.registration_id)
    if not session:
        raise HTTPException(status_code=400, detail="Invalid registration session")
    
    # Check for duplicate
    if crud.get_user_profile_by_email(db, request.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    if crud.get_user_profile_by_mobile(db, request.mobile):
        raise HTTPException(status_code=400, detail="Mobile already registered")
    
    # Create user profile
    user_profile = crud.create_user_profile(
        db,
        role=UserRole.CUSTOMER,
        name=request.name,
        email=request.email,
        mobile=request.mobile,
        address=request.address.address if request.address else "",
        city=request.address.city if request.address else "",
        state=request.address.state if request.address else "",
        postal_code=request.address.postal_code if request.address else "",
        country=request.address.country if request.address else "India",
        latitude=request.location.latitude if request.location else 0.0,
        longitude=request.location.longitude if request.location else 0.0,
        language_preference=request.preferences.language_preference,
    )
    
    # Create customer profile
    crud.create_customer_profile(
        db,
        user_id=user_profile.id,
        interests=request.customer_data.interests,
        use_case=request.customer_data.use_case,
        preferred_contact=request.customer_data.preferred_contact,
        organization=request.customer_data.organization,
        budget_range=request.customer_data.budget_range,
    )
    
    # Create metadata
    crud.create_registration_metadata(
        db,
        user_id=user_profile.id,
        registration_method=session.get("registration_method", "email"),
        referrer=session.get("referrer"),
    )
    
    # Update status
    crud.update_user_profile_status(db, user_profile.id, RegistrationStatus.COMPLETED)
    
    # Clean up session
    cleanup_session(request.registration_id)
    
    # Generate tokens
    access_token = "dummy_access_token"
    refresh_token = "dummy_refresh_token"
    
    return RegistrationCompleteResponse(
        success=True,
        user_id=user_profile.id,
        role=user_profile.role,
        email=user_profile.email,
        mobile=user_profile.mobile,
        profile_type="customer",
        access_token=access_token,
        refresh_token=refresh_token,
        next_steps=["browse_marketplace", "create_wishlists"],
    )


# ============================================================================
# Profile Retrieval
# ============================================================================

@router.get("/profile/farmer/{user_id}", response_model=FarmerProfileResponse)
async def get_farmer_profile(
    user_id: int,
    db: Session = Depends(get_db),
) -> FarmerProfileResponse:
    """Get farmer profile."""
    user = crud.get_user_profile(db, user_id)
    if not user or user.role != UserRole.FARMER:
        raise HTTPException(status_code=404, detail="Farmer profile not found")
    
    farmer = crud.get_farmer_profile(db, user_id)
    if not farmer:
        raise HTTPException(status_code=404, detail="Farmer details not found")
    
    return FarmerProfileResponse(
        user_id=user.id,
        name=user.name,
        email=user.email,
        mobile=user.mobile,
        status=user.status,
        farm_size=farmer.farm_size,
        farm_size_unit=farmer.farm_size_unit,
        primary_crop=farmer.primary_crop,
        farm_type=farmer.farm_type,
        latitude=user.latitude,
        longitude=user.longitude,
        city=user.city,
        state=user.state,
        mobile_verified=user.mobile_verified_at is not None,
        email_verified=user.email_verified_at is not None,
        completed_at=user.updated_at if user.status == RegistrationStatus.COMPLETED else None,
    )


# ============================================================================
# Status Check
# ============================================================================

@router.get("/status/{registration_id}", response_model=RegistrationStatusResponse)
async def get_registration_status(
    registration_id: str,
) -> RegistrationStatusResponse:
    """Check registration status."""
    session = get_session(registration_id)
    if not session:
        raise HTTPException(status_code=404, detail="Registration session not found")
    
    progress = 25 if session.get("status") == "pending_verification" else 75
    
    return RegistrationStatusResponse(
        registration_id=registration_id,
        status=RegistrationStatus.PENDING,
        role=session.get("role"),
        email=session.get("contact") if session.get("registration_method") == "email" else None,
        mobile=session.get("contact") if session.get("registration_method") == "mobile" else None,
        completed=False,
        progress=progress,
        current_stage=session.get("status", "pending"),
    )


# ============================================================================
# Location Services
# ============================================================================

@router.post("/location/validate")
async def validate_location(
    latitude: float = Query(...),
    longitude: float = Query(...),
    accuracy: Optional[float] = Query(None),
) -> dict:
    """
    Validate GPS coordinates.
    
    Returns validation result and accuracy assessment.
    """
    location_service = get_location_service()
    
    is_valid, location_data, error = await location_service.validate_and_get_location(
        latitude=latitude,
        longitude=longitude,
        accuracy=accuracy,
        require_address=True,
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error)
    
    return {
        "valid": True,
        "coordinates": {
            "latitude": location_data.coordinates.latitude,
            "longitude": location_data.coordinates.longitude,
            "accuracy": location_data.coordinates.accuracy,
        },
        "address": {
            "street": location_data.address.street,
            "city": location_data.address.city,
            "state": location_data.address.state,
            "postal_code": location_data.address.postal_code,
            "country": location_data.address.country,
        },
        "source": location_data.source,
        "confidence": location_data.confidence,
    }


@router.post("/location/geocode")
async def geocode_location(
    city: str = Query(...),
    state: str = Query(...),
    country: str = Query(default="India"),
    street: Optional[str] = Query(None),
    postal_code: Optional[str] = Query(None),
) -> dict:
    """
    Geocode address to GPS coordinates.
    
    Converts address to latitude/longitude.
    """
    location_service = get_location_service()
    
    is_valid, location_data, error = await location_service.geocode_address(
        city=city,
        state=state,
        country=country,
        street=street,
        postal_code=postal_code,
    )
    
    if not is_valid:
        raise HTTPException(status_code=400, detail=error)
    
    return {
        "coordinates": {
            "latitude": location_data.coordinates.latitude,
            "longitude": location_data.coordinates.longitude,
        },
        "address": {
            "street": location_data.address.street,
            "city": location_data.address.city,
            "state": location_data.address.state,
            "postal_code": location_data.address.postal_code,
            "country": location_data.address.country,
        },
        "confidence": location_data.confidence,
    }


# ============================================================================
# Lookup Endpoints (for registration forms)
# ============================================================================

@router.get("/lookup/crops")
async def get_crops(
    search: Optional[str] = Query(None),
    limit: int = Query(default=50, ge=1, le=100),
) -> dict:
    """
    Get list of crops.
    
    Optionally search/filter by name.
    """
    if search:
        crops = init_db.search_crops(search, limit=limit)
    else:
        crops = init_db.get_primary_crops()[:limit]
    
    return {
        "total": len(init_db.PRIMARY_CROPS),
        "returned": len(crops),
        "crops": crops,
    }


@router.get("/lookup/states")
async def get_states() -> dict:
    """Get list of Indian states."""
    states = init_db.get_states()
    return {
        "total": len(states),
        "states": states,
    }


@router.get("/lookup/cities")
async def get_cities(
    state: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    limit: int = Query(default=20, ge=1, le=100),
) -> dict:
    """
    Get list of cities.
    
    Optionally filter by state or search by name.
    """
    if search:
        cities = init_db.search_cities(search, state=state, limit=limit)
    elif state:
        cities = init_db.get_cities_for_state(state)
    else:
        cities = init_db.get_all_cities()[:limit]
    
    return {
        "state": state,
        "total": len(cities),
        "returned": len(cities),
        "cities": cities,
    }


@router.get("/lookup/irrigation-types")
async def get_irrigation_types() -> dict:
    """Get list of irrigation types."""
    types = init_db.get_irrigation_types()
    return {
        "total": len(types),
        "types": types,
    }


@router.get("/lookup/farm-types")
async def get_farm_types() -> dict:
    """Get list of farm types."""
    types = init_db.get_farm_types()
    return {
        "total": len(types),
        "types": types,
    }


@router.get("/lookup/business-types")
async def get_business_types() -> dict:
    """Get list of partner business types."""
    types = init_db.get_partner_business_types()
    return {
        "total": len(types),
        "types": types,
    }


@router.get("/lookup/statistics")
async def get_data_statistics() -> dict:
    """Get statistics about seed data."""
    return init_db.get_statistics()
