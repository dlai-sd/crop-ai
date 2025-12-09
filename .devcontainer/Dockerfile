FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/flutter/bin:${PATH}"

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    xz-utils \
    build-essential \
    libglu1-mesa \
    libstdc++-12-dev \
    libmpfr-dev \
    libmpc-dev \
    libssl-dev \
    libffi-dev \
    libgmp-dev \
    libx11-dev \
    libxext-dev \
    pkg-config \
    ca-certificates \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js (required for Flutter web)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
RUN git clone https://github.com/flutter/flutter.git /root/flutter && \
    cd /root/flutter && \
    git checkout stable

# Enable Flutter web
RUN flutter config --enable-web

# Run flutter doctor to verify installation
RUN flutter doctor -v

# Set working directory
WORKDIR /workspaces/crop-ai

# Install any additional tools
RUN flutter pub global activate devtools

CMD ["/bin/bash"]
