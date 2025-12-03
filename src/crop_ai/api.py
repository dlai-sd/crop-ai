"""
FastAPI application for crop-ai prediction service.
"""
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import logging
import sys
from datetime import datetime
from .predict import ModelAdapter
from .monitoring import get_monitor
from .database import get_database, PredictionRecord
import time

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="crop-ai",
    description="Crop Identification Service using Satellite Imagery",
    version="0.1.0"
)

# Initialize model adapter
model_adapter = None
db = None
startup_time = datetime.utcnow()
inference_count = 0
monitor = get_monitor()

# Request/Response Models
class PredictionRequest(BaseModel):
    """Request model for crop prediction."""
    image_url: str
    model_version: str = "latest"

class PredictionResponse(BaseModel):
    """Response model for crop prediction."""
    crop_type: str
    confidence: float
    model_version: str
    timestamp: str

class HealthResponse(BaseModel):
    """Response model for health check."""
    status: str
    service: str
    uptime_seconds: float
    inference_count: int
    timestamp: str

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize model and database on startup."""
    global model_adapter, db
    logger.info("crop-ai service starting up...")
    try:
        model_adapter = ModelAdapter()
        logger.info("Model adapter initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize model adapter: {e}")
        model_adapter = None
    
    try:
        db = await get_database()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        db = None

# Shutdown event
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown."""
    logger.info("crop-ai service shutting down...")

# Health check endpoint
@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint with system metrics."""
    uptime = (datetime.utcnow() - startup_time).total_seconds()
    health_status = monitor.check_health(model_adapter is not None)
    
    return HealthResponse(
        status=health_status.status,
        service="crop-ai",
        uptime_seconds=uptime,
        inference_count=inference_count,
        timestamp=datetime.utcnow().isoformat()
    )

# Ready check endpoint
@app.get("/ready")
async def ready():
    """Readiness check endpoint."""
    if model_adapter is None:
        raise HTTPException(status_code=503, detail="Model not initialized")
    return {"ready": True, "timestamp": datetime.utcnow().isoformat()}

# Prediction endpoint
@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    """
    Predict crop type from satellite imagery.
    
    Args:
        request: PredictionRequest with image_url and optional model_version
        
    Returns:
        PredictionResponse with crop_type, confidence, and metadata
    """
    global inference_count
    
    if model_adapter is None:
        raise HTTPException(status_code=503, detail="Model not initialized")
    
    try:
        logger.info(f"Processing prediction request for image: {request.image_url}")
        start_time = time.time()
        
        # TODO: Implement actual model inference
        # For now, return mock response
        crop_type = "wheat"
        confidence = 0.85
        
        processing_time_ms = (time.time() - start_time) * 1000
        inference_count += 1
        
        # Save to database
        if db:
            record = PredictionRecord(
                image_url=request.image_url,
                crop_type=crop_type,
                confidence=confidence,
                model_version=request.model_version,
                timestamp=datetime.utcnow().isoformat(),
                processing_time_ms=processing_time_ms
            )
            await db.save_prediction(record)
        
        return PredictionResponse(
            crop_type=crop_type,
            confidence=confidence,
            model_version=request.model_version,
            timestamp=datetime.utcnow().isoformat()
        )
    except Exception as e:
        logger.error(f"Prediction failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Info endpoint
@app.get("/info")
async def info():
    """Get service information."""
    return {
        "service": "crop-ai",
        "version": "0.1.0",
        "description": "Crop Identification Service using Satellite Imagery",
        "model_initialized": model_adapter is not None,
        "uptime_seconds": (datetime.utcnow() - startup_time).total_seconds(),
        "inference_count": inference_count,
        "timestamp": datetime.utcnow().isoformat()
    }

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    """Get service metrics and health status."""
    health_status = monitor.check_health(model_adapter is not None)
    return {
        "service": "crop-ai",
        "overall_status": health_status.status,
        "uptime_seconds": monitor.get_uptime(),
        "inference_count": inference_count,
        "system": {
            "cpu_percent": health_status.metrics.cpu_percent,
            "cpu_ok": health_status.cpu_ok,
            "memory_percent": health_status.metrics.memory_percent,
            "memory_mb": health_status.metrics.memory_mb,
            "memory_ok": health_status.memory_ok,
        },
        "model": {
            "initialized": health_status.model_ready,
        },
        "timestamp": health_status.timestamp
    }

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "Welcome to crop-ai API",
        "docs": "/docs",
        "redoc": "/redoc",
        "openapi_schema": "/openapi.json",
        "endpoints": {
            "health": "GET /health",
            "ready": "GET /ready",
            "metrics": "GET /metrics",
            "predict": "POST /predict",
            "predictions": "GET /predictions",
            "stats": "GET /stats",
            "info": "GET /info"
        }
    }

# Get recent predictions endpoint
@app.get("/predictions")
async def get_predictions(limit: int = 50):
    """Get recent predictions from database."""
    if not db:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        predictions = await db.get_predictions(limit=limit)
        return {
            "count": len(predictions),
            "predictions": [
                {
                    "image_url": p.image_url,
                    "crop_type": p.crop_type,
                    "confidence": p.confidence,
                    "model_version": p.model_version,
                    "timestamp": p.timestamp
                }
                for p in predictions
            ]
        }
    except Exception as e:
        logger.error(f"Failed to get predictions: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Get statistics endpoint
@app.get("/stats")
async def get_stats():
    """Get prediction statistics."""
    if not db:
        raise HTTPException(status_code=503, detail="Database not available")
    
    try:
        stats = await db.get_stats()
        return {
            "stats": stats,
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        logger.error(f"Failed to get stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# Exception handlers
@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    """Handle general exceptions."""
    logger.error(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "error": str(exc)}
    )
