# Application Insights Dashboard Setup

## Overview

This guide explains how to set up and configure Azure Application Insights dashboards for monitoring the crop-ai service.

## Prerequisites

1. **Azure Subscription** with Application Insights resource
2. **Connection String** from Application Insights resource
3. **Environment Variable** set in deployment

## Quick Setup

### 1. Create Application Insights Resource (Azure Portal)

```bash
# Using Azure CLI
az monitor app-insights component create \
  --app crop-ai-insights \
  --resource-group <your-resource-group> \
  --location eastus \
  --kind web
```

### 2. Get Connection String

```bash
az monitor app-insights component show \
  --app crop-ai-insights \
  --resource-group <your-resource-group> \
  --query connectionString
```

### 3. Set Environment Variable

In your Azure Container Instances deployment or local environment:

```bash
export APPINSIGHTS_CONNECTION_STRING="<your-connection-string>"
```

In `Dockerfile`:
```dockerfile
ENV APPINSIGHTS_CONNECTION_STRING=${APPINSIGHTS_CONNECTION_STRING}
```

In GitHub Actions secrets, add:
```
APPINSIGHTS_CONNECTION_STRING = <your-connection-string>
```

## Dashboard Configuration

### Creating Custom Dashboard

1. Go to **Application Insights** → **Dashboards**
2. Click **+ New Dashboard**
3. Name it `crop-ai Monitoring`
4. Add the following tiles:

#### Tile 1: Predictions Overview
- **Chart Type**: Area Chart
- **Metric**: Events (PredictionSuccess)
- **Aggregation**: Count
- **Time Range**: Last 24 hours
- **Split by**: crop_type

```
customEvents
| where name == "PredictionSuccess"
| summarize Count = count() by tostring(customDimensions.crop_type), bin(timestamp, 1h)
| render areachart
```

#### Tile 2: Prediction Performance
- **Chart Type**: Scatter Chart
- **Metric**: Confidence vs Processing Time
- **Aggregation**: Average

```
customEvents
| where name == "PredictionSuccess"
| extend confidence = toreal(customMeasurements.confidence)
| extend processing_time = toreal(customMeasurements.processing_time_ms)
| render scatterchart
```

#### Tile 3: Health Status Timeline
- **Chart Type**: Bar Chart
- **Metric**: Health Status (Healthy/Degraded)
- **Time Range**: Last 7 days

```
customEvents
| where name == "HealthCheck"
| summarize Count = count() by status = tostring(customDimensions.status), bin(timestamp, 1h)
| render barchart
```

#### Tile 4: System Resource Usage
- **Chart Type**: Line Chart
- **Metrics**: CPU % and Memory %
- **Time Range**: Last 24 hours

```
customEvents
| where name == "HealthCheck"
| extend cpu = toreal(customMeasurements.cpu_percent)
| extend memory = toreal(customMeasurements.memory_percent)
| summarize AvgCPU = avg(cpu), AvgMemory = avg(memory) by bin(timestamp, 5m)
| render linechart
```

#### Tile 5: Error Rate
- **Chart Type**: Single Value
- **Metric**: Failed Predictions
- **Time Range**: Last 24 hours

```
customEvents
| where name == "PredictionFailure"
| count
```

#### Tile 6: Average Confidence Score
- **Chart Type**: Single Value
- **Metric**: Mean Confidence

```
customEvents
| where name == "PredictionSuccess"
| extend confidence = toreal(customMeasurements.confidence)
| summarize AvgConfidence = avg(confidence)
```

## KQL (Kusto Query Language) Queries

### Key Queries for Analysis

**Prediction Statistics**
```
customEvents
| where name in ("PredictionSuccess", "PredictionFailure")
| summarize 
    TotalCount = count(),
    SuccessCount = sumif(1, name == "PredictionSuccess"),
    FailureCount = sumif(1, name == "PredictionFailure"),
    AvgConfidence = avg(todouble(customMeasurements.confidence)),
    AvgProcessingTime = avg(customMeasurements.processing_time_ms)
    by bin(timestamp, 1d)
```

**Crop Distribution**
```
customEvents
| where name == "PredictionSuccess"
| summarize Count = count() by crop_type = tostring(customDimensions.crop_type)
| render piechart
```

**Performance by Model Version**
```
customEvents
| where name == "PredictionSuccess"
| extend processing_time = toreal(customMeasurements.processing_time_ms)
| summarize 
    Count = count(),
    AvgTime = avg(processing_time),
    P95Time = percentile(processing_time, 95)
    by model_version = tostring(customDimensions.model_version)
```

**Health Degradation Trends**
```
customEvents
| where name == "HealthCheck"
| summarize 
    HealthyCount = sumif(1, customDimensions.status == "healthy"),
    DegradedCount = sumif(1, customDimensions.status == "degraded")
    by bin(timestamp, 1h)
```

**Exceptions and Errors**
```
exceptions
| summarize 
    Count = count(),
    Types = dcount(type)
    by bin(timestamp, 1d)
| render areachart
```

**Dependencies (Database, API calls)**
```
availabilityResults
| summarize 
    Count = count(),
    AvgDuration = avg(duration),
    FailureRate = (sumif(1, success == false) / count()) * 100
    by bin(timestamp, 1h)
```

## Alerts Setup

### Critical Alert: High Error Rate

```
customEvents
| where name == "PredictionFailure"
| summarize FailureRate = count() / (count() + (
    customEvents
    | where name == "PredictionSuccess"
    | count
)) by bin(timestamp, 5m)
| where FailureRate > 0.1
```

**Alert Threshold**: > 10% failure rate
**Time Window**: 5 minutes
**Action**: Send email notification

### Warning Alert: Degraded Health

```
customEvents
| where name == "HealthCheck"
| where customDimensions.status == "degraded"
| summarize Count = count() by bin(timestamp, 5m)
| where Count > 5
```

**Alert Threshold**: > 5 consecutive degraded checks
**Time Window**: 5 minutes
**Action**: Send email notification

### Performance Alert: High Processing Time

```
customEvents
| where name == "PredictionSuccess"
| extend processing_time = toreal(customMeasurements.processing_time_ms)
| summarize P95Time = percentile(processing_time, 95) by bin(timestamp, 5m)
| where P95Time > 5000
```

**Alert Threshold**: P95 > 5 seconds
**Time Window**: 5 minutes
**Action**: Investigate resource constraints

## Deployment Integration

### Update Dockerfile

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY src ./src

# Set Application Insights connection string
ARG APPINSIGHTS_CONNECTION_STRING
ENV APPINSIGHTS_CONNECTION_STRING=${APPINSIGHTS_CONNECTION_STRING}

# Run FastAPI with uvicorn
CMD ["uvicorn", "crop_ai.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Update GitHub Actions Workflow

```yaml
# In .github/workflows/ci.yml
- name: Deploy to Azure Container Instances
  if: success() && github.event_name == 'push' && github.ref == 'refs/heads/main'
  uses: azure/CLI@v1
  with:
    azcliversion: 2.42.0
    inlineScript: |
      az container create \
        --resource-group ${{ secrets.AZURE_RESOURCE_GROUP }} \
        --name crop-ai-app \
        --image ${{ env.REGISTRY_URL }}/crop-ai:latest \
        --registry-login-server ${{ env.REGISTRY_URL }} \
        --registry-username ${{ env.REGISTRY_USERNAME }} \
        --registry-password ${{ secrets.REGISTRY_PASSWORD }} \
        --dns-name-label crop-ai-app \
        --ports 8000 \
        --environment-variables \
          APPINSIGHTS_CONNECTION_STRING=${{ secrets.APPINSIGHTS_CONNECTION_STRING }} \
          ENVIRONMENT=production
```

## Monitoring the Dashboard

### Expected Metrics

1. **Prediction Success Rate**: Should be > 95%
2. **Average Processing Time**: Should be < 1000ms
3. **Average Confidence**: Should be > 0.80
4. **System Resources**: CPU < 80%, Memory < 85%
5. **Health Status**: Should remain "healthy"

### Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| No data in dashboard | Connection string not set | Verify APPINSIGHTS_CONNECTION_STRING env var |
| Missing metrics | SDK not installed | Check requirements.txt has applicationinsights |
| Events not appearing | Telemetry not initialized | Verify init_telemetry_logging() called in startup |
| High latency | Resource constraints | Check CPU/memory metrics, scale container |
| Prediction failures | Model error | Check logs in Application Insights exceptions tab |

## Next Steps

1. **Create Alerts** - Set up email notifications for critical metrics
2. **Configure Actions** - Link alerts to incident management tools
3. **Export Data** - Use continuous export for long-term analysis
4. **Integrate with Teams** - Send notifications to Microsoft Teams channel
5. **Auto-scaling** - Use metrics to trigger Azure auto-scale policies

## References

- [Application Insights Documentation](https://docs.microsoft.com/azure/azure-monitor/app/app-insights-overview)
- [KQL Query Language](https://docs.microsoft.com/azure/data-explorer/kusto/query)
- [Dashboard Creation Guide](https://docs.microsoft.com/azure/azure-monitor/app/create-new-resource#create-an-application-insights-resource)
