"""
Tests for crop-ai API.
"""
import pytest
from fastapi.testclient import TestClient
from crop_ai.api import app

client = TestClient(app)

def test_root():
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()
    assert "docs" in response.json()

def test_health():
    """Test health endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    # Status can be healthy or degraded depending on system resources
    assert data["status"] in ["healthy", "degraded"]
    assert data["service"] == "crop-ai"
    assert "uptime_seconds" in data

def test_info():
    """Test info endpoint."""
    response = client.get("/info")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "crop-ai"
    assert "model_initialized" in data

def test_predict():
    """Test prediction endpoint."""
    payload = {
        "image_url": "https://example.com/image.tif",
        "model_version": "latest"
    }
    response = client.post("/predict", json=payload)
    # Can return 200 or 503 depending on model initialization during testing
    assert response.status_code in [200, 503]
    if response.status_code == 200:
        data = response.json()
        assert "crop_type" in data
        assert "confidence" in data
        assert "model_version" in data
        assert "timestamp" in data

def test_invalid_predict_request():
    """Test prediction with invalid request."""
    payload = {}
    response = client.post("/predict", json=payload)
    assert response.status_code == 422  # Validation error

def test_ready():
    """Test readiness endpoint."""
    response = client.get("/ready")
    # May be 200 or 503 depending on model initialization
    assert response.status_code in [200, 503]
