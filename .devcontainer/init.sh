#!/bin/bash
set -e

echo "🚀 Initializing Crop AI Development Environment..."

# Update package manager
echo "📦 Updating package manager..."
apt-get update

# Install system dependencies
echo "📦 Installing system dependencies..."
apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    unzip \
    zip \
    libssl-dev \
    libffi-dev \
    python3-dev \
    postgresql-client \
    sqlite3 \
    dos2unix

# Install Firebase CLI
echo "🔥 Installing Firebase CLI..."
npm install -g firebase-tools@latest

# Install Flutter SDK
echo "🐦 Installing Flutter SDK..."
if [ ! -d "/tmp/flutter" ]; then
    cd /tmp
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
    echo "export PATH=\"/tmp/flutter/bin:\$PATH\"" >> ~/.bashrc
else
    echo "✅ Flutter already installed"
fi

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
/tmp/flutter/bin/flutter --version
/tmp/flutter/bin/flutter doctor

# Setup Python virtual environment
echo "🐍 Setting up Python environment..."
cd /workspaces/crop-ai
if [ ! -d ".venv" ]; then
    python3.11 -m venv .venv
    source .venv/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install -r requirements.txt
    pip install -r requirements-dev.txt
    echo "✅ Python virtual environment created"
else
    source .venv/bin/activate
    echo "✅ Python virtual environment activated"
fi

# Install Node dependencies (for Angular & Firebase)
echo "📦 Installing Node dependencies..."
if [ -f "frontend/package.json" ]; then
    cd frontend
    npm install
    cd ..
fi

# Setup mobile dependencies
echo "📱 Setting up Flutter mobile project..."
cd /workspaces/crop-ai/mobile
/tmp/flutter/bin/flutter pub get
echo "✅ Flutter dependencies installed"
cd /workspaces/crop-ai

# Run Python tests
echo "🧪 Running Python tests..."
PYTHONPATH=src python -m pytest tests/ -q --tb=short || echo "⚠️  Some tests may have failed, check manually"

# Run Flutter tests
echo "🧪 Running Flutter tests..."
cd /workspaces/crop-ai/mobile
export PATH="/tmp/flutter/bin:$PATH"
/tmp/flutter/bin/flutter test --no-pub || echo "⚠️  Some Flutter tests may have failed"
cd /workspaces/crop-ai

# Run code analysis
echo "📊 Running code analysis..."
export PATH="/tmp/flutter/bin:$PATH"
cd /workspaces/crop-ai/mobile
/tmp/flutter/bin/flutter analyze --no-pub || echo "⚠️  Analysis issues found, see above"
cd /workspaces/crop-ai

# Show startup summary
echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Crop AI Development Environment Ready!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "📋 Quick Start Commands:"
echo "   Backend (FastAPI):   cd src && python -m uvicorn crop_ai.main:app --reload"
echo "   Django Gateway:      cd frontend && python manage.py runserver"
echo "   Angular Web:         cd frontend/angular && npm start"
echo "   Flutter Mobile:      cd mobile && flutter run"
echo "   Run Tests:           ./scripts/run-unit-tests.sh"
echo ""
echo "🔥 Firebase:"
echo "   firebase login"
echo "   firebase deploy"
echo ""
echo "📚 Documentation:"
echo "   - README.md - Project overview"
echo "   - AGENT_STATUS_BRIEFING.md - Current status & context"
echo "   - PRIORITY_TASKS_COMPLETION.md - Latest work summary"
echo ""
echo "🌐 Services:"
echo "   FastAPI (5000):      http://localhost:5000/docs"
echo "   Django (8000):       http://localhost:8000"
echo "   Angular (4200):      http://localhost:4200"
echo "   Prometheus (9090):   http://localhost:9090"
echo ""
echo "Happy Coding! 🚀"
echo "════════════════════════════════════════════════════════════"
