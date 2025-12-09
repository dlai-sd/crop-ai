#!/bin/bash

# Epic 1 Testing Summary Script
# Run this to execute all Epic 1 tests

echo "============================================"
echo "Epic 1: Crop Monitoring - Test Suite"
echo "============================================"
echo ""

cd /workspaces/crop-ai/mobile

echo "📋 Test Files Found:"
find test -name "*_test.dart" -type f | sort

echo ""
echo "Running tests..."
echo ""

# Run all tests with coverage
flutter test --coverage 2>&1 | tee test_results.txt

echo ""
echo "============================================"
echo "Test Results Summary"
echo "============================================"
echo ""

# Count test results
PASSED=$(grep -c "✓" test_results.txt 2>/dev/null || echo "0")
FAILED=$(grep -c "✗" test_results.txt 2>/dev/null || echo "0")

echo "✅ Tests Passed: $PASSED"
echo "❌ Tests Failed: $FAILED"

echo ""
echo "Test Files Executed:"
echo "  1. Farm Model Tests: test/features/farm/models/farm_test.dart"
echo "  2. Farm Form Tests: test/features/farm/models/farm_form_test.dart"
echo "  3. Farm Repository Tests: test/features/farm/data/farm_repository_test.dart"
echo "  4. Weather Model Tests: test/features/weather/models/weather_test.dart"
echo "  5. Weather Repository Tests: test/features/weather/data/weather_repository_test.dart"
echo "  6. Sync Service Tests: test/features/offline_sync/data/sync_service_test.dart"
echo "  7. Integration Tests: test/integration/epic_1_integration_test.dart"

echo ""
echo "Coverage Report:"
if [ -f "coverage/lcov.info" ]; then
  echo "✅ Coverage data generated: coverage/lcov.info"
else
  echo "⚠️ Coverage data not available"
fi

echo ""
echo "============================================"
echo "Epic 1 Testing Complete"
echo "============================================"
