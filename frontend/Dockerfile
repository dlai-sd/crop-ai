# Build Angular
FROM node:18-alpine as ng-builder

WORKDIR /app/angular

# Copy Angular project
COPY frontend/angular/package*.json ./
RUN npm install --legacy-peer-deps

COPY frontend/angular/ ./
RUN npm run build

# Build Django with Angular static files
FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY frontend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy Django project
COPY frontend/ .

# Copy Angular build output
COPY --from=ng-builder /app/angular/staticfiles/ng ./staticfiles/ng

# Collect static files
RUN python manage.py collectstatic --noinput || true

# Create non-root user
RUN useradd -m -u 1000 appuser
USER appuser

EXPOSE 8000

# Run with gunicorn
CMD ["gunicorn", "crop_ai_frontend.wsgi:application", \
     "--bind", "0.0.0.0:8000", \
     "--workers", "4", \
     "--timeout", "120"]
