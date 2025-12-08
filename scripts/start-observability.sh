#!/bin/bash
set -e

echo "🔍 Starting Observability Stack..."
echo "=================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create log directory
mkdir -p /tmp/crop-ai-logs

cd /workspaces/crop-ai/monitoring

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker not available. Install Docker to use full observability stack.${NC}"
    echo "Proceeding with local tools only..."
else
    echo -e "\n${BLUE}Starting Docker Compose services...${NC}"
    
    # Start observability stack
    docker-compose up -d
    
    # Wait for services to be ready
    echo "Waiting for services to initialize..."
    sleep 10
    
    echo -e "\n${GREEN}✅ Observability Stack Running:${NC}"
    echo ""
    echo "📊 Prometheus (Metrics Collection)"
    echo "   URL: http://localhost:9090"
    echo "   Targets: /api/v1/targets"
    echo ""
    echo "📈 Grafana (Dashboards)"
    echo "   URL: http://localhost:3001"
    echo "   User: admin"
    echo "   Password: admin"
    echo ""
    echo "📝 Loki (Log Aggregation)"
    echo "   URL: http://localhost:3100"
    echo ""
    echo "🔍 Jaeger (Distributed Tracing)"
    echo "   URL: http://localhost:16686"
    echo ""
    echo "🚨 AlertManager"
    echo "   URL: http://localhost:9093"
    echo ""
fi

echo -e "\n${BLUE}Starting Application Monitoring...${NC}"

# Python observability instrumentation
pip install prometheus-client python-json-logger structlog -q 2>/dev/null || true

echo -e "\n${GREEN}✅ Observability Infrastructure Ready!${NC}"
echo ""
echo "📊 Access via Codespace URLs:"
echo "   Prometheus: https://\${CODESPACE_NAME}-9090.app.github.dev"
echo "   Grafana: https://\${CODESPACE_NAME}-3001.app.github.dev"
echo "   Loki: https://\${CODESPACE_NAME}-3100.app.github.dev"
echo "   Jaeger: https://\${CODESPACE_NAME}-16686.app.github.dev"
echo "   AlertManager: https://\${CODESPACE_NAME}-9093.app.github.dev"
echo ""
echo "📂 Log files:"
echo "   FastAPI: /tmp/crop-ai-logs/fastapi.log"
echo "   Django: /tmp/crop-ai-logs/django.log"
echo "   Angular: /tmp/crop-ai-logs/angular.log"
echo ""
echo "To stop observability stack:"
echo "   cd /workspaces/crop-ai/monitoring && docker-compose down"
