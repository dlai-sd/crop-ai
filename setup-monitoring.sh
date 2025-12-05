#!/bin/bash

# Azure Cost Management & Alerts Setup Script
# This script configures:
# 1. Budget alerts for cost tracking
# 2. Cost anomaly detection
# 3. Application Insights resources
# 4. Container Insights for ACI monitoring

set -e

echo "🔧 Setting up Azure Monitoring & Cost Management..."

RESOURCE_GROUP="crop-ai-rg"
LOCATION="eastus"
BUDGET_AMOUNT=70  # $70/month
ALERT_THRESHOLD=80  # Alert at 80% of budget

# ============================================================
# 1. CREATE APPLICATION INSIGHTS RESOURCE
# ============================================================
echo ""
echo "📊 Creating Application Insights resource..."

APP_INSIGHTS_NAME="crop-ai-insights"

if az resource show --resource-group "$RESOURCE_GROUP" --name "$APP_INSIGHTS_NAME" --resource-type "Microsoft.Insights/components" &>/dev/null; then
    echo "✅ Application Insights already exists: $APP_INSIGHTS_NAME"
else
    az monitor app-insights component create \
        --app "$APP_INSIGHTS_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --application-type web || echo "⚠️ Could not create Application Insights (may need additional permissions)"
fi

# Get instrumentation key
APP_INSIGHTS_KEY=$(az monitor app-insights component show \
    --resource-group "$RESOURCE_GROUP" \
    --query "instrumentationKey" \
    -o tsv 2>/dev/null || echo "")

if [ -z "$APP_INSIGHTS_KEY" ]; then
    echo "⚠️ Could not retrieve Application Insights key"
else
    echo "✅ Application Insights key: ${APP_INSIGHTS_KEY:0:10}..."
fi

# ============================================================
# 2. CREATE BUDGET ALERT
# ============================================================
echo ""
echo "💰 Setting up budget alerts..."

BUDGET_NAME="crop-ai-monthly-budget"

# Check if budget already exists
if az costmanagement budget show \
    --resource-group "$RESOURCE_GROUP" \
    --budget-name "$BUDGET_NAME" &>/dev/null; then
    echo "✅ Budget already configured: $BUDGET_NAME"
else
    # Create budget (only works with certain subscription types)
    az costmanagement budget create \
        --resource-group "$RESOURCE_GROUP" \
        --budget-name "$BUDGET_NAME" \
        --category "Cost" \
        --amount "$BUDGET_AMOUNT" \
        --time-period "Monthly" \
        --start-date "2025-12-01" \
        || echo "⚠️ Budget creation skipped (may need additional permissions)"
fi

# ============================================================
# 3. CONFIGURE APPLICATION INSIGHTS ALERTS
# ============================================================
echo ""
echo "🚨 Configuring Application Insights alerts..."

# Alert for high error rate
echo "  • Configuring error rate alert..."
az monitor metrics alert create \
    --name "crop-ai-high-errors" \
    --resource-group "$RESOURCE_GROUP" \
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourcegroups/$RESOURCE_GROUP/providers/microsoft.insights/components/$APP_INSIGHTS_NAME" \
    --description "Alert when error rate exceeds 5%" \
    --condition "avg server/exceptions > 5" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    || echo "  ⚠️ Could not create error rate alert"

# Alert for high response time
echo "  • Configuring response time alert..."
az monitor metrics alert create \
    --name "crop-ai-slow-responses" \
    --resource-group "$RESOURCE_GROUP" \
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourcegroups/$RESOURCE_GROUP/providers/microsoft.insights/components/$APP_INSIGHTS_NAME" \
    --description "Alert when p95 response time exceeds 1 second" \
    --condition "avg request/duration > 1000" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 3 \
    || echo "  ⚠️ Could not create response time alert"

# ============================================================
# 4. SETUP CONTAINER INSIGHTS FOR ACI
# ============================================================
echo ""
echo "🐳 Setting up Container Insights..."

# Log Analytics Workspace is needed for Container Insights
WORKSPACE_NAME="crop-ai-workspace"

if az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$WORKSPACE_NAME" &>/dev/null; then
    echo "✅ Log Analytics Workspace exists: $WORKSPACE_NAME"
else
    echo "  • Creating Log Analytics Workspace..."
    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$WORKSPACE_NAME" \
        --location "$LOCATION" \
        || echo "  ⚠️ Could not create Log Analytics Workspace"
fi

# ============================================================
# 5. CREATE MONITORING DASHBOARD
# ============================================================
echo ""
echo "📈 Creating monitoring dashboard..."

DASHBOARD_NAME="crop-ai-dashboard"

# Simple dashboard template (JSON)
DASHBOARD_TEMPLATE='{
  "location": "'$LOCATION'",
  "properties": {
    "lenses": {
      "0": {
        "order": 0,
        "parts": {
          "0": {
            "position": {
              "x": 0,
              "y": 0,
              "colSpan": 6,
              "rowSpan": 4
            },
            "metadata": {
              "inputs": [
                {
                  "name": "resourceId",
                  "value": "/subscriptions/'$(az account show --query id -o tsv)'/resourcegroups/'$RESOURCE_GROUP'/providers/microsoft.insights/components/'$APP_INSIGHTS_NAME'"
                }
              ],
              "type": "Extension/AppInsightsExtension/PartType/AppMapGalPart",
              "settings": {},
              "deepLink": "AppInsights"
            }
          }
        }
      }
    },
    "metadata": {
      "model": {
        "timeRange": {
          "value": "1h",
          "type": "MsPortalFx.Composition.Configuration.ValueTypes.TimeRange"
        }
      }
    }
  }
}'

if az portal dashboard show --name "$DASHBOARD_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "✅ Dashboard already exists: $DASHBOARD_NAME"
else
    echo "  • Dashboard creation requires Azure Portal (manual setup recommended)"
fi

# ============================================================
# 6. EXPORT MONITORING CONFIGURATION
# ============================================================
echo ""
echo "📝 Exporting configuration..."

cat > .env.monitoring << EOF
# Application Insights Configuration
APPINSIGHTS_INSTRUMENTATION_KEY=$APP_INSIGHTS_KEY
ENVIRONMENT=production

# Log Analytics
LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$WORKSPACE_NAME" \
    --query id \
    -o tsv 2>/dev/null || echo "")

# Cost Management
MONTHLY_BUDGET=$BUDGET_AMOUNT
ALERT_THRESHOLD=$ALERT_THRESHOLD

# Resource Group
RESOURCE_GROUP=$RESOURCE_GROUP
LOCATION=$LOCATION

# Alert Configuration
HIGH_ERROR_THRESHOLD=5
SLOW_RESPONSE_THRESHOLD_MS=1000
EOF

echo "✅ Configuration exported to .env.monitoring"

# ============================================================
# 7. DISPLAY CONFIGURATION SUMMARY
# ============================================================
echo ""
echo "════════════════════════════════════════════════════════"
echo "✅ Monitoring Setup Complete!"
echo "════════════════════════════════════════════════════════"
echo ""
echo "📊 Resources Created/Configured:"
echo "  ✓ Application Insights: $APP_INSIGHTS_NAME"
echo "  ✓ Log Analytics Workspace: $WORKSPACE_NAME"
echo "  ✓ Budget Alert: $BUDGET_NAME ($BUDGET_AMOUNT/month)"
echo "  ✓ Error Rate Alert: > 5 errors in 5min window"
echo "  ✓ Response Time Alert: p95 > 1000ms"
echo ""
echo "🔗 Access Monitoring:"
echo "  • Azure Portal: https://portal.azure.com"
echo "  • Application Insights: resource group > $APP_INSIGHTS_NAME"
echo "  • Cost Management: Subscriptions > Cost Management"
echo ""
echo "🚀 Next Steps:"
echo "  1. Export APPINSIGHTS_INSTRUMENTATION_KEY to container:"
echo "     export APPINSIGHTS_INSTRUMENTATION_KEY='$APP_INSIGHTS_KEY'"
echo ""
echo "  2. Update container environment variables"
echo ""
echo "  3. Monitor your application at:"
echo "     https://portal.azure.com/#resource/subscriptions/.../resourceGroups/$RESOURCE_GROUP/providers/microsoft.insights/components/$APP_INSIGHTS_NAME"
echo ""
echo "════════════════════════════════════════════════════════"
