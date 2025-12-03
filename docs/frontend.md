# crop-ai Frontend - Django + Angular

Complete web frontend for crop-ai prediction service built with Django (backend) and Angular (frontend).

## Architecture

```
frontend/
├── crop_ai_frontend/      # Django project settings
├── api/                   # Django API app (proxy to FastAPI backend)
├── angular/               # Angular SPA application
├── templates/             # Django HTML templates
├── static/               # Static files (CSS, images)
├── manage.py             # Django management script
└── requirements.txt      # Python dependencies
```

## Features

### Django Backend
- 🔗 API proxy to crop-ai FastAPI backend
- 📊 Prediction request handling
- 🔄 CORS support for Angular frontend
- 🛡️ Error handling and logging
- 🚀 Production-ready with Gunicorn

### Angular Frontend
- 📱 Responsive Bootstrap UI
- 🌾 Crop prediction interface
- 📊 Analytics dashboard with charts
- 📈 System health monitoring
- 🔄 Real-time data updates
- ♿ Accessible components

## Setup

### Prerequisites
- Python 3.10+
- Node.js 18+
- npm or yarn

### Backend Setup (Django)

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # or .venv\Scripts\activate on Windows

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser

# Run development server
python manage.py runserver 0.0.0.0:8000
```

### Frontend Setup (Angular)

```bash
cd angular/

# Install dependencies
npm install

# Development server (with proxy to Django)
npm start
# App runs at http://localhost:4200

# Build for production
npm run build
# Output: ../staticfiles/ng/
```

### Environment Variables

Create `.env` file in frontend root:

```env
# Django
DEBUG=True
DJANGO_SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=localhost,127.0.0.1,yourdomain.com
CORS_ALLOWED_ORIGINS=http://localhost:4200,http://localhost:8000

# Backend API
CROP_AI_API_URL=http://localhost:8000
CROP_AI_API_TIMEOUT=30

# Database (optional, defaults to SQLite)
DATABASE_URL=sqlite:///./db.sqlite3

# Logging
DJANGO_LOG_LEVEL=INFO
```

### Docker Setup

Build and run with Docker:

```bash
# Build image
docker build -t crop-ai-frontend:latest .

# Run container
docker run -p 8000:8000 \
  -e CROP_AI_API_URL=http://crop-ai-api:8000 \
  -e DEBUG=False \
  crop-ai-frontend:latest
```

## API Endpoints (Django Proxy)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/predict/` | POST | Make a crop prediction |
| `/api/predictions/` | GET | Get recent predictions |
| `/api/stats/` | GET | Get statistics |
| `/api/health/` | GET | Get health status |
| `/api/info/` | GET | Get service info |
| `/api/metrics/` | GET | Get system metrics |
| `/api/ready/` | GET | Get readiness status |

### Example Requests

**Make a Prediction:**
```bash
curl -X POST http://localhost:8000/api/predict/ \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://example.com/satellite-image.tif",
    "model_version": "latest"
  }'
```

**Get Recent Predictions:**
```bash
curl http://localhost:8000/api/predictions/?limit=20
```

**Get Health Status:**
```bash
curl http://localhost:8000/api/health/
```

## Frontend Pages

### 1. Prediction Page (`/predict`)
- Upload satellite image URL
- Select model version
- View prediction results with confidence
- Shows crop type, confidence score, timestamp

### 2. Dashboard (`/dashboard`)
- System health overview
- Crop distribution chart
- System resources monitoring (CPU, Memory)
- Recent predictions table
- Service uptime and inference count

### 3. Navigation
- Header with navigation links
- Footer with project info
- Responsive design for mobile devices

## Development

### Running in Development Mode

**Terminal 1 - Django Backend:**
```bash
cd frontend/
python manage.py runserver 0.0.0.0:8000
```

**Terminal 2 - Angular Frontend:**
```bash
cd frontend/angular/
npm start
```

Then open http://localhost:4200 in your browser.

### Project Structure

```
frontend/
├── crop_ai_frontend/
│   ├── settings.py          # Django configuration
│   ├── urls.py              # URL routing
│   ├── wsgi.py              # WSGI application
│   └── __init__.py
├── api/
│   ├── views.py             # API proxy views
│   ├── urls.py              # API routes
│   ├── apps.py              # App configuration
│   └── __init__.py
├── angular/
│   ├── src/
│   │   ├── app.component.ts     # Main app component
│   │   ├── main.ts              # Bootstrap
│   │   ├── routes.ts            # Route definitions
│   │   ├── index.html           # HTML template
│   │   ├── styles.css           # Global styles
│   │   ├── services/
│   │   │   └── crop-ai.service.ts  # API service
│   │   └── components/
│   │       ├── navbar/
│   │       ├── footer/
│   │       ├── predict.component.ts
│   │       └── dashboard.component.ts
│   ├── package.json
│   ├── angular.json
│   └── tsconfig.json
├── templates/
│   └── index.html           # Django template for SPA
├── static/                  # Static files
├── manage.py
├── requirements.txt
└── Dockerfile
```

## Production Deployment

### Using Gunicorn

```bash
# Install gunicorn (included in requirements.txt)
gunicorn crop_ai_frontend.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --timeout 300
```

### Using Docker with Azure Container Instances

```bash
# Build
docker build -t crop-ai-frontend:latest .

# Tag for registry
docker tag crop-ai-frontend:latest myregistry.azurecr.io/crop-ai-frontend:latest

# Push
docker push myregistry.azurecr.io/crop-ai-frontend:latest

# Deploy to ACI
az container create \
  --resource-group mygroup \
  --name crop-ai-frontend \
  --image myregistry.azurecr.io/crop-ai-frontend:latest \
  --registry-login-server myregistry.azurecr.io \
  --registry-username myusername \
  --registry-password mypassword \
  --dns-name-label crop-ai-frontend \
  --ports 8000 \
  --environment-variables \
    CROP_AI_API_URL=http://crop-ai-api:8000 \
    DEBUG=False
```

### Environment Variables for Production

```env
DEBUG=False
DJANGO_SECRET_KEY=<strong-random-key>
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
CORS_ALLOWED_ORIGINS=https://yourdomain.com
CROP_AI_API_URL=https://api.yourdomain.com
CROP_AI_API_TIMEOUT=60
DATABASE_URL=postgresql://user:password@host:5432/dbname
```

## Performance Optimization

### Frontend (Angular)

```bash
# Production build (minified, tree-shake, AOT)
npm run build

# This creates optimized bundles in staticfiles/ng/
```

### Backend (Django)

1. **Enable caching:**
   ```python
   CACHES = {
       'default': {
           'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
       }
   }
   ```

2. **Use WhiteNoise for static files:**
   ```python
   MIDDLEWARE = [
       'whitenoise.middleware.WhiteNoiseMiddleware',
       ...
   ]
   STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
   ```

3. **Database connection pooling (for PostgreSQL):**
   ```python
   DATABASES = {
       'default': {
           'ENGINE': 'django.db.backends.postgresql',
           'CONN_MAX_AGE': 600,
           'OPTIONS': {
               'connect_timeout': 10,
           }
       }
   }
   ```

## Troubleshooting

### CORS Errors

**Error:** `Access to XMLHttpRequest ... has been blocked by CORS policy`

**Solution:** Ensure `CORS_ALLOWED_ORIGINS` includes your frontend URL in Django settings.

### Static Files Not Loading

**Error:** `404 Not Found` for static files in production

**Solution:** Run `python manage.py collectstatic --noinput` and ensure WhiteNoise is in middleware.

### API Connection Timeout

**Error:** `Backend request timeout`

**Solution:** 
1. Check `CROP_AI_API_URL` is correct
2. Verify FastAPI backend is running
3. Increase `CROP_AI_API_TIMEOUT` if needed

### Angular Build Errors

**Error:** `Cannot find module '@angular/core'`

**Solution:** Run `npm install` in `angular/` directory.

## Contributing

1. Follow PEP 8 for Python code
2. Use Angular style guide for TypeScript
3. Test locally before committing
4. Update documentation for major changes

## License

Same as crop-ai project

## Support

For issues, check:
1. Backend logs: `python manage.py runserver` output
2. Angular console: Browser DevTools
3. Application Insights (if configured)
