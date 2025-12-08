"""
Observability Dashboard Configuration for Grafana
Defines all dashboard templates and data sources
"""

from typing import Any, Dict


class DashboardGenerator:
    """Generate Grafana dashboards programmatically"""
    
    @staticmethod
    def create_main_dashboard() -> Dict[str, Any]:
        """Main system overview dashboard"""
        return {
            "dashboard": {
                "title": "Crop AI - System Overview",
                "tags": ["crop-ai", "main"],
                "timezone": "UTC",
                "panels": [
                    {
                        "title": "API Requests (5m)",
                        "targets": [
                            {
                                "expr": "rate(http_requests_total[5m])"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Request Latency (P95)",
                        "targets": [
                            {
                                "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Error Rate (5m)",
                        "targets": [
                            {
                                "expr": "rate(http_requests_total{status=~'5..'}[5m])"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Active Requests",
                        "targets": [
                            {
                                "expr": "http_requests_active"
                            }
                        ],
                        "type": "stat"
                    },
                    {
                        "title": "System CPU Usage",
                        "targets": [
                            {
                                "expr": "100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "System Memory Usage",
                        "targets": [
                            {
                                "expr": "100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Disk Usage",
                        "targets": [
                            {
                                "expr": "100 * (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes))"
                            }
                        ],
                        "type": "graph"
                    }
                ]
            }
        }
    
    @staticmethod
    def create_application_dashboard() -> Dict[str, Any]:
        """Application metrics dashboard"""
        return {
            "dashboard": {
                "title": "Crop AI - Application Metrics",
                "tags": ["crop-ai", "application"],
                "timezone": "UTC",
                "panels": [
                    {
                        "title": "Model Predictions (5m)",
                        "targets": [
                            {
                                "expr": "rate(model_predictions_total[5m])"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Prediction Success Rate",
                        "targets": [
                            {
                                "expr": "model_predictions_total{status='success'} / model_predictions_total"
                            }
                        ],
                        "type": "gauge"
                    },
                    {
                        "title": "Prediction Latency (P99)",
                        "targets": [
                            {
                                "expr": "histogram_quantile(0.99, rate(model_prediction_duration_seconds_bucket[5m]))"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Database Query Latency",
                        "targets": [
                            {
                                "expr": "histogram_quantile(0.95, rate(db_query_duration_seconds_bucket[5m]))"
                            }
                        ],
                        "type": "graph"
                    },
                    {
                        "title": "Cache Hit Rate",
                        "targets": [
                            {
                                "expr": "cache_hits_total / (cache_hits_total + cache_misses_total)"
                            }
                        ],
                        "type": "gauge"
                    }
                ]
            }
        }
    
    @staticmethod
    def create_logs_dashboard() -> Dict[str, Any]:
        """Logs and events dashboard"""
        return {
            "dashboard": {
                "title": "Crop AI - Logs & Events",
                "tags": ["crop-ai", "logs"],
                "timezone": "UTC",
                "panels": [
                    {
                        "title": "Recent Logs",
                        "targets": [
                            {
                                "expr": "{app=~'crop-ai.*'}",
                                "refId": "A"
                            }
                        ],
                        "type": "logs"
                    },
                    {
                        "title": "Error Logs (24h)",
                        "targets": [
                            {
                                "expr": "{level='ERROR'}",
                                "refId": "A"
                            }
                        ],
                        "type": "logs"
                    },
                    {
                        "title": "Warning Logs (24h)",
                        "targets": [
                            {
                                "expr": "{level='WARNING'}",
                                "refId": "A"
                            }
                        ],
                        "type": "logs"
                    }
                ]
            }
        }

# Export configurations
DATASOURCES = [
    {
        "name": "Prometheus",
        "type": "prometheus",
        "access": "proxy",
        "url": "http://prometheus:9090",
        "isDefault": True
    },
    {
        "name": "Loki",
        "type": "loki",
        "access": "proxy",
        "url": "http://loki:3100"
    }
]

DASHBOARDS = {
    "main": DashboardGenerator.create_main_dashboard(),
    "application": DashboardGenerator.create_application_dashboard(),
    "logs": DashboardGenerator.create_logs_dashboard()
}
