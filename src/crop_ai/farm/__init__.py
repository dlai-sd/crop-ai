"""
Farm Management Module
Handles farm monitoring, crop tracking, weather, and soil health data
"""

from .routes import router
from .models import Farm, CropStage, WeatherForecast, SoilHealth
from .schemas import (
    FarmCreate, FarmUpdate, FarmListResponse, FarmDetailsResponse,
    WeatherForecastResponse, SoilHealthResponse, FarmDashboardResponse
)
from . import crud

__all__ = [
    # Routes
    "router",
    # Models
    "Farm", "CropStage", "WeatherForecast", "SoilHealth",
    # Schemas
    "FarmCreate", "FarmUpdate", "FarmListResponse", "FarmDetailsResponse",
    "WeatherForecastResponse", "SoilHealthResponse", "FarmDashboardResponse",
    # CRUD
    "crud",
]
