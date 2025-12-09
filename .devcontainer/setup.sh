#!/bin/bash
set -e

echo "🚀 Setting up Flutter web development environment..."

# Update package manager
sudo apt-get update -qq

# Install dependencies
echo "📦 Installing system dependencies..."
sudo apt-get install -y -qq \
  curl \
  git \
  wget \
  unzip \
  ca-certificates \
  clang \
  cmake \
  git \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  libffi-dev \
  libssl-dev \
  libsqlite3-dev

# Download and setup Flutter
echo "📱 Installing Flutter SDK..."
if [ ! -d "/opt/flutter" ]; then
  cd /opt
  sudo git clone https://github.com/flutter/flutter.git -b stable --depth 1
  sudo chown -R codespace:codespace flutter
else
  echo "Flutter already installed"
fi

# Setup Flutter
export PATH="/opt/flutter/bin:$PATH"

# Accept licenses
flutter config --no-analytics
flutter precache --web

echo "✅ Flutter web development environment ready!"
flutter --version
dart --version

# Build web support
echo "🔧 Enabling Flutter web..."
flutter config --enable-web

echo "✨ Setup complete! You can now run 'flutter run -d web-server --web-port=8080'"
