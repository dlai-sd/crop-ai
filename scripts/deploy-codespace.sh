#!/bin/bash
set -e

echo "🚀 Deploying to Codespace..."
echo "============================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Kill any existing processes
echo "Cleaning up existing processes..."
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "python manage.py" 2>/dev/null || true
pkill -f "ng serve" 2>/dev/null || true
sleep 2

# Create log directory
mkdir -p /tmp/crop-ai-logs

# Start Backend (FastAPI)
echo -e "\n${YELLOW}Starting FastAPI Backend (port 5000)...${NC}"
cd /workspaces/crop-ai
nohup python -m uvicorn src.crop_ai.api:app --host 0.0.0.0 --port 5000 > /tmp/crop-ai-logs/fastapi.log 2>&1 &
BACKEND_PID=$!
echo "Backend PID: $BACKEND_PID"

# Wait for backend to be ready
echo "Waiting for FastAPI backend to start..."
sleep 5
for i in {1..30}; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ FastAPI backend is running on port 5000${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Start Django Gateway
echo -e "\n${YELLOW}Starting Django Gateway (port 8000)...${NC}"
cd /workspaces/crop-ai/frontend
nohup python manage.py runserver 0.0.0.0:8000 > /tmp/crop-ai-logs/django.log 2>&1 &
DJANGO_PID=$!
echo "Django PID: $DJANGO_PID"

# Wait for Django to be ready
echo "Waiting for Django to start..."
sleep 5
for i in {1..30}; do
    if curl -s http://localhost:8000/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Django gateway is running on port 8000${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Start Angular Dev Server
echo -e "\n${YELLOW}Starting Angular Dev Server (port 4200)...${NC}"
cd /workspaces/crop-ai/frontend/angular
nohup npm start > /tmp/crop-ai-logs/angular.log 2>&1 &
ANGULAR_PID=$!
echo "Angular PID: $ANGULAR_PID"

# Wait for Angular to be ready
echo "Waiting for Angular to compile..."
sleep 30
for i in {1..60}; do
    if curl -s http://localhost:4200/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Angular dev server is running on port 4200${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Display URLs
echo -e "\n${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo "📍 Local Access URLs:"
echo "  Frontend: http://localhost:4200"
echo "  Backend: http://localhost:5000"
echo "  Django Gateway: http://localhost:8000"
echo ""
echo "🌐 Codespace Public URLs:"
CODESPACE_NAME=$(echo $CODESPACE_NAME)
if [ -z "$CODESPACE_NAME" ]; then
    echo "  (Run this in Codespace terminal to see public URLs)"
else
    echo "  Frontend: https://${CODESPACE_NAME}-4200.app.github.dev"
    echo "  Backend: https://${CODESPACE_NAME}-5000.app.github.dev"
    echo "  Django Gateway: https://${CODESPACE_NAME}-8000.app.github.dev"
fi
echo ""
echo "📋 Process IDs:"
echo "  FastAPI: $BACKEND_PID"
echo "  Django: $DJANGO_PID"
echo "  Angular: $ANGULAR_PID"
echo ""
echo "📂 Logs:"
echo "  FastAPI: /tmp/crop-ai-logs/fastapi.log"
echo "  Django: /tmp/crop-ai-logs/django.log"
echo "  Angular: /tmp/crop-ai-logs/angular.log"
echo ""
echo "To stop all services, run: pkill -f 'uvicorn\|manage.py runserver\|ng serve'"
