"""
Tests for crop-ai model adapter.
"""
import pytest
from crop_ai.predict import ModelAdapter, PredictionResult

def test_model_adapter_init():
    """Test model adapter initialization."""
    adapter = ModelAdapter()
    assert adapter is not None
    assert adapter.model_version == "0.1.0"

def test_model_adapter_crops():
    """Test supported crops."""
    adapter = ModelAdapter()
    crops = adapter.get_supported_crops()
    assert "wheat" in crops
    assert len(crops) > 0

def test_model_adapter_predict():
    """Test single prediction."""
    adapter = ModelAdapter()
    result = adapter.predict("https://example.com/image.tif")
    assert isinstance(result, PredictionResult)
    assert result.crop_type is not None
    assert 0 <= result.confidence <= 1

def test_model_adapter_batch_predict():
    """Test batch prediction."""
    adapter = ModelAdapter()
    images = [
        "https://example.com/image1.tif",
        "https://example.com/image2.tif"
    ]
    results = adapter.batch_predict(images)
    assert len(results) == 2
    assert all(isinstance(r, PredictionResult) for r in results)

def test_model_adapter_info():
    """Test model info."""
    adapter = ModelAdapter()
    info = adapter.get_model_info()
    assert "model_version" in info
    assert "supported_crops" in info
    assert "is_loaded" in info
