#!/bin/bash
set -e

echo "🚀 Initializing Crop AI Development Environment..."

# Source Flutter PATH
export PATH="/tmp/flutter/bin:$PATH"

# Verify Flutter is available
echo "🔍 Verifying Flutter installation..."
if [ ! -f "/tmp/flutter/bin/flutter" ]; then
    echo "❌ Flutter not found! Installing..."
    cd /tmp
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

flutter --version
flutter doctor -v | head -20 || true

# Setup Python virtual environment
echo "🐍 Setting up Python environment..."
cd /workspaces/crop-ai
if [ ! -d ".venv" ]; then
    python3.11 -m venv .venv
fi
source .venv/bin/activate
pip install --upgrade pip setuptools wheel 2>&1 | tail -5
pip install -r requirements.txt -r requirements-dev.txt 2>&1 | tail -10
echo "✅ Python virtual environment ready"

# Install Node dependencies (optional - only if frontend exists)
echo "📦 Installing Node dependencies..."
if [ -f "frontend/package.json" ]; then
    cd frontend
    npm install 2>&1 | tail -5 || echo "⚠️  Node deps install had issues"
    cd ..
fi

# Setup Flutter mobile project
echo "📱 Setting up Flutter mobile project..."
cd /workspaces/crop-ai/mobile
flutter pub get 2>&1 | tail -10
echo "✅ Flutter dependencies ready"
cd /workspaces/crop-ai

# Optional: Run quick tests (skip if not ready)
echo "🧪 Optional: Skipping tests on first init (run manually if needed)"
echo "   Backend tests:  cd src && python -m pytest tests/"
echo "   Flutter tests:  cd mobile && flutter test"
echo "   Flutter analyze: cd mobile && flutter analyze"

# Show startup summary
echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Crop AI Development Environment Ready!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Available Commands:"
echo "   Backend (FastAPI):   cd src && python -m uvicorn crop_ai.main:app --reload"
echo "   Django Gateway:      cd frontend && python manage.py runserver"
echo "   Flutter Mobile:      cd mobile && flutter run"
echo "   Flutter Web:         cd mobile && flutter run -d web"
echo ""
echo "🧪 Testing:"
echo "   Backend tests:       cd src && python -m pytest tests/ -v"
echo "   Flutter tests:       cd mobile && flutter test"
echo "   Code analysis:       cd mobile && flutter analyze"
echo ""
echo "📚 Documentation:"
echo "   Status & Context:    cat AGENT_STATUS_BRIEFING.md"
echo "   Development Guide:   cat /workspaces/crop-ai/.github/copilot-instructions.md"
echo ""
echo "🔧 Quick Info:"
echo "   Flutter Version:     $(flutter --version 2>&1 | head -1)"
echo "   Python Version:      $(python --version)"
echo "   Node Version:        $(node --version)"
echo ""
echo "Happy Coding! 🚀"
echo "════════════════════════════════════════════════════════════"
