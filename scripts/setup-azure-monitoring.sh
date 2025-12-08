#!/bin/bash
set -e

echo "📊 Setting up Azure Monitoring..."
echo "=================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if logged in to Azure
if ! az account show > /dev/null 2>&1; then
    echo -e "${YELLOW}Please login to Azure:${NC}"
    az login
fi

# Get resource group
RG_NAME="crop-ai-rg"

echo -e "\n${BLUE}Creating Application Insights...${NC}"

# Create Application Insights
APPINSIGHTS_NAME="crop-ai-insights"
az monitor app-insights component create \
    --app $APPINSIGHTS_NAME \
    --resource-group $RG_NAME \
    --application-type "web" \
    --kind "web" \
    2>/dev/null || echo "Application Insights may already exist"

# Get instrumentation key
INSTRUMENTATION_KEY=$(az monitor app-insights component show \
    --app $APPINSIGHTS_NAME \
    --resource-group $RG_NAME \
    --query 'instrumentationKey' -o tsv 2>/dev/null || echo "")

if [ -n "$INSTRUMENTATION_KEY" ]; then
    echo -e "${GREEN}✅ Application Insights Instrumentation Key: ${NC}$INSTRUMENTATION_KEY"
fi

echo -e "\n${BLUE}Creating Log Analytics Workspace...${NC}"

# Create Log Analytics workspace
WORKSPACE_NAME="crop-ai-logs"
az monitor log-analytics workspace create \
    --resource-group $RG_NAME \
    --workspace-name $WORKSPACE_NAME \
    2>/dev/null || echo "Log Analytics workspace may already exist"

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group $RG_NAME \
    --workspace-name $WORKSPACE_NAME \
    --query 'id' -o tsv 2>/dev/null || echo "")

if [ -n "$WORKSPACE_ID" ]; then
    echo -e "${GREEN}✅ Log Analytics Workspace ID: ${NC}$WORKSPACE_ID"
fi

echo -e "\n${BLUE}Creating Alert Rules...${NC}"

# Backend API Alert - High error rate
az monitor metrics alert create \
    --name "crop-ai-backend-errors" \
    --resource-group $RG_NAME \
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/crop-ai-backend-latest" \
    --condition "avg http_server_requests_seconds_sum > 1000" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    2>/dev/null || echo "Alert may already exist"

# System CPU Alert
az monitor metrics alert create \
    --name "crop-ai-system-cpu" \
    --resource-group $RG_NAME \
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME" \
    --condition "avg Percentage CPU > 80" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    2>/dev/null || echo "Alert may already exist"

# System Memory Alert
az monitor metrics alert create \
    --name "crop-ai-system-memory" \
    --resource-group $RG_NAME \
    --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME" \
    --condition "avg Memory % > 85" \
    --window-size 5m \
    --evaluation-frequency 1m \
    --severity 2 \
    2>/dev/null || echo "Alert may already exist"

echo -e "\n${BLUE}Creating Diagnostic Settings...${NC}"

# Enable diagnostics for container instances
CONTAINER_GROUPS=$(az container list --resource-group $RG_NAME --query "[].name" -o tsv)

for cg in $CONTAINER_GROUPS; do
    az monitor diagnostic-settings create \
        --name "${cg}-diagnostics" \
        --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/$cg" \
        --logs '[{"category": "ContainerInstanceLogs", "enabled": true}]' \
        --metrics '[{"category": "AllMetrics", "enabled": true}]' \
        --workspace $WORKSPACE_ID \
        2>/dev/null || echo "Diagnostics for $cg may already be configured"
done

echo -e "\n${GREEN}✅ Azure Monitoring Setup Complete!${NC}"
echo ""
echo "📊 Azure Monitor URLs:"
echo "   Application Insights: https://portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/microsoft.insights/components/$APPINSIGHTS_NAME"
echo "   Log Analytics: https://portal.azure.com/#@microsoft.onmicrosoft.com/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/microsoft.operationalinsights/workspaces/$WORKSPACE_NAME"
echo ""
echo "Environment variables to add to deployment:"
echo "   APPLICATIONINSIGHTS_INSTRUMENTATION_KEY=$INSTRUMENTATION_KEY"
echo "   WORKSPACE_ID=$WORKSPACE_ID"
