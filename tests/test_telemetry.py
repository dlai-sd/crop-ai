"""
Tests for telemetry module.
"""
from datetime import datetime

from crop_ai.telemetry import HealthMetric, PredictionMetric, TelemetryManager, get_telemetry


def test_telemetry_manager_init():
    """Test TelemetryManager initialization."""
    manager = TelemetryManager()
    assert manager is not None
    # May or may not have client depending on env vars
    assert manager.environment in ["development", "production"]


def test_prediction_metric():
    """Test PredictionMetric dataclass."""
    metric = PredictionMetric(
        image_url="https://example.com/image.tif",
        crop_type="wheat",
        confidence=0.85,
        model_version="v1",
        processing_time_ms=125.5,
        timestamp=datetime.utcnow().isoformat(),
        success=True
    )
    assert metric.crop_type == "wheat"
    assert metric.confidence == 0.85
    assert metric.success is True


def test_prediction_metric_failure():
    """Test PredictionMetric with failure."""
    metric = PredictionMetric(
        image_url="https://example.com/image.tif",
        crop_type="unknown",
        confidence=0.0,
        model_version="v1",
        processing_time_ms=100.0,
        timestamp=datetime.utcnow().isoformat(),
        success=False,
        error_message="Model timeout"
    )
    assert metric.success is False
    assert metric.error_message == "Model timeout"


def test_health_metric():
    """Test HealthMetric dataclass."""
    metric = HealthMetric(
        cpu_percent=25.5,
        memory_percent=45.0,
        memory_mb=512.0,
        status="healthy",
        model_ready=True,
        timestamp=datetime.utcnow().isoformat()
    )
    assert metric.status == "healthy"
    assert metric.cpu_percent == 25.5
    assert metric.model_ready is True


def test_get_telemetry_singleton():
    """Test telemetry singleton pattern."""
    telemetry1 = get_telemetry()
    telemetry2 = get_telemetry()
    assert telemetry1 is telemetry2


def test_track_prediction():
    """Test tracking a prediction without crashing."""
    manager = TelemetryManager()
    metric = PredictionMetric(
        image_url="https://example.com/image.tif",
        crop_type="rice",
        confidence=0.92,
        model_version="v1",
        processing_time_ms=150.0,
        timestamp=datetime.utcnow().isoformat(),
        success=True
    )
    # Should not raise
    manager.track_prediction(metric)


def test_track_health():
    """Test tracking health metric without crashing."""
    manager = TelemetryManager()
    metric = HealthMetric(
        cpu_percent=30.0,
        memory_percent=50.0,
        memory_mb=600.0,
        status="healthy",
        model_ready=True,
        timestamp=datetime.utcnow().isoformat()
    )
    # Should not raise
    manager.track_health(metric)


def test_track_exception():
    """Test tracking an exception without crashing."""
    manager = TelemetryManager()
    try:
        raise ValueError("Test error")
    except ValueError as e:
        # Should not raise
        manager.track_exception(e, "test_context")


def test_track_custom_metric():
    """Test tracking a custom metric without crashing."""
    manager = TelemetryManager()
    # Should not raise
    manager.track_custom_metric(
        name="inference_queue_depth",
        value=5.0,
        properties={"queue": "main"}
    )


def test_track_dependency():
    """Test tracking a dependency without crashing."""
    manager = TelemetryManager()
    # Should not raise
    manager.track_dependency(
        name="database",
        command_name="get_predictions",
        success=True,
        duration_ms=45.0
    )


def test_flush():
    """Test flushing telemetry without crashing."""
    manager = TelemetryManager()
    # Should not raise
    manager.flush()
