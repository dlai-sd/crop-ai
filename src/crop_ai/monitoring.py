"""
Monitoring and health check utilities for crop-ai.
"""
import logging
from dataclasses import dataclass
from datetime import datetime

import psutil

logger = logging.getLogger(__name__)

@dataclass
class SystemMetrics:
    """System performance metrics."""
    cpu_percent: float
    memory_percent: float
    memory_mb: float
    timestamp: str

@dataclass
class ServiceHealth:
    """Service health status."""
    status: str
    model_ready: bool
    system_ok: bool
    cpu_ok: bool
    memory_ok: bool
    timestamp: str
    metrics: SystemMetrics

class HealthMonitor:
    """Monitor service health and system resources."""
    
    CPU_THRESHOLD = 95.0  # percent - relaxed for CI environments
    MEMORY_THRESHOLD = 95.0  # percent - relaxed for CI environments
    
    def __init__(self):
        """Initialize health monitor."""
        self.start_time = datetime.utcnow()
        logger.info("Health monitor initialized")
    
    def get_system_metrics(self) -> SystemMetrics:
        """Get current system metrics."""
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        
        return SystemMetrics(
            cpu_percent=cpu_percent,
            memory_percent=memory.percent,
            memory_mb=memory.used / (1024 * 1024),
            timestamp=datetime.utcnow().isoformat()
        )
    
    def check_health(self, model_initialized: bool) -> ServiceHealth:
        """Check overall service health."""
        metrics = self.get_system_metrics()
        
        cpu_ok = metrics.cpu_percent < self.CPU_THRESHOLD
        memory_ok = metrics.memory_percent < self.MEMORY_THRESHOLD
        system_ok = cpu_ok and memory_ok
        
        status = "healthy" if (system_ok and model_initialized) else "degraded"
        
        return ServiceHealth(
            status=status,
            model_ready=model_initialized,
            system_ok=system_ok,
            cpu_ok=cpu_ok,
            memory_ok=memory_ok,
            timestamp=datetime.utcnow().isoformat(),
            metrics=metrics
        )
    
    def get_uptime(self) -> float:
        """Get service uptime in seconds."""
        return (datetime.utcnow() - self.start_time).total_seconds()

# Global health monitor instance
_monitor = HealthMonitor()

def get_monitor() -> HealthMonitor:
    """Get global health monitor instance."""
    return _monitor
