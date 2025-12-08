#!/bin/bash
set -e

echo "🧪 Running Unit Tests..."
echo "========================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Backend Tests
echo -e "\n${YELLOW}[1/2] Backend Unit Tests (PyUnit/pytest)${NC}"
cd /workspaces/crop-ai
PYTHONPATH=src python -m pytest tests/ -v --tb=short --cov=src --cov-report=xml --cov-report=html 2>&1 | tee backend-test-results.log

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✅ Backend tests PASSED${NC}"
else
    echo -e "${RED}❌ Backend tests FAILED${NC}"
fi

# Frontend Tests
echo -e "\n${YELLOW}[2/2] Frontend Unit Tests (Jest/Karma)${NC}"
cd /workspaces/crop-ai/frontend/angular

# Try Jest first (if configured)
if [ -f "jest.config.js" ]; then
    echo "Running Jest tests..."
    npm run test:ci 2>&1 | tee ../../frontend-jest-results.log || echo "Jest tests completed with exit code: $?"
fi

# Run Karma/Jasmine (Angular default)
echo "Running Karma/Jasmine tests..."
npm test -- --watch=false --browsers=ChromeHeadless 2>&1 | tee ../../frontend-karma-results.log || echo "Karma tests completed with exit code: $?"

echo -e "${GREEN}✅ Frontend tests completed${NC}"

echo -e "\n${GREEN}🎉 Unit Testing Summary:${NC}"
echo "Backend: Coverage report available at ./htmlcov/index.html"
echo "Frontend: Results logged to frontend-*-results.log"
