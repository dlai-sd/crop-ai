"""
Farm API Routes
RESTful endpoints for farm management, weather, and soil health
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime

from .models import Farm
from .schemas import (
    FarmCreate, FarmUpdate, FarmListResponse, FarmDetailsResponse,
    WeatherForecastListResponse, WeatherForecastResponse,
    SoilHealthResponse, SoilHealthLatestResponse,
    FarmDashboardResponse, FarmerDashboardResponse,
    CropStageResponse, ErrorResponse
)
from . import crud

# Router configuration
router = APIRouter(
    prefix="/api/farm",
    tags=["farm"],
    responses={404: {"description": "Farm not found"}}
)

# Mock database session getter (replace with your actual DB session)
def get_db() -> Session:
    """Database session dependency"""
    # TODO: Implement with your database connection
    # from src.crop_ai.database import SessionLocal
    # db = SessionLocal()
    # try:
    #     yield db
    # finally:
    #     db.close()
    pass


# ============================================================================
# FARM LIST & DETAILS ENDPOINTS
# ============================================================================

@router.get(
    "/farmer/farms",
    response_model=FarmerDashboardResponse,
    summary="Get all farms for current farmer",
    description="Returns list of all farms belonging to the authenticated farmer with basic info"
)
async def get_farmer_farms(
    user_id: int = None,  # In production, extract from JWT token
    db: Session = Depends(get_db)
):
    """
    Get all farms for the authenticated farmer.
    
    Returns:
        - farms: List of farms with minimal info
        - total_farms: Count of farms
        - total_area: Sum of all farm areas
        - critical_alerts: Farms needing attention
        - last_sync: Last sync timestamp
    
    Raises:
        404: Farmer not found
        401: Unauthorized
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farms = crud.get_farmer_farms(db, user_id)
    if not farms:
        # Return empty dashboard
        return FarmerDashboardResponse(
            user_id=user_id,
            farms=[],
            total_farms=0,
            total_area=0.0,
            critical_alerts=[],
            last_sync=datetime.utcnow()
        )
    
    # Get critical alerts
    critical = crud.get_farms_needing_attention(db, user_id)
    alerts = [f"{f['farm_name']}: {', '.join(f['alerts'])}" for f in critical]
    
    # Convert farms to response schema
    farm_responses = [FarmListResponse.from_orm(farm) for farm in farms]
    
    # Calculate totals
    total_area = sum(farm.area or 0 for farm in farms)
    
    return FarmerDashboardResponse(
        user_id=user_id,
        farms=farm_responses,
        total_farms=len(farms),
        total_area=total_area,
        critical_alerts=alerts,
        last_sync=datetime.utcnow()
    )


@router.get(
    "/{farm_id}",
    response_model=FarmDetailsResponse,
    summary="Get farm details",
    description="Get detailed information about a specific farm"
)
async def get_farm(
    farm_id: int,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Get detailed information about a farm.
    
    Parameters:
        farm_id: Farm ID
        
    Returns:
        Farm details including growth stage, soil health, last sync time
        
    Raises:
        404: Farm not found
        403: Unauthorized (farm belongs to another farmer)
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farm = crud.get_farm_by_user_and_id(db, user_id, farm_id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    return FarmDetailsResponse.from_orm(farm)


@router.post(
    "/",
    response_model=FarmDetailsResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create new farm",
    description="Create a new farm for the authenticated farmer"
)
async def create_farm(
    farm_data: FarmCreate,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Create a new farm.
    
    Request body:
        - name: Farm name (required)
        - location: GPS or location name (optional)
        - area: Farm size in acres (optional)
        - farm_type: irrigated, rainfed, mixed (optional)
        - soil_type: clay, sandy, loam, etc. (optional)
        - current_crop: Crop type (required)
        - primary_crop: Primary crop for this farm (required)
        
    Returns:
        Created farm with ID and timestamps
        
    Raises:
        400: Invalid request data
        401: Unauthorized
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farm = crud.create_farm(db, user_id, farm_data)
    return FarmDetailsResponse.from_orm(farm)


@router.put(
    "/{farm_id}",
    response_model=FarmDetailsResponse,
    summary="Update farm",
    description="Update farm information"
)
async def update_farm(
    farm_id: int,
    farm_data: FarmUpdate,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Update farm information.
    
    Supports partial updates (only send fields to change).
    
    Raises:
        404: Farm not found
        403: Unauthorized
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farm = crud.get_farm_by_user_and_id(db, user_id, farm_id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    farm = crud.update_farm(db, farm_id, farm_data)
    return FarmDetailsResponse.from_orm(farm)


# ============================================================================
# WEATHER ENDPOINTS
# ============================================================================

@router.get(
    "/{farm_id}/weather",
    response_model=WeatherForecastListResponse,
    summary="Get weather forecast",
    description="Get 7-day weather forecast for a farm"
)
async def get_farm_weather(
    farm_id: int,
    days: int = 7,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Get weather forecast for a farm.
    
    Parameters:
        farm_id: Farm ID
        days: Number of days to forecast (default 7, max 14)
        
    Returns:
        List of daily forecasts with temperature, rainfall, UV index, etc.
        
    Raises:
        404: Farm not found
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    if days > 14:
        days = 14  # Cap at 14 days
    
    farm = crud.get_farm_by_user_and_id(db, user_id, farm_id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    forecasts = crud.get_farm_weather_forecast(db, farm_id, days)
    
    if not forecasts:
        # No forecast data - return empty list
        return WeatherForecastListResponse(
            farm_id=farm_id,
            forecasts=[],
            generated_at=datetime.utcnow(),
            location=farm.location or "Unknown"
        )
    
    forecast_responses = [WeatherForecastResponse.from_orm(f) for f in forecasts]
    
    return WeatherForecastListResponse(
        farm_id=farm_id,
        forecasts=forecast_responses,
        generated_at=datetime.utcnow(),
        location=farm.location or "Unknown"
    )


# ============================================================================
# SOIL HEALTH ENDPOINTS
# ============================================================================

@router.get(
    "/{farm_id}/soil-health",
    response_model=SoilHealthLatestResponse,
    summary="Get soil health",
    description="Get latest soil health measurement for a farm"
)
async def get_farm_soil_health(
    farm_id: int,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Get latest soil health data.
    
    Returns:
        - latest_measurement: Most recent soil health measurement
        - trend: Whether soil health is improving, stable, or declining
        
    Raises:
        404: Farm not found
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farm = crud.get_farm_by_user_and_id(db, user_id, farm_id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    latest = crud.get_farm_latest_soil_health(db, farm_id)
    history = crud.get_farm_soil_health_history(db, farm_id, days=30)
    
    # Determine trend
    trend = None
    if latest and len(history) > 1:
        if history[1].health_score and latest.health_score:
            if latest.health_score > history[1].health_score:
                trend = "improving"
            elif latest.health_score < history[1].health_score:
                trend = "declining"
            else:
                trend = "stable"
    
    return SoilHealthLatestResponse(
        farm_id=farm_id,
        latest_measurement=SoilHealthResponse.from_orm(latest) if latest else None,
        trend=trend
    )


# ============================================================================
# CROP STAGE ENDPOINTS
# ============================================================================

@router.get(
    "/{farm_id}/crop-stage",
    response_model=CropStageResponse,
    summary="Get current crop stage",
    description="Get current growth stage for a farm's crop"
)
async def get_farm_crop_stage(
    farm_id: int,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Get the current growth stage.
    
    Returns:
        - stage: Current growth stage (seedling, growth, flowering, etc.)
        - started_on: When this stage began
        - progress_percent: Estimated progress through this stage
        - expected_duration: Days until next stage
        
    Raises:
        404: Farm not found or no stage recorded yet
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farm = crud.get_farm_by_user_and_id(db, user_id, farm_id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    stage = crud.get_farm_current_stage(db, farm_id)
    if not stage:
        raise HTTPException(status_code=404, detail="No crop stage recorded")
    
    return CropStageResponse.from_orm(stage)


# ============================================================================
# DASHBOARD ENDPOINT
# ============================================================================

@router.get(
    "/{farm_id}/dashboard",
    response_model=FarmDashboardResponse,
    summary="Get farm dashboard",
    description="Get complete dashboard with farm, weather, soil health, and recommendations"
)
async def get_farm_dashboard(
    farm_id: int,
    user_id: int = None,
    db: Session = Depends(get_db)
):
    """
    Get complete farm dashboard with all related data.
    
    Returns:
        - farm: Farm details
        - current_stage: Growth stage info
        - weather_forecast: 7-day forecast
        - soil_health: Latest soil health + trend
        - next_action: AI-recommended action based on current conditions
        
    Raises:
        404: Farm not found
    """
    if not user_id:
        raise HTTPException(status_code=401, detail="User not authenticated")
    
    farm = crud.get_farm_by_user_and_id(db, user_id, farm_id)
    if not farm:
        raise HTTPException(status_code=404, detail="Farm not found")
    
    # Gather all data
    farm_response = FarmDetailsResponse.from_orm(farm)
    stage = crud.get_farm_current_stage(db, farm_id)
    weather = crud.get_farm_weather_forecast(db, farm_id)
    soil_health = crud.get_farm_latest_soil_health(db, farm_id)
    
    # Convert to response models
    stage_response = CropStageResponse.from_orm(stage) if stage else None
    weather_responses = [WeatherForecastResponse.from_orm(w) for w in weather]
    
    # Soil health with trend
    soil_history = crud.get_farm_soil_health_history(db, farm_id, days=30)
    trend = None
    if soil_health and len(soil_history) > 1:
        if soil_history[1].health_score and soil_health.health_score:
            if soil_health.health_score > soil_history[1].health_score:
                trend = "improving"
            elif soil_health.health_score < soil_history[1].health_score:
                trend = "declining"
            else:
                trend = "stable"
    
    soil_health_response = SoilHealthLatestResponse(
        farm_id=farm_id,
        latest_measurement=SoilHealthResponse.from_orm(soil_health) if soil_health else None,
        trend=trend
    )
    
    # Generate next action (simple logic, can be enhanced with AI)
    next_action = None
    if soil_health and soil_health.health_score < 40:
        next_action = "⚠️ Urgent: Improve soil health - consider adding organic matter"
    elif farm.moisture_level and farm.moisture_level < 20:
        next_action = "💧 Water your field - soil moisture is low"
    elif stage and stage.progress_percent > 80:
        next_action = "🌾 Prepare for harvest - crop is nearly mature"
    
    return FarmDashboardResponse(
        farm=farm_response,
        current_stage=stage_response,
        weather_forecast=weather_responses,
        soil_health=soil_health_response,
        next_action=next_action
    )


# ============================================================================
# HEALTH CHECK
# ============================================================================

@router.get(
    "/health",
    summary="Health check",
    description="Check if farm service is running"
)
async def health():
    """Health check endpoint"""
    return {
        "status": "ok",
        "service": "farm",
        "timestamp": datetime.utcnow()
    }
