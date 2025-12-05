"""
Application Insights configuration and monitoring setup for crop-ai service.
"""

import os
from opencensus.ext.azure.log_exporter import AzureLogHandler
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.ext.flask.flask_middleware import FlaskMiddleware
from opencensus.trace.samplers import ProbabilitySampler
import logging

def setup_application_insights():
    """
    Configure Azure Application Insights for monitoring.
    
    Environment Variables:
    - APPINSIGHTS_INSTRUMENTATION_KEY: The instrumentation key from Application Insights
    - ENVIRONMENT: Deployment environment (development, staging, production)
    """
    
    instrumentation_key = os.getenv('APPINSIGHTS_INSTRUMENTATION_KEY', '')
    environment = os.getenv('ENVIRONMENT', 'development')
    
    if not instrumentation_key:
        logging.warning("APPINSIGHTS_INSTRUMENTATION_KEY not set. Monitoring disabled.")
        return None
    
    # Set up Azure Exporter
    azure_exporter = AzureExporter(connection_string=f"InstrumentationKey={instrumentation_key}")
    
    # Configure logging with Application Insights
    handler = AzureLogHandler(connection_string=f"InstrumentationKey={instrumentation_key}")
    handler.setLevel(logging.INFO)
    
    # Create formatter
    formatter = logging.Formatter(
        fmt='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        datefmt='%Y-%m-%d %H:%M:%S'
    )
    handler.setFormatter(formatter)
    
    # Add properties for all logs
    handler.add_telemetry_processor(lambda envelope: add_custom_properties(envelope, environment))
    
    # Get root logger and add handler
    logger = logging.getLogger()
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
    
    logging.info(f"Application Insights initialized for environment: {environment}")
    
    return azure_exporter

def add_custom_properties(envelope, environment):
    """Add custom properties to all telemetry."""
    envelope.tags['ai.cloud.role'] = 'crop-ai-api'
    envelope.tags['ai.cloud.roleInstance'] = os.getenv('HOSTNAME', 'unknown')
    
    # Add custom properties
    if hasattr(envelope, 'tags'):
        if 'ai.application.ver' not in envelope.tags:
            envelope.tags['ai.application.ver'] = '0.1.0'
        
        # Add environment tag
        if hasattr(envelope.data, 'base_data'):
            if hasattr(envelope.data.base_data, 'properties'):
                envelope.data.base_data.properties['environment'] = environment
                envelope.data.base_data.properties['service'] = 'crop-ai'
    
    return True

def get_instrumentation_key():
    """Get the Application Insights instrumentation key."""
    return os.getenv('APPINSIGHTS_INSTRUMENTATION_KEY', '')

def is_monitoring_enabled():
    """Check if Application Insights monitoring is enabled."""
    return bool(os.getenv('APPINSIGHTS_INSTRUMENTATION_KEY'))
