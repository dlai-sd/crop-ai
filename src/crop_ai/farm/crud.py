"""
Farm CRUD Operations
Database operations for farm management
"""

from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, timedelta
from typing import List, Optional

from .models import Farm, CropStage, WeatherForecast, SoilHealth, CropStageEnum, CropTypeEnum
from .schemas import FarmCreate, FarmUpdate, CropTypeEnum as SchemaCropTypeEnum


# ============================================================================
# FARM CRUD OPERATIONS
# ============================================================================

def get_farm(db: Session, farm_id: int) -> Optional[Farm]:
    """Get a single farm by ID"""
    return db.query(Farm).filter(Farm.id == farm_id).first()


def get_farm_by_user_and_id(db: Session, user_id: int, farm_id: int) -> Optional[Farm]:
    """Get a farm, ensuring it belongs to the user"""
    return db.query(Farm).filter(
        and_(Farm.id == farm_id, Farm.user_id == user_id)
    ).first()


def get_farmer_farms(db: Session, user_id: int) -> List[Farm]:
    """Get all farms for a farmer"""
    return db.query(Farm).filter(Farm.user_id == user_id).order_by(Farm.created_at.desc()).all()


def create_farm(db: Session, user_id: int, farm_data: FarmCreate) -> Farm:
    """Create a new farm for a farmer"""
    db_farm = Farm(
        user_id=user_id,
        name=farm_data.name,
        location=farm_data.location,
        area=farm_data.area,
        farm_type=farm_data.farm_type,
        soil_type=farm_data.soil_type,
        current_crop=farm_data.current_crop,
        primary_crop=farm_data.primary_crop,
        soil_health_score=farm_data.soil_health_score,
        moisture_level=farm_data.moisture_level,
        ph_level=farm_data.ph_level,
    )
    db.add(db_farm)
    db.commit()
    db.refresh(db_farm)
    return db_farm


def update_farm(db: Session, farm_id: int, farm_data: FarmUpdate) -> Optional[Farm]:
    """Update an existing farm"""
    db_farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not db_farm:
        return None

    # Update only provided fields
    update_data = farm_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_farm, field, value)
    
    db_farm.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_farm)
    return db_farm


def delete_farm(db: Session, farm_id: int) -> bool:
    """Delete a farm"""
    db_farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not db_farm:
        return False
    db.delete(db_farm)
    db.commit()
    return True


def update_farm_growth_stage(db: Session, farm_id: int, new_stage: CropStageEnum) -> Optional[Farm]:
    """Update the growth stage of a farm's crop"""
    db_farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not db_farm:
        return None
    
    db_farm.growth_stage = new_stage
    db_farm.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(db_farm)
    return db_farm


def mark_farm_synced(db: Session, farm_id: int) -> Optional[Farm]:
    """Mark farm as synced (clear pending changes flag)"""
    db_farm = db.query(Farm).filter(Farm.id == farm_id).first()
    if not db_farm:
        return None
    
    db_farm.last_sync = datetime.utcnow()
    db_farm.offline_changes_pending = False
    db.commit()
    db.refresh(db_farm)
    return db_farm


# ============================================================================
# CROP STAGE CRUD OPERATIONS
# ============================================================================

def get_farm_current_stage(db: Session, farm_id: int) -> Optional[CropStage]:
    """Get the current growth stage for a farm"""
    return db.query(CropStage).filter(CropStage.farm_id == farm_id).order_by(
        CropStage.started_on.desc()
    ).first()


def create_crop_stage(db: Session, farm_id: int, stage: CropStageEnum, notes: str = None) -> CropStage:
    """Create a new crop stage record"""
    db_stage = CropStage(
        farm_id=farm_id,
        stage=stage,
        started_on=datetime.utcnow(),
        notes=notes
    )
    db.add(db_stage)
    db.commit()
    db.refresh(db_stage)
    return db_stage


# ============================================================================
# WEATHER CRUD OPERATIONS
# ============================================================================

def get_farm_weather_forecast(db: Session, farm_id: int, days: int = 7) -> List[WeatherForecast]:
    """Get N-day weather forecast for a farm"""
    today = datetime.utcnow().date()
    future_date = today + timedelta(days=days)
    
    return db.query(WeatherForecast).filter(
        and_(
            WeatherForecast.farm_id == farm_id,
            WeatherForecast.forecast_date >= today,
            WeatherForecast.forecast_date <= future_date
        )
    ).order_by(WeatherForecast.forecast_date).all()


def create_weather_forecast(
    db: Session,
    farm_id: int,
    forecast_date: datetime,
    condition: str,
    temperature_high: float,
    temperature_low: float,
    rainfall_mm: float = 0.0,
    humidity: float = None,
    wind_speed_kmh: float = None,
    uv_index: float = None,
    description: str = None
) -> WeatherForecast:
    """Create a weather forecast record"""
    db_forecast = WeatherForecast(
        farm_id=farm_id,
        forecast_date=forecast_date,
        condition=condition,
        temperature_high=temperature_high,
        temperature_low=temperature_low,
        rainfall_mm=rainfall_mm,
        humidity=humidity,
        wind_speed_kmh=wind_speed_kmh,
        uv_index=uv_index,
        description=description,
        source="openweathermap"
    )
    db.add(db_forecast)
    db.commit()
    db.refresh(db_forecast)
    return db_forecast


def clear_farm_weather_forecast(db: Session, farm_id: int):
    """Clear old weather forecasts for a farm"""
    today = datetime.utcnow().date()
    db.query(WeatherForecast).filter(
        and_(
            WeatherForecast.farm_id == farm_id,
            WeatherForecast.forecast_date < today
        )
    ).delete()
    db.commit()


# ============================================================================
# SOIL HEALTH CRUD OPERATIONS
# ============================================================================

def get_farm_latest_soil_health(db: Session, farm_id: int) -> Optional[SoilHealth]:
    """Get the latest soil health measurement"""
    return db.query(SoilHealth).filter(SoilHealth.farm_id == farm_id).order_by(
        SoilHealth.measurement_date.desc()
    ).first()


def get_farm_soil_health_history(db: Session, farm_id: int, days: int = 30) -> List[SoilHealth]:
    """Get soil health history for past N days"""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    return db.query(SoilHealth).filter(
        and_(
            SoilHealth.farm_id == farm_id,
            SoilHealth.measurement_date >= cutoff_date
        )
    ).order_by(SoilHealth.measurement_date.desc()).all()


def create_soil_health_record(
    db: Session,
    farm_id: int,
    moisture_level: float = None,
    ph_level: float = None,
    nitrogen: float = None,
    phosphorus: float = None,
    potassium: float = None,
    organic_matter: float = None,
    health_score: float = None,
    recommendations: str = None,
    source: str = "manual"
) -> SoilHealth:
    """Create a soil health measurement record"""
    db_soil = SoilHealth(
        farm_id=farm_id,
        measurement_date=datetime.utcnow(),
        moisture_level=moisture_level,
        ph_level=ph_level,
        nitrogen=nitrogen,
        phosphorus=phosphorus,
        potassium=potassium,
        organic_matter=organic_matter,
        health_score=health_score,
        recommendations=recommendations,
        source=source
    )
    db.add(db_soil)
    db.commit()
    db.refresh(db_soil)
    return db_soil


# ============================================================================
# ANALYTICS & REPORTING
# ============================================================================

def get_farmer_statistics(db: Session, user_id: int) -> dict:
    """Get statistics for a farmer"""
    farms = db.query(Farm).filter(Farm.user_id == user_id).all()
    
    if not farms:
        return {
            "total_farms": 0,
            "total_area": 0.0,
            "crops": {},
            "avg_soil_health": 0.0
        }
    
    # Calculate statistics
    total_farms = len(farms)
    total_area = sum(f.area or 0 for f in farms)
    
    # Crop distribution
    crops = {}
    for farm in farms:
        crop = farm.current_crop.value
        crops[crop] = crops.get(crop, 0) + 1
    
    # Average soil health
    avg_soil_health = sum(f.soil_health_score or 0 for f in farms) / total_farms if total_farms > 0 else 0
    
    return {
        "total_farms": total_farms,
        "total_area": total_area,
        "crops": crops,
        "avg_soil_health": round(avg_soil_health, 2)
    }


def get_farms_needing_attention(db: Session, user_id: int) -> List[dict]:
    """Get farms that need attention (low soil health, critical stage, etc)"""
    farms = db.query(Farm).filter(Farm.user_id == user_id).all()
    
    critical_farms = []
    for farm in farms:
        alerts = []
        
        # Check soil health
        if farm.soil_health_score < 40:
            alerts.append(f"Low soil health: {farm.soil_health_score}")
        
        # Check moisture
        if farm.moisture_level and farm.moisture_level < 20:
            alerts.append("Low soil moisture")
        elif farm.moisture_level and farm.moisture_level > 80:
            alerts.append("High soil moisture (waterlogging risk)")
        
        # Check growth stage
        if farm.growth_stage in [CropStageEnum.FLOWERING, CropStageEnum.MATURITY]:
            alerts.append("Critical growth stage - monitor closely")
        
        # Check offline changes
        if farm.offline_changes_pending:
            alerts.append("Pending offline changes to sync")
        
        if alerts:
            critical_farms.append({
                "farm_id": farm.id,
                "farm_name": farm.name,
                "alerts": alerts
            })
    
    return critical_farms
