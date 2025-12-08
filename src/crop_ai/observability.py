"""
Observability instrumentation for FastAPI backend
- Prometheus metrics export
- JSON structured logging
- Distributed tracing support
"""

import json
import logging
import time
from datetime import datetime
from functools import wraps

from prometheus_client import Counter, Gauge, Histogram, generate_latest

# Prometheus metrics
request_count = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

request_duration = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint'],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0)
)

active_requests = Gauge(
    'http_requests_active',
    'Active HTTP requests'
)

prediction_count = Counter(
    'model_predictions_total',
    'Total model predictions',
    ['model', 'status']
)

prediction_duration = Histogram(
    'model_prediction_duration_seconds',
    'Model prediction duration',
    ['model'],
    buckets=(0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0)
)

db_query_duration = Histogram(
    'db_query_duration_seconds',
    'Database query duration',
    ['operation', 'table'],
    buckets=(0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0)
)

cache_hits = Counter(
    'cache_hits_total',
    'Cache hits',
    ['key']
)

cache_misses = Counter(
    'cache_misses_total',
    'Cache misses',
    ['key']
)

# Structured logging
class JSONFormatter(logging.Formatter):
    """Format logs as JSON"""
    
    def format(self, record):
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'logger': record.name,
            'message': record.getMessage(),
            'module': record.module,
            'function': record.funcName,
            'line': record.lineno,
        }
        
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        
        return json.dumps(log_data)

def setup_logging():
    """Setup JSON structured logging"""
    logger = logging.getLogger('crop-ai')
    logger.setLevel(logging.INFO)
    
    # File handler with JSON formatting
    fh = logging.FileHandler('/tmp/crop-ai-logs/fastapi.log')
    fh.setFormatter(JSONFormatter())
    logger.addHandler(fh)
    
    # Console handler with JSON formatting
    ch = logging.StreamHandler()
    ch.setFormatter(JSONFormatter())
    logger.addHandler(ch)
    
    return logger

# Middleware for FastAPI
class MetricsMiddleware:
    """Middleware to collect Prometheus metrics"""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        path = scope["path"]
        method = scope["method"]
        
        # Skip metrics endpoint
        if path == "/metrics":
            await self.app(scope, receive, send)
            return
        
        active_requests.inc()
        start_time = time.time()
        
        async def send_wrapper(message):
            if message["type"] == "http.response.start":
                status_code = message["status"]
                duration = time.time() - start_time
                
                request_count.labels(
                    method=method,
                    endpoint=path,
                    status=status_code
                ).inc()
                
                request_duration.labels(
                    method=method,
                    endpoint=path
                ).observe(duration)
            
            await send(message)
        
        try:
            await self.app(scope, receive, send_wrapper)
        finally:
            active_requests.dec()

# Decorators for instrumentation
def track_prediction(model_name):
    """Decorator to track model predictions"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = func(*args, **kwargs)
                duration = time.time() - start_time
                prediction_duration.labels(model=model_name).observe(duration)
                prediction_count.labels(model=model_name, status='success').inc()
                return result
            except Exception:
                prediction_count.labels(model=model_name, status='error').inc()
                raise
        return wrapper
    return decorator

def track_db_query(operation, table):
    """Decorator to track database queries"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            start_time = time.time()
            try:
                result = func(*args, **kwargs)
                duration = time.time() - start_time
                db_query_duration.labels(operation=operation, table=table).observe(duration)
                return result
            except Exception:
                raise
        return wrapper
    return decorator

def track_cache(key_name):
    """Decorator to track cache operations"""
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            cache_key = f"{key_name}:{args}:{kwargs}"
            # Implementation depends on actual cache logic
            return func(*args, **kwargs)
        return wrapper
    return decorator

# Health check endpoint
async def health_check():
    """Health check endpoint for observability"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    }

# Metrics endpoint
async def get_metrics():
    """Prometheus metrics endpoint"""
    return generate_latest()
