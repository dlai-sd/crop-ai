"""
Farm Management Data Models
SQLAlchemy ORM models for farms, crops, and related data

Database Tables:
- farms: Store farmer's farms/fields
- crop_stages: Growth stages (seedling, growth, maturity, harvest)
- weather_forecasts: 7-day weather data
- soil_health: Soil metrics (moisture, pH, nutrients)
"""

from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, Enum, ForeignKey, Text
from sqlalchemy.orm import declarative_base, relationship
from datetime import datetime
import enum

Base = declarative_base()


class CropStageEnum(str, enum.Enum):
    """Crop growth stages"""
    SEEDLING = "seedling"      # 0-30 days
    GROWTH = "growth"          # 30-60 days
    FLOWERING = "flowering"    # 60-90 days
    MATURITY = "maturity"      # 90-120 days
    HARVEST = "harvest"        # Ready to harvest
    FALLOW = "fallow"          # Field is empty


class CropTypeEnum(str, enum.Enum):
    """Supported crop types (extensible for modularity)"""
    CORN = "corn"
    WHEAT = "wheat"
    SUGARCANE = "sugarcane"
    RICE = "rice"
    COTTON = "cotton"
    SOY = "soy"
    POTATO = "potato"
    OTHER = "other"


class FarmTypeEnum(str, enum.Enum):
    """Farm/field types"""
    IRRIGATED = "irrigated"
    RAINFED = "rainfed"
    MIXED = "mixed"


class Farm(Base):
    """
    Represents a farmer's farm/field
    
    Attributes:
        id: Primary key
        user_id: Foreign key to User
        name: Farm/field name
        location: GPS coordinates or description
        area: Farm size in acres/hectares
        farm_type: Irrigated, rainfed, etc.
        soil_type: Clay, sandy, loam, etc.
        current_crop: Crop name
        primary_crop: Main crop for this farm
        growth_stage: Current stage (seedling, growth, etc.)
        soil_health_score: 0-100 score
        last_sync: Last sync timestamp (for offline tracking)
        created_at: When farm was added
        updated_at: Last update timestamp
    """
    __tablename__ = "farms"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    
    # Farm basic info
    name = Column(String(255), nullable=False)
    location = Column(String(255))  # "lat,lng" or location name
    area = Column(Float)  # in acres/hectares
    farm_type = Column(Enum(FarmTypeEnum), default=FarmTypeEnum.MIXED)
    soil_type = Column(String(100))  # clay, sandy, loam, etc.
    
    # Current crop info
    current_crop = Column(Enum(CropTypeEnum), nullable=False)
    primary_crop = Column(Enum(CropTypeEnum), nullable=False)
    growth_stage = Column(Enum(CropStageEnum), default=CropStageEnum.SEEDLING, index=True)
    
    # Health metrics
    soil_health_score = Column(Float, default=50.0)  # 0-100
    moisture_level = Column(Float)  # 0-100%
    ph_level = Column(Float)  # 0-14
    
    # Sync tracking
    last_sync = Column(DateTime, default=datetime.utcnow)
    offline_changes_pending = Column(Boolean, default=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    crop_stages = relationship(
        "CropStage",
        back_populates="farm",
        cascade="all, delete-orphan",
        lazy="joined"
    )
    weather_forecasts = relationship(
        "WeatherForecast",
        back_populates="farm",
        cascade="all, delete-orphan"
    )
    soil_health_records = relationship(
        "SoilHealth",
        back_populates="farm",
        cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<Farm(id={self.id}, name={self.name}, user_id={self.user_id}, crop={self.current_crop})>"


class CropStage(Base):
    """
    Tracks crop growth stage timeline
    
    Attributes:
        id: Primary key
        farm_id: Farm this stage belongs to
        stage: Growth stage (seedling, growth, etc.)
        started_on: Date stage began
        expected_duration: Days until next stage
        progress_percent: 0-100% through this stage
    """
    __tablename__ = "crop_stages"

    id = Column(Integer, primary_key=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False, index=True)
    
    stage = Column(Enum(CropStageEnum), nullable=False)
    started_on = Column(DateTime, default=datetime.utcnow)
    expected_duration = Column(Integer)  # days
    progress_percent = Column(Float, default=0.0)  # 0-100
    
    notes = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    farm = relationship("Farm", back_populates="crop_stages")

    def __repr__(self):
        return f"<CropStage(farm_id={self.farm_id}, stage={self.stage}, progress={self.progress_percent}%)>"


class WeatherForecast(Base):
    """
    7-day weather forecast for a farm
    
    Attributes:
        id: Primary key
        farm_id: Farm location
        forecast_date: Date of forecast
        temperature_high: Celsius
        temperature_low: Celsius
        humidity: 0-100%
        rainfall_mm: Expected rainfall
        wind_speed_kmh: Wind speed
        uv_index: Sun intensity
        condition: sunny, rainy, cloudy, etc.
    """
    __tablename__ = "weather_forecasts"

    id = Column(Integer, primary_key=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False, index=True)
    
    forecast_date = Column(DateTime, nullable=False, index=True)
    
    # Temperature
    temperature_high = Column(Float)  # Celsius
    temperature_low = Column(Float)
    
    # Precipitation & Humidity
    humidity = Column(Float)  # 0-100%
    rainfall_mm = Column(Float, default=0.0)
    
    # Wind & Sun
    wind_speed_kmh = Column(Float)
    wind_direction = Column(String(10))  # N, NE, E, etc.
    uv_index = Column(Float)  # 0-11+
    
    # Condition
    condition = Column(String(50))  # sunny, rainy, cloudy, etc.
    description = Column(Text)
    
    # Metadata
    source = Column(String(50), default="openweathermap")  # Weather API source
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    farm = relationship("Farm", back_populates="weather_forecasts")

    def __repr__(self):
        return f"<WeatherForecast(farm_id={self.farm_id}, date={self.forecast_date}, condition={self.condition})>"


class SoilHealth(Base):
    """
    Soil health measurements over time
    
    Attributes:
        id: Primary key
        farm_id: Farm this measurement belongs to
        measurement_date: When measurement was taken
        moisture_level: 0-100%
        ph_level: 0-14
        nitrogen: ppm
        phosphorus: ppm
        potassium: ppm
        organic_matter: %
        ec_level: Electrical conductivity
    """
    __tablename__ = "soil_health"

    id = Column(Integer, primary_key=True)
    farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False, index=True)
    
    measurement_date = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Physical properties
    moisture_level = Column(Float)  # 0-100%
    temperature = Column(Float)  # Celsius
    
    # Chemical properties
    ph_level = Column(Float)  # 0-14
    ec_level = Column(Float)  # Electrical conductivity
    
    # Nutrients (ppm - parts per million)
    nitrogen = Column(Float)
    phosphorus = Column(Float)
    potassium = Column(Float)
    
    # Organic matter
    organic_matter = Column(Float)  # %
    
    # Assessment
    health_score = Column(Float)  # 0-100
    recommendations = Column(Text)
    
    # Source
    source = Column(String(50))  # sensor, manual, lab, etc.
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    farm = relationship("Farm", back_populates="soil_health_records")

    def __repr__(self):
        return f"<SoilHealth(farm_id={self.farm_id}, date={self.measurement_date}, score={self.health_score})>"
