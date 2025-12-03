"""
Application Insights telemetry and monitoring integration.
"""
import logging
import os
from typing import Optional, Dict, Any
from datetime import datetime
from dataclasses import dataclass, asdict

logger = logging.getLogger(__name__)

# Application Insights SDK
try:
    from applicationinsights import TelemetryClient
    from applicationinsights.logging import LoggingHandler
    INSIGHTS_AVAILABLE = True
except ImportError:
    INSIGHTS_AVAILABLE = False
    logger.warning("Application Insights SDK not available - using stdout logging only")


@dataclass
class PredictionMetric:
    """Prediction event metric."""
    image_url: str
    crop_type: str
    confidence: float
    model_version: str
    processing_time_ms: float
    timestamp: str
    success: bool
    error_message: Optional[str] = None


@dataclass
class HealthMetric:
    """Health check metric."""
    cpu_percent: float
    memory_percent: float
    memory_mb: float
    status: str
    model_ready: bool
    timestamp: str


class TelemetryManager:
    """Manage Application Insights telemetry."""
    
    def __init__(self):
        """Initialize telemetry manager."""
        self.client: Optional[TelemetryClient] = None
        self.connection_string = os.getenv("APPINSIGHTS_CONNECTION_STRING")
        self.environment = os.getenv("ENVIRONMENT", "development")
        
        if INSIGHTS_AVAILABLE and self.connection_string:
            try:
                self.client = TelemetryClient(connection_string=self.connection_string)
                self.client.context.application.ver = "0.1.0"
                self.client.context.device.role_name = "crop-ai-api"
                logger.info(f"Application Insights initialized in {self.environment} environment")
            except Exception as e:
                logger.error(f"Failed to initialize Application Insights: {e}")
                self.client = None
        else:
            if not INSIGHTS_AVAILABLE:
                logger.info("Application Insights SDK not installed")
            if not self.connection_string:
                logger.info("APPINSIGHTS_CONNECTION_STRING not set - telemetry disabled")
    
    def track_prediction(self, metric: PredictionMetric) -> None:
        """Track a prediction event."""
        properties = {
            "crop_type": metric.crop_type,
            "model_version": metric.model_version,
            "environment": self.environment,
            "success": str(metric.success)
        }
        measurements = {
            "confidence": metric.confidence,
            "processing_time_ms": metric.processing_time_ms
        }
        
        event_name = "PredictionSuccess" if metric.success else "PredictionFailure"
        
        if self.client:
            self.client.track_event(
                name=event_name,
                properties=properties,
                measurements=measurements
            )
            self.client.flush()
        
        # Always log locally
        logger.info(f"Prediction tracked: {event_name} - {metric.crop_type} (confidence: {metric.confidence:.2f})")
    
    def track_health(self, metric: HealthMetric) -> None:
        """Track health check metric."""
        properties = {
            "status": metric.status,
            "model_ready": str(metric.model_ready),
            "environment": self.environment
        }
        measurements = {
            "cpu_percent": metric.cpu_percent,
            "memory_percent": metric.memory_percent,
            "memory_mb": metric.memory_mb
        }
        
        if self.client:
            self.client.track_event(
                name="HealthCheck",
                properties=properties,
                measurements=measurements
            )
            self.client.flush()
        
        logger.debug(f"Health metric tracked: {metric.status} - CPU: {metric.cpu_percent:.1f}%, Memory: {metric.memory_percent:.1f}%")
    
    def track_exception(self, error: Exception, context: str = "") -> None:
        """Track an exception."""
        properties = {
            "context": context,
            "environment": self.environment
        }
        
        if self.client:
            self.client.track_exception(
                exc_type=type(error),
                exc_value=error,
                tb=None,
                properties=properties
            )
            self.client.flush()
        
        logger.error(f"Exception tracked in {context}: {str(error)}")
    
    def track_custom_metric(self, name: str, value: float, properties: Optional[Dict[str, str]] = None) -> None:
        """Track a custom metric."""
        if properties is None:
            properties = {}
        properties["environment"] = self.environment
        
        if self.client:
            self.client.track_event(
                name=name,
                properties=properties,
                measurements={"value": value}
            )
            self.client.flush()
        
        logger.debug(f"Custom metric tracked: {name} = {value}")
    
    def track_dependency(self, name: str, command_name: str, success: bool, duration_ms: float) -> None:
        """Track a dependency call (database, external API, etc)."""
        if self.client:
            self.client.track_availability(
                name=name,
                result=success,
                duration=int(duration_ms),
                properties={"command": command_name, "environment": self.environment}
            )
            self.client.flush()
        
        logger.debug(f"Dependency tracked: {name} - {command_name} - {'success' if success else 'failed'} ({duration_ms:.1f}ms)")
    
    def flush(self) -> None:
        """Flush any pending telemetry."""
        if self.client:
            self.client.flush()


# Global telemetry manager instance
_telemetry_manager: Optional[TelemetryManager] = None


def get_telemetry() -> TelemetryManager:
    """Get or create global telemetry manager."""
    global _telemetry_manager
    if _telemetry_manager is None:
        _telemetry_manager = TelemetryManager()
    return _telemetry_manager


def init_telemetry_logging() -> None:
    """Initialize Application Insights logging handler."""
    if not INSIGHTS_AVAILABLE:
        logger.warning("Application Insights SDK not available - cannot initialize logging handler")
        return
    
    connection_string = os.getenv("APPINSIGHTS_CONNECTION_STRING")
    if not connection_string:
        logger.info("APPINSIGHTS_CONNECTION_STRING not set - telemetry logging disabled")
        return
    
    try:
        # Add Application Insights handler to root logger
        handler = LoggingHandler(connection_string=connection_string)
        handler.setLevel(logging.WARNING)
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logging.getLogger().addHandler(handler)
        logger.info("Application Insights logging handler initialized")
    except Exception as e:
        logger.error(f"Failed to initialize Application Insights logging handler: {e}")
