#!/bin/bash
# Quick Flutter Web Preview Script
# Usage: ./scripts/preview-web.sh

set -e

echo "🌐 Building Flutter Web for UI Preview..."
echo ""

# Ensure Flutter is in PATH
export PATH="/tmp/flutter/bin:$PATH"

# Check if flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found! Please ensure devcontainer initialized correctly."
    exit 1
fi

# Navigate to mobile directory
cd /workspaces/crop-ai/mobile

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean 2>&1 | tail -3

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get 2>&1 | tail -3

# Build web
echo "🔨 Building Flutter web (release mode)..."
flutter build web --release 2>&1 | tail -10

echo ""
echo "✅ Web build complete!"
echo ""
echo "📍 Preview URL: http://localhost:8080"
echo ""
echo "🚀 Starting local web server on port 8080..."
echo "   (Press Ctrl+C to stop)"
echo ""

# Navigate to build directory and start simple HTTP server
cd build/web
python3 -m http.server 8080 --bind 127.0.0.1

