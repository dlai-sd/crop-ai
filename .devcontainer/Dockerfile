FROM mcr.microsoft.com/devcontainers/python:3.11-bullseye

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install system dependencies including web server for Flutter web preview
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    wget \
    unzip \
    zip \
    libssl-dev \
    libffi-dev \
    postgresql-client \
    sqlite3 \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Install Firebase CLI globally
RUN npm install -g firebase-tools@latest

# Install Flutter SDK to /tmp/flutter
RUN cd /tmp && \
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 && \
    /tmp/flutter/bin/flutter config --no-analytics && \
    /tmp/flutter/bin/flutter config --enable-web && \
    /tmp/flutter/bin/flutter precache

# Set environment variables
ENV PATH="/tmp/flutter/bin:${PATH}" \
    FLUTTER_HOME="/tmp/flutter" \
    PYTHONPATH="/workspaces/crop-ai/src" \
    NODE_ENV="development" \
    FLUTTER_SKIP_DOWNLOAD_ENCODING_ASSETS="true"

# Verify installations
RUN python --version && \
    node --version && \
    npm --version && \
    firebase --version && \
    /tmp/flutter/bin/flutter --version && \
    /tmp/flutter/bin/flutter doctor -v | head -20

WORKDIR /workspaces/crop-ai
