"""
Farm API Request/Response Schemas
Pydantic validation models for API contracts
"""

from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from enum import Enum
from typing import List, Optional


# ============================================================================
# ENUMS (matching models.py)
# ============================================================================

class CropStageEnum(str, Enum):
    SEEDLING = "seedling"
    GROWTH = "growth"
    FLOWERING = "flowering"
    MATURITY = "maturity"
    HARVEST = "harvest"
    FALLOW = "fallow"


class CropTypeEnum(str, Enum):
    CORN = "corn"
    WHEAT = "wheat"
    SUGARCANE = "sugarcane"
    RICE = "rice"
    COTTON = "cotton"
    SOY = "soy"
    POTATO = "potato"
    OTHER = "other"


class FarmTypeEnum(str, Enum):
    IRRIGATED = "irrigated"
    RAINFED = "rainfed"
    MIXED = "mixed"


# ============================================================================
# FARM SCHEMAS
# ============================================================================

class FarmBase(BaseModel):
    """Base farm schema with common fields"""
    name: str = Field(..., min_length=1, max_length=255)
    location: Optional[str] = Field(None, max_length=255)
    area: Optional[float] = Field(None, gt=0)
    farm_type: FarmTypeEnum = FarmTypeEnum.MIXED
    soil_type: Optional[str] = Field(None, max_length=100)
    current_crop: CropTypeEnum
    primary_crop: CropTypeEnum
    soil_health_score: float = Field(default=50.0, ge=0, le=100)
    moisture_level: Optional[float] = Field(None, ge=0, le=100)
    ph_level: Optional[float] = Field(None, ge=0, le=14)


class FarmCreate(FarmBase):
    """Request schema for creating a farm"""
    pass


class FarmUpdate(BaseModel):
    """Request schema for updating a farm"""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    location: Optional[str] = None
    area: Optional[float] = Field(None, gt=0)
    farm_type: Optional[FarmTypeEnum] = None
    soil_type: Optional[str] = None
    growth_stage: Optional[CropStageEnum] = None
    soil_health_score: Optional[float] = Field(None, ge=0, le=100)
    moisture_level: Optional[float] = Field(None, ge=0, le=100)
    ph_level: Optional[float] = Field(None, ge=0, le=14)


class FarmListResponse(BaseModel):
    """Response schema for farm list (minimal info)"""
    id: int
    name: str
    location: Optional[str]
    current_crop: CropTypeEnum
    growth_stage: CropStageEnum
    soil_health_score: float
    offline_changes_pending: bool
    last_sync: datetime

    class Config:
        from_attributes = True


class FarmDetailsResponse(FarmBase):
    """Response schema for detailed farm info"""
    id: int
    user_id: int
    growth_stage: CropStageEnum
    offline_changes_pending: bool
    last_sync: datetime
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# CROP STAGE SCHEMAS
# ============================================================================

class CropStageResponse(BaseModel):
    """Response schema for crop stage info"""
    id: int
    farm_id: int
    stage: CropStageEnum
    started_on: datetime
    expected_duration: Optional[int]
    progress_percent: float
    notes: Optional[str]

    class Config:
        from_attributes = True


# ============================================================================
# WEATHER SCHEMAS
# ============================================================================

class WeatherForecastResponse(BaseModel):
    """Response schema for single day weather forecast"""
    id: int
    farm_id: int
    forecast_date: datetime
    temperature_high: Optional[float]
    temperature_low: Optional[float]
    humidity: Optional[float]
    rainfall_mm: float
    wind_speed_kmh: Optional[float]
    wind_direction: Optional[str]
    uv_index: Optional[float]
    condition: str
    description: Optional[str]

    class Config:
        from_attributes = True


class WeatherForecastListResponse(BaseModel):
    """Response schema for 7-day weather forecast"""
    farm_id: int
    forecasts: List[WeatherForecastResponse]
    generated_at: datetime
    location: str


# ============================================================================
# SOIL HEALTH SCHEMAS
# ============================================================================

class SoilHealthResponse(BaseModel):
    """Response schema for soil health measurement"""
    id: int
    farm_id: int
    measurement_date: datetime
    moisture_level: Optional[float]
    temperature: Optional[float]
    ph_level: Optional[float]
    ec_level: Optional[float]
    nitrogen: Optional[float]
    phosphorus: Optional[float]
    potassium: Optional[float]
    organic_matter: Optional[float]
    health_score: Optional[float]
    recommendations: Optional[str]
    source: str

    class Config:
        from_attributes = True


class SoilHealthLatestResponse(BaseModel):
    """Response schema for latest soil health data"""
    farm_id: int
    latest_measurement: Optional[SoilHealthResponse]
    trend: Optional[str]  # improving, stable, declining


# ============================================================================
# SYNC SCHEMAS (for offline mobile sync)
# ============================================================================

class SyncChange(BaseModel):
    """Represents a single change to sync"""
    field: str
    old_value: Optional[str]
    new_value: str
    timestamp: datetime


class FarmSyncRequest(BaseModel):
    """Request schema for syncing offline changes"""
    farm_id: int
    changes: List[SyncChange]
    sync_timestamp: datetime


class FarmSyncResponse(BaseModel):
    """Response schema for sync operation"""
    farm_id: int
    synced: bool
    changes_applied: int
    server_data: FarmDetailsResponse
    sync_timestamp: datetime


# ============================================================================
# COMPOSITE SCHEMAS (multiple related data)
# ============================================================================

class FarmDashboardResponse(BaseModel):
    """Complete dashboard for a single farm"""
    farm: FarmDetailsResponse
    current_stage: CropStageResponse
    weather_forecast: List[WeatherForecastResponse]
    soil_health: SoilHealthLatestResponse
    next_action: Optional[str]  # AI-recommended action


class FarmerDashboardResponse(BaseModel):
    """Dashboard showing all farms for a farmer"""
    user_id: int
    farms: List[FarmListResponse]
    total_farms: int
    total_area: float  # sum of all farm areas
    critical_alerts: List[str]  # farms needing attention
    last_sync: datetime


# ============================================================================
# ERROR SCHEMAS
# ============================================================================

class ErrorResponse(BaseModel):
    """Standard error response"""
    status: int
    error_code: str
    message: str
    details: Optional[dict] = None
