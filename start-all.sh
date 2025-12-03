#!/bin/bash

set -e

echo "🚀 Starting Crop AI Full Stack..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to wait for port to be available
wait_for_port() {
    local port=$1
    local service=$2
    local max_attempts=30
    local attempt=0
    
    echo "⏳ Waiting for $service on port $port..."
    while ! lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "❌ $service failed to start on port $port"
            return 1
        fi
        echo -n "."
        sleep 1
    done
    echo -e " ${GREEN}✓${NC}"
}

# Create log directory
mkdir -p /tmp/crop-ai-logs

# Terminal 1: FastAPI Backend
echo -e "${YELLOW}Starting FastAPI Backend (port 5000)...${NC}"
cd /workspaces/crop-ai
nohup python -m uvicorn src.crop_ai.api:app --host 0.0.0.0 --port 5000 > /tmp/crop-ai-logs/fastapi.log 2>&1 &
FASTAPI_PID=$!
wait_for_port 5000 "FastAPI" || exit 1
echo -e "${GREEN}✓ FastAPI running (PID: $FASTAPI_PID)${NC}"

# Terminal 2: Django Backend
echo -e "${YELLOW}Starting Django Gateway (port 8000)...${NC}"
cd /workspaces/crop-ai/frontend
nohup python manage.py runserver 0.0.0.0:8000 > /tmp/crop-ai-logs/django.log 2>&1 &
DJANGO_PID=$!
wait_for_port 8000 "Django" || exit 1
echo -e "${GREEN}✓ Django running (PID: $DJANGO_PID)${NC}"

# Terminal 3: Angular Frontend
echo -e "${YELLOW}Starting Angular Frontend (port 4200)...${NC}"
cd /workspaces/crop-ai/frontend/angular
nohup npm start > /tmp/crop-ai-logs/angular.log 2>&1 &
ANGULAR_PID=$!
wait_for_port 4200 "Angular" || exit 1
echo -e "${GREEN}✓ Angular running (PID: $ANGULAR_PID)${NC}"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}✓ All Services Running!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "📋 Service URLs:"
echo -e "   FastAPI Backend:  http://localhost:5000"
echo -e "   Django Gateway:   http://localhost:8000"
echo -e "   Angular Frontend: http://localhost:4200"
echo ""
echo "🌐 Open your browser: http://localhost:4200"
echo ""
echo "📊 Logs:"
echo "   FastAPI:  tail -f /tmp/crop-ai-logs/fastapi.log"
echo "   Django:   tail -f /tmp/crop-ai-logs/django.log"
echo "   Angular:  tail -f /tmp/crop-ai-logs/angular.log"
echo ""
echo "🛑 To stop all services:"
echo "   pkill -f 'uvicorn|manage.py runserver|ng serve'"
echo ""

# Keep script running
echo "Press CTRL+C to stop all services..."
wait
