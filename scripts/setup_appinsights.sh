#!/bin/bash
# Setup Application Insights for crop-ai service
# Usage: ./setup_appinsights.sh <resource-group> <location>

set -e

RESOURCE_GROUP=${1:-crop-ai-rg}
LOCATION=${2:-eastus}
APP_NAME="crop-ai-insights"

echo "🔧 Setting up Application Insights for crop-ai..."

# Check if resource group exists, create if not
if ! az group exists --name "$RESOURCE_GROUP" | grep -q true; then
    echo "📦 Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    echo "✓ Resource group $RESOURCE_GROUP already exists"
fi

# Create Application Insights resource
echo "📊 Creating Application Insights resource: $APP_NAME"
APP_INSIGHTS=$(az monitor app-insights component create \
    --app "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --kind web \
    --query id \
    --output tsv)

echo "✓ Application Insights created: $APP_INSIGHTS"

# Get connection string
echo "🔑 Retrieving connection string..."
CONNECTION_STRING=$(az monitor app-insights component show \
    --app "$APP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query connectionString \
    --output tsv)

echo "✓ Connection String: $CONNECTION_STRING"

# Create GitHub Actions secret
echo "🔐 Setting GitHub Actions secret..."
REPO_URL=$(git config --get remote.origin.url | sed 's/.*[:/]\(.*\)\/\(.*\).git/\1\/\2/')
echo ""
echo "📋 To set this in GitHub Actions:"
echo "   1. Go to: https://github.com/$REPO_URL/settings/secrets/actions"
echo "   2. Click 'New repository secret'"
echo "   3. Name: APPINSIGHTS_CONNECTION_STRING"
echo "   4. Value: $CONNECTION_STRING"
echo ""

# Save to .env file (for local development)
echo "💾 Saving to .env file..."
echo "APPINSIGHTS_CONNECTION_STRING=$CONNECTION_STRING" >> .env
echo "ENVIRONMENT=development" >> .env

echo ""
echo "✅ Application Insights setup complete!"
echo ""
echo "📖 Next steps:"
echo "   1. Add the connection string to GitHub Actions secrets"
echo "   2. Update your Docker deployment with the connection string"
echo "   3. View dashboard at: https://portal.azure.com"
echo ""
echo "🎯 To deploy with Application Insights:"
echo "   az container create \\"
echo "     --resource-group $RESOURCE_GROUP \\"
echo "     --name crop-ai-app \\"
echo "     --image <registry>/crop-ai:latest \\"
echo "     --environment-variables APPINSIGHTS_CONNECTION_STRING='$CONNECTION_STRING'"
echo ""
