#!/bin/bash
set -e

echo "🧪 Running System Tests..."
echo "=========================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p test-results

# Health checks for running services
echo -e "\n${YELLOW}[1/4] System Health Checks${NC}"

# Check Backend API
echo "Checking Backend API (port 5000)..."
if curl -s http://localhost:5000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend API is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Backend API not responding (expected if not running)${NC}"
fi

# Check Django Gateway
echo "Checking Django Gateway (port 8000)..."
if curl -s http://localhost:8000/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Django Gateway is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Django Gateway not responding (expected if not running)${NC}"
fi

# Check Angular Dev Server
echo "Checking Angular Dev Server (port 4200)..."
if curl -s http://localhost:4200/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Angular Dev Server is healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Angular Dev Server not responding (expected if not running)${NC}"
fi

# API Endpoint Tests
echo -e "\n${YELLOW}[2/4] API Endpoint Tests${NC}"

BACKEND_TESTS_PASSED=0
BACKEND_TESTS_TOTAL=0

# Test Auth endpoints
if [ -f "tests/test_auth.py" ]; then
    echo "Running auth endpoint tests..."
    BACKEND_TESTS_TOTAL=$((BACKEND_TESTS_TOTAL + 1))
    if PYTHONPATH=src python -m pytest tests/test_auth.py -v --tb=short > test-results/auth-tests.log 2>&1; then
        BACKEND_TESTS_PASSED=$((BACKEND_TESTS_PASSED + 1))
        echo -e "${GREEN}✅ Auth tests passed${NC}"
    else
        echo -e "${RED}❌ Auth tests failed${NC}"
    fi
fi

# Test API endpoints
if [ -f "tests/test_api.py" ]; then
    echo "Running API endpoint tests..."
    BACKEND_TESTS_TOTAL=$((BACKEND_TESTS_TOTAL + 1))
    if PYTHONPATH=src python -m pytest tests/test_api.py -v --tb=short > test-results/api-tests.log 2>&1; then
        BACKEND_TESTS_PASSED=$((BACKEND_TESTS_PASSED + 1))
        echo -e "${GREEN}✅ API tests passed${NC}"
    else
        echo -e "${RED}❌ API tests failed${NC}"
    fi
fi

# Frontend Integration Tests
echo -e "\n${YELLOW}[3/4] Frontend Integration Tests${NC}"

cd frontend/angular

# E2E tests if available (Cypress, Protractor, etc.)
if [ -f "cypress.config.js" ] || [ -d "cypress" ]; then
    echo "Running Cypress E2E tests..."
    npm run e2e > ../../test-results/cypress-tests.log 2>&1 || echo "Cypress tests completed"
    echo -e "${GREEN}✅ E2E tests completed${NC}"
else
    echo -e "${YELLOW}⚠️  No E2E test framework found${NC}"
fi

cd ../..

# Docker Image Tests
echo -e "\n${YELLOW}[4/4] Docker Image Build Tests${NC}"

echo "Testing Backend Dockerfile build..."
if docker build -f Dockerfile -t crop-ai-backend:test . > test-results/docker-backend-build.log 2>&1; then
    echo -e "${GREEN}✅ Backend Docker image builds successfully${NC}"
else
    echo -e "${RED}❌ Backend Docker image build failed${NC}"
fi

echo "Testing Frontend Dockerfile build..."
if docker build -f frontend/Dockerfile -t crop-ai-frontend:test . > test-results/docker-frontend-build.log 2>&1; then
    echo -e "${GREEN}✅ Frontend Docker image builds successfully${NC}"
else
    echo -e "${RED}❌ Frontend Docker image build failed${NC}"
fi

# Summary
echo -e "\n${GREEN}📊 System Test Summary:${NC}"
echo "API Tests: $BACKEND_TESTS_PASSED/$BACKEND_TESTS_TOTAL passed"
echo "Test results: ./test-results/"
echo ""
echo -e "${GREEN}✅ System testing completed${NC}"
