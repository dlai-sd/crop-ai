# Logging & Observability Strategy

**Status:** 🔴 PRIORITY 3 - Before MVP Launch  
**Decision Date:** December 5, 2025  
**Last Updated:** December 5, 2025

---

## Executive Summary

Crop AI is a production system serving AI model inference on satellite data. We need **centralized logging, metrics, and tracing** to monitor health, debug issues, and optimize performance.

### Decision Summary

| Technology | Setup | Cost/mo | Features | Recommendation |
|------------|-------|---------|----------|-----------------|
| Azure Log Analytics | 30 min | $30-50 | ✅ All | ✅ RECOMMENDED |
| Datadog | 30 min | $50-100 | ✅ All | ⚠️ Great but expensive |
| Grafana+Prometheus | 2 hours | $0-30 | ✅ All | ⚠️ Self-hosted overhead |
| CloudWatch | 30 min | $30-50 | ✅ All | ⚠️ AWS only |
| ELK Stack | 4 hours | $50-100 | ✅ All | ❌ Too complex for MVP |

### Recommendation

**Use Azure Log Analytics** (integrated with Application Insights)
- Integrated with existing Azure infrastructure
- $30-50/month for MVP
- KQL (Kusto Query Language) for powerful analytics
- Real-time dashboards & alerts
- No infrastructure to manage

---

## Problem Statement

Production systems need visibility:

1. **Debugging Issues** - What went wrong? When? Why?
2. **Performance Optimization** - Which endpoints are slow? Why?
3. **Capacity Planning** - When do we need more resources?
4. **Security Monitoring** - Failed logins? Unusual access patterns?
5. **Cost Optimization** - Which operations consume most resources?
6. **User Experience** - Are users experiencing issues?

### Current State (Without Observability)
```
✗ Can't see API errors
✗ Can't track request latency
✗ Can't monitor AI model performance
✗ Can't detect issues before users report
✗ No audit trail for compliance
✗ Can't optimize database queries
✗ Can't correlate events across services
```

### Desired State (With Observability)
```
✓ Logs: All events captured and searchable
✓ Metrics: Performance data every 10 seconds
✓ Traces: Request flow across services
✓ Alerts: Notifications when issues happen
✓ Dashboards: Real-time status overview
✓ Analysis: Historical trends & patterns
✓ Compliance: Complete audit trail
```

---

## Three Pillars of Observability

### Pillar 1: Logs

**What:** Text messages from application (info, warning, error)

**Examples:**
```
INFO: User 123 logged in from 192.168.1.1
WARNING: Slow database query (2.5 seconds)
ERROR: Failed to reach satellite API (timeout after 30s)
DEBUG: Cache hit for crop ID 456
```

**Log Levels:**
- DEBUG: Detailed information for debugging
- INFO: General informational messages
- WARNING: Something unexpected but not critical
- ERROR: Error occurred, operation failed
- CRITICAL: System may not continue operating

### Pillar 2: Metrics

**What:** Numeric measurements (counts, durations, values)

**Examples:**
```
requests_total: 1,234,567 (total API requests)
request_latency_ms: 42.3 (average request time)
http_4xx_errors: 12 (number of client errors)
gpu_memory_used: 6.2 (GB)
db_connection_pool: 8/10 (active connections)
crops_analyzed_today: 156
```

**Key Metrics for Crop AI:**
```
API Health:
├─ Requests per second
├─ Request latency (p50, p99)
├─ Error rate (4xx, 5xx)
└─ Uptime %

Database:
├─ Query latency (slow query log)
├─ Connection pool usage
├─ Disk usage
└─ Replication lag

AI/ML:
├─ Model inference time
├─ GPU memory usage
├─ GPU utilization %
├─ Model accuracy metrics
└─ Queue depth

Storage:
├─ Blob upload latency
├─ Blob download latency
├─ Storage tier distribution
└─ Storage cost

Business:
├─ Crops analyzed (daily, weekly, monthly)
├─ Analyses completed (success %)
├─ Model accuracy
└─ User activity
```

### Pillar 3: Traces

**What:** Distributed request flow across services

**Examples:**
```
Request: POST /crops/123/analyze
├─ FastAPI handler (10ms)
├─  → PostgreSQL: Get crop (5ms)
├─  → Redis: Get cached model (1ms, cache hit)
├─  → RQ: Enqueue job (2ms)
├─  → Response: 202 Accepted (0.5ms)
└─ Total: 18.5ms

Background Job: Analyze satellite imagery
├─ Get model from S3 (200ms)
├─ Load image from blob (150ms)
├─ GPU inference (8,500ms)
├─ Save results to blob (100ms)
├─ Update PostgreSQL (50ms)
└─ Total: 9,000ms
```

---

## Option Analysis

### Option 1: Azure Log Analytics (RECOMMENDED)

**How it works:**
```
1. FastAPI application logs to Application Insights
2. Application Insights aggregates logs, metrics, traces
3. Stored in Log Analytics workspace
4. Query/visualize with KQL
5. Setup alerts & dashboards
```

**Architecture:**
```
FastAPI App
    ├─ Logs (Application Insights SDK)
    ├─ Metrics (standard metrics + custom)
    └─ Traces (distributed tracing)
            ↓
    Application Insights
            ├─ Log Analytics Workspace
            ├─ Dashboards
            ├─ Alerts
            └─ Analytics Queries (KQL)
```

**Pros:**
- ✅ Fully managed (no servers)
- ✅ Integrated with Azure ecosystem
- ✅ Powerful KQL query language
- ✅ Real-time dashboards
- ✅ Automatic performance anomaly detection
- ✅ Application Map (visualize dependencies)
- ✅ Works with Python, Node.js, Go, Java
- ✅ 30-day retention (configurable)
- ✅ Affordable pricing
- ✅ Native Azure AD integration

**Cons:**
- ❌ Azure lock-in
- ❌ KQL has learning curve
- ❌ Data retention costs ($0.50-5/GB for long-term)
- ❌ Dashboard creation requires KQL knowledge

**Cost Analysis:**

| Phase | Scenario | Monthly |
|-------|----------|---------|
| MVP | 100 requests/sec, 100 GB/day logs | $30-50 |
| Growth | 500 requests/sec, 300 GB/day logs | $75-125 |
| Enterprise | 2000 requests/sec, 1000 GB/day logs | $150-300 |

**Pricing Details:**
```
Azure Log Analytics Pricing (per GB ingested):
├─ First 5 GB/day: Free tier (some limitations)
├─ Beyond 5 GB/day: $2.99/GB (if Pay-As-You-Go)
└─ Commitment-based: $0.99-2.99/GB (6-12 month commitments)

Total calculation for MVP:
├─ Estimated: 100 GB/month
├─ Cost: 100 × $2.99 = $299/month (pay-as-you-go)
├─ OR: 100 × $1.50 (commitment) = $150/month (6-month commitment)
└─ Reasonable estimate: $30-50/month after optimization
```

**Implementation (30 minutes):**

```bash
# 1. Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group crop-ai-rg \
  --workspace-name crop-ai-logs \
  --location eastus

# 2. Create Application Insights resource
az monitor app-insights component create \
  --app crop-ai-insights \
  --location eastus \
  --resource-group crop-ai-rg \
  --workspace /subscriptions/{sub-id}/resourcegroups/crop-ai-rg/providers/microsoft.operationalinsights/workspaces/crop-ai-logs

# 3. Get instrumentation key
az monitor app-insights component show \
  --app crop-ai-insights \
  --resource-group crop-ai-rg \
  --query instrumentationKey -o tsv
```

**FastAPI Integration:**

```python
# requirements.txt
azure-monitor-opentelemetry-exporter==1.0.0
opentelemetry-api==1.20.0
opentelemetry-sdk==1.20.0
opentelemetry-instrumentation-fastapi==0.41b0
opentelemetry-instrumentation-sqlalchemy==0.41b0
opentelemetry-instrumentation-redis==0.41b0

# main.py
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter
import os

# Setup Azure Monitor exporter
exporter = AzureMonitorTraceExporter(
    connection_string=os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
)

# Setup trace provider
trace_provider = TracerProvider()
trace_provider.add_span_processor(BatchSpanProcessor(exporter))
trace.set_tracer_provider(trace_provider)

# Instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# Instrument database
SQLAlchemyInstrumentor().instrument(engine=db_engine)

# Instrument Redis
RedisInstrumentor().instrument()

# Custom logging
import logging
from azure.monitor.opentelemetry.exporter import AzureMonitorLogExporter

logging_exporter = AzureMonitorLogExporter(
    connection_string=os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
)

# Setup logging
logging_handler = logging.StreamHandler()
logger = logging.getLogger("crop_ai")
logger.addHandler(logging_handler)
logger.setLevel(logging.INFO)
```

**Structured Logging:**

```python
# config/logging.py
import logging
import json
from pythonjsonlogger import jsonlogger
from datetime import datetime

class JSONFormatter(jsonlogger.JsonFormatter):
    """Custom JSON formatter with extra fields"""
    
    def add_fields(self, log_record, record, message_dict):
        super(JSONFormatter, self).add_fields(log_record, record, message_dict)
        log_record['timestamp'] = datetime.utcnow().isoformat()
        log_record['level'] = record.levelname
        log_record['logger'] = record.name

# Setup JSON logging
json_handler = logging.FileHandler('logs/app.json')
json_formatter = JSONFormatter()
json_handler.setFormatter(json_formatter)

logger = logging.getLogger("crop_ai")
logger.addHandler(json_handler)

# Usage in application
from config.logging import logger

logger.info("Crop analysis started", extra={
    "crop_id": crop_id,
    "user_id": user_id,
    "analysis_type": "ndvi",
    "region": "US-East"
})

logger.warning("Slow query detected", extra={
    "query": "SELECT * FROM crops WHERE ...",
    "duration_ms": 2500,
    "threshold_ms": 1000
})

logger.error("Model inference failed", extra={
    "crop_id": crop_id,
    "error": str(exception),
    "model_version": "v2.1",
    "gpu_memory_mb": 6144
})
```

**Custom Metrics:**

```python
# monitoring/metrics.py
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from azure.monitor.opentelemetry.exporter import AzureMonitorMetricExporter

# Setup metrics
metric_exporter = AzureMonitorMetricExporter()
metrics_reader = PeriodicExportingMetricReader(metric_exporter, interval_millis=5000)
meter_provider = MeterProvider(metric_readers=[metrics_reader])
metrics.set_meter_provider(meter_provider)

# Create meter
meter = metrics.get_meter("crop_ai")

# Define custom metrics
crops_analyzed = meter.create_counter(
    name="crops_analyzed_total",
    description="Total crops analyzed",
    unit="1"
)

inference_duration = meter.create_histogram(
    name="inference_duration_ms",
    description="Model inference duration",
    unit="ms"
)

queue_depth = meter.create_observable_gauge(
    name="queue_depth",
    description="Number of jobs in queue",
    unit="1",
    callbacks=[lambda: [{"value": get_queue_depth()}]]
)

# Usage
crops_analyzed.add(1, {"crop_type": "wheat", "region": "us_midwest"})
inference_duration.record(8500, {"model": "ndvi_v2", "gpu": "A100"})
```

**KQL Queries:**

```kusto
// Request latency over time
requests
| where timestamp > ago(24h)
| summarize AvgDuration=avg(duration), MaxDuration=max(duration), P99=percentile(duration, 99) by bin(timestamp, 5m)
| render timechart

// Error rate by endpoint
requests
| where timestamp > ago(1h)
| summarize ErrorRate=toreal(todouble(sum(itemCount * iif(success==false, 1, 0))) / sum(itemCount)) * 100 by name
| where ErrorRate > 1

// Slow queries
customMetrics
| where name == "database_query_duration_ms"
| where todynamic(customDimensions).duration_ms > 1000
| summarize Count=count(), AvgDuration=avg(todouble(value)) by customDimensions.query
| order by Count desc

// GPU memory usage
customMetrics
| where name == "gpu_memory_mb"
| summarize AvgMemory=avg(todouble(value)), MaxMemory=max(todouble(value)) by bin(timestamp, 1m)
| render timechart

// Crop analysis completion rate
customMetrics
| where name == "crops_analyzed_total"
| make-series CompletedCount=sum(todouble(value)) default=0 on timestamp from ago(7d) to now() step 1d by tostring(customDimensions.status)
| render timechart
```

**Dashboards:**

```
Dashboard: Crop AI System Health

┌─────────────────────────────────────────────────────────────┐
│ API Performance                                             │
│ ├─ Requests/sec: 142                                       │
│ ├─ Latency (p99): 123ms                                    │
│ ├─ Error Rate: 0.3%                                        │
│ └─ Uptime: 99.97%                                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ AI Model Performance                                        │
│ ├─ Inference Time: 8,234ms (avg)                           │
│ ├─ GPU Utilization: 87%                                    │
│ ├─ GPU Memory: 6.2GB / 8GB                                 │
│ └─ Queue Depth: 23 jobs                                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Database Health                                             │
│ ├─ Query Latency (p99): 245ms                              │
│ ├─ Connection Pool: 8/10 active                            │
│ ├─ Replication Lag: 2 seconds                              │
│ └─ Slow Queries (1h): 3                                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Business Metrics                                            │
│ ├─ Crops Analyzed (today): 156                             │
│ ├─ Success Rate: 98.2%                                     │
│ ├─ Avg Analysis Time: 2.3 minutes                          │
│ └─ Active Users: 42                                        │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Alerts                                                      │
│ ├─ ⚠️ High error rate (2.1%)                               │
│ ├─ ⚠️ GPU memory near limit (87%)                          │
│ └─ ✓ All other systems nominal                             │
└─────────────────────────────────────────────────────────────┘
```

**Alerts:**

```python
# monitoring/alerts.py
from azure.monitor.management import MonitorManagementClient

ALERT_CONFIG = {
    "high_error_rate": {
        "condition": "error_rate > 5%",
        "severity": "2",  # Warning
        "notification": ["devops@cropai.com"]
    },
    "slow_api": {
        "condition": "p99_latency > 1000ms",
        "severity": "3",  # Informational
        "notification": ["devops@cropai.com"]
    },
    "gpu_memory_critical": {
        "condition": "gpu_memory > 95%",
        "severity": "2",
        "notification": ["devops@cropai.com", "ml-team@cropai.com"]
    },
    "inference_timeout": {
        "condition": "inference_time > 15s",
        "severity": "1",  # Critical
        "notification": ["oncall@cropai.com"]
    },
    "database_replication_lag": {
        "condition": "replication_lag > 30s",
        "severity": "2",
        "notification": ["dba@cropai.com"]
    },
    "failed_login_attempts": {
        "condition": "failed_logins > 10 in 5min",
        "severity": "1",  # Critical - possible attack
        "notification": ["security@cropai.com"]
    }
}
```

---

### Option 2: Datadog

**How it works:**
```
1. Install Datadog agent on servers
2. Application sends traces to agent
3. Agent forwards to Datadog cloud
4. Query/visualize in Datadog console
```

**Pros:**
- ✅ Industry standard for observability
- ✅ Excellent out-of-the-box dashboards
- ✅ AI-powered anomaly detection
- ✅ Works everywhere (AWS, Azure, GCP, on-prem)
- ✅ Great support & documentation

**Cons:**
- ❌ Expensive ($50-100/month for MVP)
- ❌ More complexity than needed
- ❌ Overkill for MVP stage

**When to use:**
- Multi-cloud deployment required
- Existing Datadog contract in organization
- Need advanced ML-based anomaly detection

**Cost:** $15-20 per monitored host/container

---

### Option 3: Grafana + Prometheus (Self-Hosted)

**How it works:**
```
1. FastAPI app exposes Prometheus metrics endpoint
2. Prometheus scrapes metrics every 10 seconds
3. Store metrics in Prometheus time-series database
4. Grafana visualizes Prometheus data
5. AlertManager sends alerts
```

**Pros:**
- ✅ Free/open-source
- ✅ Works everywhere
- ✅ Full control
- ✅ Beautiful dashboards (Grafana)

**Cons:**
- ❌ Requires server management (PostgreSQL, Redis for state)
- ❌ 4 hours initial setup
- ❌ Operational overhead (backups, upgrades, monitoring)
- ❌ Data retention costs (long-term storage problematic)

**When to use:**
- On-premises deployment
- Internal systems (not customer-facing)
- Team experienced with Prometheus

**Cost:** $50-100/month for infrastructure (VMs, storage)

---

### Option 4: CloudWatch (AWS-only)

**How it works:**
```
1. FastAPI app logs to CloudWatch
2. CloudWatch stores logs
3. CloudWatch Insights queries logs
4. Lambda processes metrics
5. SNS sends alerts
```

**Pros:**
- ✅ Integrated if using AWS
- ✅ Similar cost to Azure
- ✅ Powerful Insights query language

**Cons:**
- ❌ AWS lock-in
- ❌ Learning curve for Insights language
- ❌ Pricing can surprise
- ❌ We're on Azure; adds complexity

**When to use:**
- Existing AWS deployment
- Already using CloudFormation

---

### Option 5: ELK Stack (Elasticsearch, Logstash, Kibana)

**How it works:**
```
1. FastAPI sends logs to Logstash
2. Logstash parses and enrich logs
3. Elasticsearch stores logs
4. Kibana visualizes logs
```

**Pros:**
- ✅ Industry standard (especially in large enterprises)
- ✅ Excellent full-text search
- ✅ Powerful visualization

**Cons:**
- ❌ Complex setup (4+ hours)
- ❌ Requires operational expertise
- ❌ High infrastructure cost ($100+/month)
- ❌ Overkill for MVP
- ❌ Steep learning curve

**When to use:**
- Large enterprise with existing ELK
- On-premises requirement
- Need for complex log parsing

---

## Recommended Implementation

### MVP Phase: Azure Log Analytics

```
FastAPI App
    ├─ Logs (INFO, WARNING, ERROR)
    ├─ Metrics (API, GPU, DB, Storage)
    └─ Traces (Request flow)
            ↓
    Application Insights
            ├─ Aggregation
            └─ Ingestion
                    ↓
            Log Analytics Workspace
            ├─ Storage (30 days)
            ├─ Queries (KQL)
            ├─ Dashboards
            └─ Alerts
```

### Growth Phase: Add Custom Metrics

```
Azure Log Analytics (existing)
    ├─ Business metrics (crops analyzed, success rate)
    ├─ Performance metrics (inference time, queue depth)
    ├─ Cost metrics (GPU usage hours, storage bytes)
    └─ Compliance metrics (audit logs, access patterns)
```

### Enterprise Phase: Multi-Cloud

```
Azure Log Analytics (Primary)
    ├─ Primary data ingestion
    └─ Real-time alerts

AWS CloudWatch (Optional, for AWS resources)
    ├─ Secondary data
    └─ Cross-cloud visibility
```

---

## Implementation Plan

### Phase 1: Setup Azure Log Analytics (Day 1)

**Effort:** 1 hour

```bash
# Create Log Analytics workspace
az monitor log-analytics workspace create \
  --resource-group crop-ai-rg \
  --workspace-name crop-ai-logs

# Create Application Insights
az monitor app-insights component create \
  --app crop-ai-insights \
  --resource-group crop-ai-rg \
  --kind web \
  --workspace /subscriptions/{id}/resourcegroups/crop-ai-rg/providers/microsoft.operationalinsights/workspaces/crop-ai-logs

# Get connection string (store in .env)
az monitor app-insights component show \
  --app crop-ai-insights \
  --resource-group crop-ai-rg \
  --query connectionString -o tsv
```

### Phase 2: Instrument FastAPI (Day 1-2)

**Effort:** 2 hours

- Install OpenTelemetry libraries
- Configure Azure exporter
- Instrument FastAPI, database, Redis
- Add structured logging

### Phase 3: Create Dashboards (Day 2)

**Effort:** 2 hours

- API health dashboard
- AI model performance dashboard
- Business metrics dashboard
- Create key KQL queries

### Phase 4: Setup Alerts (Day 3)

**Effort:** 1 hour

- Configure alert rules
- Test alert notifications
- Document escalation procedures

### Phase 5: Documentation & Training (Day 3)

**Effort:** 1 hour

- Dashboard usage guide
- Common queries
- Troubleshooting guide
- On-call runbook

---

## Key Metrics to Monitor

### API Metrics

```
requests_total: Counter
├─ Total requests
├─ By status (200, 400, 404, 500)
└─ By endpoint

request_latency_ms: Histogram
├─ Min, max, avg, p50, p99
├─ By endpoint
└─ By method (GET, POST, etc)

http_exceptions: Counter
├─ By error type
├─ By status code
└─ By endpoint
```

### Database Metrics

```
db_query_latency_ms: Histogram
├─ By query type (SELECT, INSERT, UPDATE, DELETE)
├─ Slow queries (>1s)
└─ By table

db_connection_pool: Gauge
├─ Active connections
├─ Available connections
└─ Utilization %

db_errors: Counter
├─ Connection errors
├─ Query timeouts
└─ Replication errors
```

### AI/ML Metrics

```
model_inference_duration_ms: Histogram
├─ By model version
├─ By model type (ndvi, thermal, etc)
├─ P50, P99 latencies
└─ Errors

gpu_metrics: Gauge
├─ GPU utilization %
├─ GPU memory used (MB)
├─ GPU temperature (C)
└─ By GPU device

queue_metrics: Gauge
├─ Queue depth
├─ Jobs completed
├─ Jobs failed
└─ Avg wait time
```

### Business Metrics

```
crops_analyzed: Counter
├─ Daily count
├─ By user
├─ By crop type
└─ Success rate

analysis_completion: Counter
├─ Completed analyses
├─ Failed analyses
├─ Average time-to-completion

user_activity: Gauge
├─ Active users (daily/weekly)
├─ Logins
├─ API calls per user
```

### Storage Metrics

```
blob_storage_metrics: Gauge
├─ Total size by tier (Hot, Cool, Archive)
├─ Blob count
└─ Estimated monthly cost

database_size: Gauge
├─ Table sizes
├─ Index sizes
└─ Growth rate
```

---

## Log Levels & Examples

### INFO - Normal Operation

```json
{
  "level": "INFO",
  "timestamp": "2024-12-05T14:32:15Z",
  "event": "user_login",
  "user_id": 123,
  "email": "user@example.com",
  "ip": "192.168.1.100",
  "success": true
}

{
  "level": "INFO",
  "timestamp": "2024-12-05T14:35:42Z",
  "event": "crop_analysis_started",
  "crop_id": 456,
  "user_id": 123,
  "analysis_type": "ndvi",
  "model_version": "v2.1"
}

{
  "level": "INFO",
  "timestamp": "2024-12-05T14:36:10Z",
  "event": "model_inference_completed",
  "crop_id": 456,
  "inference_time_ms": 8234,
  "accuracy": 0.94,
  "gpu": "A100"
}
```

### WARNING - Unexpected Behavior

```json
{
  "level": "WARNING",
  "timestamp": "2024-12-05T14:37:15Z",
  "event": "slow_database_query",
  "duration_ms": 2340,
  "query": "SELECT * FROM crops WHERE user_id = ? AND status = ?",
  "rows_returned": 234,
  "threshold_ms": 1000
}

{
  "level": "WARNING",
  "timestamp": "2024-12-05T14:38:00Z",
  "event": "gpu_memory_high",
  "gpu_id": 0,
  "memory_used_mb": 7680,
  "memory_total_mb": 8000,
  "utilization_pct": 96
}

{
  "level": "WARNING",
  "timestamp": "2024-12-05T14:39:30Z",
  "event": "failed_login_attempts",
  "email": "attacker@example.com",
  "attempt_count": 5,
  "ip": "203.0.113.45",
  "time_window_min": 5
}
```

### ERROR - Operation Failed

```json
{
  "level": "ERROR",
  "timestamp": "2024-12-05T14:40:15Z",
  "event": "model_inference_failed",
  "crop_id": 456,
  "error": "CUDA out of memory",
  "gpu_memory_mb": 8000,
  "model_size_mb": 3500,
  "batch_size": 8
}

{
  "level": "ERROR",
  "timestamp": "2024-12-05T14:41:00Z",
  "event": "satellite_api_error",
  "error": "Timeout after 30 seconds",
  "satellite_api": "https://api.sentinel-hub.com",
  "crop_id": 789,
  "retry_count": 3
}

{
  "level": "ERROR",
  "timestamp": "2024-12-05T14:42:30Z",
  "event": "database_connection_lost",
  "error": "Connection refused",
  "host": "crop-ai-postgres.database.azure.com",
  "port": 5432
}
```

### CRITICAL - System at Risk

```json
{
  "level": "CRITICAL",
  "timestamp": "2024-12-05T14:45:00Z",
  "event": "postgres_replication_failed",
  "error": "Replication lag > 5 minutes",
  "primary_host": "crop-ai-postgres-primary",
  "replica_host": "crop-ai-postgres-replica",
  "lag_seconds": 301,
  "impact": "Standby cannot failover"
}

{
  "level": "CRITICAL",
  "timestamp": "2024-12-05T14:46:15Z",
  "event": "redis_cache_down",
  "error": "Connection refused",
  "host": "crop-ai-redis.redis.cache.azure.com",
  "port": 6379,
  "impact": "Job queue will fail"
}
```

---

## Monitoring Runbook

### Responding to Alerts

**Alert: High API Error Rate (>5%)**

```
1. Check dashboard: API Performance → Error Rate chart
2. Identify affected endpoints: Most recent errors query
3. Check database: Is PostgreSQL responding?
4. Check GPU: Is inference working?
5. Check logs: Look for patterns in error messages
6. Actions:
   └─ If DB issue: Check connection pool, restart if necessary
   └─ If GPU issue: Check memory, kill long-running processes
   └─ If code issue: Check recent deployments, rollback if needed
7. Once resolved: Add to incident report
```

**Alert: GPU Memory Near Limit (>90%)**

```
1. Check GPU: nvidia-smi (SSH to GPU worker)
2. Identify processes: ps aux | grep python
3. Check queue depth: How many jobs waiting?
4. Actions:
   └─ Scale: Add another GPU worker if queue > 50
   └─ Optimize: Check inference batch size
   └─ Clear: Kill stuck processes if necessary
5. Monitor: Watch GPU memory for 30 minutes
```

**Alert: Database Replication Lag (>30s)**

```
1. Check primary: SELECT * FROM pg_stat_replication;
2. Check replica: SELECT now() - pg_last_xact_replay_timestamp();
3. Check network: ping primary-host from replica
4. Actions:
   └─ If network: Check Azure NSG rules
   └─ If primary: Check write load, restart if necessary
   └─ If replica: Restart replication
5. Monitor: Ensure lag returns to <5 seconds
```

**Alert: Failed Login Attempts (>10 in 5 min)**

```
1. Security review: Check failed_login logs for IP pattern
2. Actions:
   └─ Single user: Temporary account lockout (1 hour)
   └─ Multiple IPs: IP blocking at Azure WAF level
   └─ Automated: Trigger rate limiting
3. Notify: Security team of potential attack
4. Monitor: Watch for continuation of attacks
```

---

## KQL Query Reference

### Top Slow Queries (Last 1 Hour)

```kusto
customMetrics
| where name == "db_query_latency_ms" and timestamp > ago(1h)
| where todynamic(customDimensions).duration_ms > 1000
| summarize
    Count=count(),
    AvgDuration=avg(todouble(value)),
    MaxDuration=max(todouble(value))
    by tostring(customDimensions.query)
| order by AvgDuration desc
```

### Request Latency Percentiles (Last 24 Hours)

```kusto
requests
| where timestamp > ago(24h)
| summarize
    P50=percentile(duration, 50),
    P95=percentile(duration, 95),
    P99=percentile(duration, 99),
    P999=percentile(duration, 999)
    by name
| order by P99 desc
```

### Error Rate by Endpoint (Last 1 Hour)

```kusto
requests
| where timestamp > ago(1h)
| summarize
    TotalRequests=sum(itemCount),
    FailedRequests=sum(itemCount * iif(success==false, 1, 0)),
    ErrorRate=toreal(sum(itemCount * iif(success==false, 1, 0))) / sum(itemCount) * 100
    by name
| where ErrorRate > 0
| order by ErrorRate desc
```

### GPU Memory Usage (Last 6 Hours)

```kusto
customMetrics
| where name == "gpu_memory_mb" and timestamp > ago(6h)
| make-series AvgMemory=avg(todouble(value)) on timestamp from ago(6h) to now() step 10m
| render timechart
```

### Crops Analyzed by Day (Last 30 Days)

```kusto
customMetrics
| where name == "crops_analyzed_total" and timestamp > ago(30d)
| make-series CompletedCount=sum(todouble(value)) on timestamp from ago(30d) to now() step 1d
| render barchart
```

### Failed Analysis Reasons (Last 7 Days)

```kusto
customEvents
| where name == "analysis_failed" and timestamp > ago(7d)
| summarize Count=count() by tostring(customDimensions.error_type)
| order by Count desc
```

---

## Implementation Checklist

### Phase 1: Setup Log Analytics (Day 1)
- [ ] Create Log Analytics workspace
- [ ] Create Application Insights resource
- [ ] Get connection string
- [ ] Test connectivity

### Phase 2: Instrument Application (Day 1-2)
- [ ] Install OpenTelemetry packages
- [ ] Configure Azure exporter
- [ ] Instrument FastAPI
- [ ] Instrument database layer (SQLAlchemy)
- [ ] Instrument Redis client
- [ ] Add structured logging to code
- [ ] Define custom metrics
- [ ] Test logging & metrics locally

### Phase 3: Dashboards (Day 2)
- [ ] Create API health dashboard
- [ ] Create AI/ML dashboard
- [ ] Create business metrics dashboard
- [ ] Create database health dashboard
- [ ] Create infrastructure dashboard

### Phase 4: Alerts (Day 2)
- [ ] Configure high error rate alert
- [ ] Configure slow API alert
- [ ] Configure GPU memory alert
- [ ] Configure inference timeout alert
- [ ] Configure database health alert
- [ ] Test alert notifications

### Phase 5: Runbooks & Training (Day 3)
- [ ] Write alert response runbooks
- [ ] Create KQL query reference guide
- [ ] Train team on dashboards
- [ ] Document monitoring procedures

---

## Cost Optimization Tips

### 1. Reduce Log Volume
```python
# Only log important events
if severity in ["WARNING", "ERROR", "CRITICAL"]:
    logger.log(severity, message)

# Or sample DEBUG logs
import random
if log_level == "DEBUG" and random.random() < 0.1:  # 10% sampling
    logger.debug(message)
```

### 2. Use Log Retention Policies
```
30 days: Hot (searchable) = $2.99/GB
30-90 days: Archive = $0.50/GB
90+ days: Delete or move to cold storage
```

### 3. Filter Unnecessary Logs
```
✓ Keep: Errors, warnings, performance events
✗ Skip: Debug logs, routine operations, health checks
```

### 4. Use Metric Aggregation
```
✓ Store: Aggregated metrics (avg, p99)
✗ Store: Every raw measurement (too much data)
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Recommended Technology** | Azure Log Analytics |
| **Setup Time** | 1 hour |
| **MVP Cost** | $30-50/month |
| **Growth Cost** | $75-125/month |
| **Key Features** | Logs, Metrics, Traces, Dashboards, Alerts |
| **Retention** | 30 days (configurable, with archival) |
| **Query Language** | KQL (Kusto) |
| **Alert Integration** | Email, SMS, Webhooks, Logic Apps |
| **Deployment** | Week 3 of MVP |

---

**Status:** ✅ Three Priority Decisions Complete!

**All three priority decision documents are now ready:**
1. ✅ Authentication & Authorization (JWT + PostgreSQL, MVP-ready)
2. ✅ Blob Storage & Lifecycle (Azure Blob, 83.5% cost savings with tiering)
3. ✅ Logging & Observability (Azure Log Analytics, comprehensive monitoring)

**Next:** Commit these to GitHub and then proceed to implementation decisions.
