"""
Farm API Tests
Unit and integration tests for farm endpoints
"""

import pytest
from datetime import datetime, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

from src.crop_ai.farm.models import Base, Farm, CropStage, WeatherForecast, SoilHealth
from src.crop_ai.farm.models import CropStageEnum, CropTypeEnum, FarmTypeEnum
from src.crop_ai.farm import crud
from src.crop_ai.farm.schemas import FarmCreate, FarmUpdate


# ============================================================================
# TEST DATABASE SETUP
# ============================================================================

@pytest.fixture(scope="session")
def test_db_engine():
    """Create in-memory SQLite database for tests"""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    return engine


@pytest.fixture(scope="function")
def db_session(test_db_engine):
    """Create a fresh database session for each test"""
    connection = test_db_engine.connect()
    transaction = connection.begin()
    session = sessionmaker(autocommit=False, autoflush=False, bind=connection)()
    
    yield session
    
    session.close()
    transaction.rollback()
    connection.close()


# ============================================================================
# FIXTURES: Sample Data
# ============================================================================

@pytest.fixture
def sample_farm(db_session):
    """Create a sample farm for testing"""
    farm = Farm(
        user_id=1,
        name="North Field",
        location="40.7128,-74.0060",
        area=50.0,
        farm_type=FarmTypeEnum.IRRIGATED,
        soil_type="loam",
        current_crop=CropTypeEnum.CORN,
        primary_crop=CropTypeEnum.CORN,
        growth_stage=CropStageEnum.GROWTH,
        soil_health_score=75.0,
        moisture_level=60.0,
        ph_level=6.8
    )
    db_session.add(farm)
    db_session.commit()
    db_session.refresh(farm)
    return farm


@pytest.fixture
def sample_farms(db_session):
    """Create multiple farms for testing list operations"""
    farms = [
        Farm(
            user_id=1,
            name="Field 1",
            area=30.0,
            farm_type=FarmTypeEnum.IRRIGATED,
            current_crop=CropTypeEnum.CORN,
            primary_crop=CropTypeEnum.CORN,
            soil_health_score=80.0
        ),
        Farm(
            user_id=1,
            name="Field 2",
            area=40.0,
            farm_type=FarmTypeEnum.RAINFED,
            current_crop=CropTypeEnum.WHEAT,
            primary_crop=CropTypeEnum.WHEAT,
            soil_health_score=65.0
        ),
        Farm(
            user_id=2,
            name="Field 3",
            area=25.0,
            farm_type=FarmTypeEnum.MIXED,
            current_crop=CropTypeEnum.SUGARCANE,
            primary_crop=CropTypeEnum.SUGARCANE,
            soil_health_score=70.0
        )
    ]
    db_session.add_all(farms)
    db_session.commit()
    for farm in farms:
        db_session.refresh(farm)
    return farms


# ============================================================================
# TESTS: FARM CRUD OPERATIONS
# ============================================================================

def test_create_farm(db_session):
    """Test creating a new farm"""
    farm_data = FarmCreate(
        name="Test Farm",
        area=50.0,
        current_crop=CropTypeEnum.CORN,
        primary_crop=CropTypeEnum.CORN,
        soil_health_score=75.0
    )
    
    farm = crud.create_farm(db_session, user_id=1, farm_data=farm_data)
    
    assert farm.id is not None
    assert farm.name == "Test Farm"
    assert farm.user_id == 1
    assert farm.area == 50.0
    assert farm.current_crop == CropTypeEnum.CORN


def test_get_farm(db_session, sample_farm):
    """Test retrieving a farm by ID"""
    farm = crud.get_farm(db_session, sample_farm.id)
    
    assert farm is not None
    assert farm.id == sample_farm.id
    assert farm.name == "North Field"


def test_get_farm_not_found(db_session):
    """Test retrieving non-existent farm"""
    farm = crud.get_farm(db_session, 999)
    assert farm is None


def test_get_farmer_farms(db_session, sample_farms):
    """Test retrieving all farms for a farmer"""
    farms = crud.get_farmer_farms(db_session, user_id=1)
    
    assert len(farms) == 2
    assert all(f.user_id == 1 for f in farms)


def test_get_farmer_farms_empty(db_session):
    """Test getting farms for farmer with no farms"""
    farms = crud.get_farmer_farms(db_session, user_id=999)
    assert farms == []


def test_update_farm(db_session, sample_farm):
    """Test updating a farm"""
    update_data = FarmUpdate(
        soil_health_score=85.0,
        growth_stage=CropStageEnum.MATURITY
    )
    
    updated_farm = crud.update_farm(db_session, sample_farm.id, update_data)
    
    assert updated_farm.soil_health_score == 85.0
    assert updated_farm.growth_stage == CropStageEnum.MATURITY


def test_delete_farm(db_session, sample_farm):
    """Test deleting a farm"""
    result = crud.delete_farm(db_session, sample_farm.id)
    assert result is True
    
    farm = crud.get_farm(db_session, sample_farm.id)
    assert farm is None


# ============================================================================
# TESTS: CROP STAGE OPERATIONS
# ============================================================================

def test_create_crop_stage(db_session, sample_farm):
    """Test creating a crop stage record"""
    stage = crud.create_crop_stage(
        db_session,
        farm_id=sample_farm.id,
        stage=CropStageEnum.GROWTH,
        notes="Healthy growth"
    )
    
    assert stage.id is not None
    assert stage.farm_id == sample_farm.id
    assert stage.stage == CropStageEnum.GROWTH
    assert stage.notes == "Healthy growth"


def test_get_farm_current_stage(db_session, sample_farm):
    """Test retrieving current crop stage"""
    # Create two stages
    stage1 = crud.create_crop_stage(db_session, sample_farm.id, CropStageEnum.SEEDLING)
    stage2 = crud.create_crop_stage(db_session, sample_farm.id, CropStageEnum.GROWTH)
    
    current = crud.get_farm_current_stage(db_session, sample_farm.id)
    
    # Should return the most recent
    assert current.id == stage2.id
    assert current.stage == CropStageEnum.GROWTH


# ============================================================================
# TESTS: WEATHER FORECAST OPERATIONS
# ============================================================================

def test_create_weather_forecast(db_session, sample_farm):
    """Test creating a weather forecast"""
    forecast_date = datetime.utcnow() + timedelta(days=1)
    
    forecast = crud.create_weather_forecast(
        db_session,
        farm_id=sample_farm.id,
        forecast_date=forecast_date,
        condition="sunny",
        temperature_high=28.0,
        temperature_low=18.0,
        rainfall_mm=0.0,
        humidity=60.0
    )
    
    assert forecast.id is not None
    assert forecast.farm_id == sample_farm.id
    assert forecast.condition == "sunny"
    assert forecast.temperature_high == 28.0


def test_get_farm_weather_forecast(db_session, sample_farm):
    """Test retrieving weather forecast"""
    # Create 3 forecasts for next 3 days
    today = datetime.utcnow()
    for i in range(1, 4):
        crud.create_weather_forecast(
            db_session,
            farm_id=sample_farm.id,
            forecast_date=today + timedelta(days=i),
            condition="sunny" if i < 3 else "rainy",
            temperature_high=28.0 - i,
            temperature_low=18.0 - i,
            rainfall_mm=0.0 if i < 3 else 10.0
        )
    
    forecasts = crud.get_farm_weather_forecast(db_session, sample_farm.id, days=3)
    
    assert len(forecasts) == 3
    assert forecasts[2].condition == "rainy"


# ============================================================================
# TESTS: SOIL HEALTH OPERATIONS
# ============================================================================

def test_create_soil_health_record(db_session, sample_farm):
    """Test creating a soil health measurement"""
    record = crud.create_soil_health_record(
        db_session,
        farm_id=sample_farm.id,
        moisture_level=65.0,
        ph_level=6.8,
        nitrogen=150.0,
        health_score=80.0,
        source="sensor"
    )
    
    assert record.id is not None
    assert record.farm_id == sample_farm.id
    assert record.moisture_level == 65.0
    assert record.health_score == 80.0


def test_get_farm_latest_soil_health(db_session, sample_farm):
    """Test retrieving latest soil health"""
    # Create multiple records
    record1 = crud.create_soil_health_record(
        db_session,
        farm_id=sample_farm.id,
        health_score=70.0
    )
    record2 = crud.create_soil_health_record(
        db_session,
        farm_id=sample_farm.id,
        health_score=75.0
    )
    
    latest = crud.get_farm_latest_soil_health(db_session, sample_farm.id)
    
    assert latest.id == record2.id
    assert latest.health_score == 75.0


def test_get_farm_soil_health_history(db_session, sample_farm):
    """Test retrieving soil health history"""
    today = datetime.utcnow()
    
    # Create records for past 30 days
    for i in range(0, 30, 7):
        crud.create_soil_health_record(
            db_session,
            farm_id=sample_farm.id,
            health_score=70.0 + i,
            source="manual"
        )
    
    history = crud.get_farm_soil_health_history(db_session, sample_farm.id, days=30)
    
    assert len(history) >= 4  # At least 4 weeks of data


# ============================================================================
# TESTS: ANALYTICS
# ============================================================================

def test_get_farmer_statistics(db_session, sample_farms):
    """Test farmer statistics calculation"""
    stats = crud.get_farmer_statistics(db_session, user_id=1)
    
    assert stats["total_farms"] == 2
    assert stats["total_area"] == 70.0  # 30 + 40
    assert "corn" in stats["crops"]
    assert "wheat" in stats["crops"]
    assert stats["avg_soil_health"] > 0


def test_get_farms_needing_attention(db_session):
    """Test identifying farms needing attention"""
    # Create a farm with low soil health
    farm = Farm(
        user_id=1,
        name="Problem Farm",
        current_crop=CropTypeEnum.CORN,
        primary_crop=CropTypeEnum.CORN,
        growth_stage=CropStageEnum.FLOWERING,
        soil_health_score=35.0,  # Low
        moisture_level=15.0  # Low
    )
    db_session.add(farm)
    db_session.commit()
    
    critical = crud.get_farms_needing_attention(db_session, user_id=1)
    
    assert len(critical) > 0
    assert any("Low soil health" in alert for f in critical for alert in f["alerts"])


# ============================================================================
# TESTS: DATA VALIDATION
# ============================================================================

def test_farm_relationships(db_session, sample_farm):
    """Test farm relationships are properly loaded"""
    db_session.refresh(sample_farm)
    
    assert hasattr(sample_farm, "crop_stages")
    assert hasattr(sample_farm, "weather_forecasts")
    assert hasattr(sample_farm, "soil_health_records")


def test_timestamp_tracking(db_session, sample_farm):
    """Test that timestamps are properly tracked"""
    assert sample_farm.created_at is not None
    assert sample_farm.updated_at is not None
    assert isinstance(sample_farm.created_at, datetime)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
