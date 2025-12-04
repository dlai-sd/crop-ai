# Azure Cloud Deployment Guide - Bare Minimum Cost
## DLAI Crop AI - SPA + Backend Architecture

**Last Updated:** December 4, 2025  
**Focus:** Cost-effective, production-ready deployment

---

## 🎯 Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud Deployment                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐              ┌──────────────────┐   │
│  │  Azure Static    │              │  Azure Container │   │
│  │  Web Apps (SPA)  │              │  Instances (API) │   │
│  │                  │              │                  │   │
│  │ • Angular Build  │              │ • Python Uvicorn│   │
│  │ • Free Tier      │              │ • Docker        │   │
│  │ • CDN Included   │              │ • $30-50/month  │   │
│  └──────────────────┘              └──────────────────┘   │
│         ▲                                  ▲               │
│         │ HTTPS                           │ HTTPS          │
│         └────────────────────────────────┘                 │
│                   Frontend → Backend                       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │    Azure Blob Storage (Optional Assets)              │  │
│  │    • Images, satellite data, backups                │  │
│  │    • Minimal cost (pay per GB)                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 💰 Cost Breakdown (Monthly Estimate)

### **Option A: Bare Minimum (Recommended for MVP)**

| Service | Tier | Cost | Notes |
|---------|------|------|-------|
| Static Web Apps (SPA) | Free | $0 | 100 GB/month bandwidth, auto HTTPS |
| Container Instances (Backend) | Standard | $35-50 | 1 vCPU, 1GB RAM, reserved instance |
| Blob Storage (Assets) | Cool | $5-10 | Only if using satellite imagery storage |
| Application Insights | Free | $0 | Monitoring & logging |
| **Total Monthly** | | **$40-60** | **Bare minimum production** |

### **Option B: Auto-Scaling (Better for Growth)**

| Service | Tier | Cost | Notes |
|---------|------|------|-------|
| Static Web Apps (SPA) | Free | $0 | Same benefits |
| App Service (Backend) | B1 | $12 | Includes auto-scaling, better perf |
| Container Registry | Basic | $5 | For Docker image storage |
| Blob Storage | Cool | $5-10 | Satellite imagery storage |
| **Total Monthly** | | **$22-30** | **With better scaling** |

---

## 🚀 Deployment Steps (Step-by-Step)

### **Phase 1: Prepare Angular SPA for Production**

```bash
# 1. Build optimized Angular bundle
cd /workspaces/crop-ai/frontend/angular
ng build --configuration production --output-hashing all

# Output: dist/crop-ai-ng/ (production-ready files)
```

**Build Optimizations:**
- Tree shaking: Removes unused code
- Minification: Reduces bundle size
- AOT compilation: Faster loading
- Output hashing: Cache busting

**Expected build size:** ~1.5-2 MB (highly optimized)

---

### **Phase 2: Containerize Python Backend**

**Dockerfile is ready!** Located at `/workspaces/crop-ai/Dockerfile`

**Current setup:**
- Python 3.10 slim base image (~150MB)
- Uvicorn ASGI server
- Exposed on port 8000

**Optimize for Azure Container Instances:**

```dockerfile
# Multi-stage build to reduce image size
FROM python:3.10-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.10-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY src/ src/
ENV PATH=/root/.local/bin:$PATH
PYTHONPATH=/app/src
EXPOSE 8000
CMD ["uvicorn", "crop_ai.api:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Image size reduction:** ~200MB → ~350MB final (acceptable for ACI)

---

### **Phase 3: Azure Static Web Apps (Free SPA Hosting)**

#### **3.1 Create Static Web App in Azure Portal**

```
Steps:
1. Go to Azure Portal → Search "Static Web Apps"
2. Click "Create"
3. Fill in:
   - Resource Group: create-crop-ai-rg
   - Name: crop-ai-landing
   - Plan Type: Free
   - Repository: dlai-sd/crop-ai
   - Build location: frontend/angular
   - App location: dist/crop-ai-ng
   - API location: (leave empty for now)
```

#### **3.2 Auto-Deploy on Git Push**

Azure will create GitHub Actions workflow automatically:

```yaml
# .github/workflows/azure-static-web-apps-*.yml
name: Azure Static Web Apps CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build_and_deploy_job:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Angular
        run: |
          cd frontend/angular
          npm install
          ng build --configuration production
      - name: Deploy to SWA
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: upload
          app_location: "frontend/angular/dist/crop-ai-ng"
          app_build_command: "echo 'Already built'"
```

**Benefits:**
- Automatic deployment on every git push to `main`
- Global CDN included (edge locations worldwide)
- Free HTTPS certificate
- Automatic staging environments for PR previews

---

### **Phase 4: Azure Container Instances (Backend API)**

#### **4.1 Push Docker Image to Azure Container Registry**

```bash
# 1. Create Azure Container Registry
az acr create --resource-group create-crop-ai-rg \
  --name cropairegistry --sku Basic

# 2. Build and push Docker image
az acr build --registry cropairegistry \
  --image crop-ai-api:latest .

# 3. Verify image
az acr repository list --name cropairegistry --output table
```

#### **4.2 Deploy Container Instance**

```bash
# Create Azure Container Instance
az container create \
  --resource-group create-crop-ai-rg \
  --name crop-ai-api \
  --image cropairegistry.azurecr.io/crop-ai-api:latest \
  --cpu 1 --memory 1 \
  --registry-login-server cropairegistry.azurecr.io \
  --registry-username <username> \
  --registry-password <password> \
  --ports 8000 \
  --environment-variables \
    LOG_LEVEL=INFO \
    API_PORT=8000 \
  --dns-name-label crop-ai-api \
  --ip-address Public

# Get access URL
az container show --resource-group create-crop-ai-rg \
  --name crop-ai-api --query ipAddress.fqdn
# Output: crop-ai-api.centralindia.azurecontainers.io
```

**Cost Optimization:**
- Use reserved instances for predictable workloads
- Scale down during off-hours (manual or scheduled)
- Monitor CPU/memory, right-size if underutilized

---

### **Phase 5: Connect Frontend to Backend**

#### **5.1 Update API Base URL**

In Angular component (`landing.component.ts`):

```typescript
// Before (localhost)
private apiBaseUrl = 'http://localhost:8000';

// After (Azure)
private apiBaseUrl = 'https://crop-ai-api.centralindia.azurecontainers.io';
```

Or use environment variables:

```typescript
import { environment } from '../environments/environment';

constructor() {
  this.apiBaseUrl = environment.apiBaseUrl;
}
```

`src/environments/environment.prod.ts`:
```typescript
export const environment = {
  production: true,
  apiBaseUrl: 'https://crop-ai-api.centralindia.azurecontainers.io'
};
```

#### **5.2 Configure CORS (Cross-Origin Resource Sharing)**

In Python backend (`src/crop_ai/api.py`):

```python
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Allow your Static Web App domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://crop-ai-landing.azurestaticapps.net",  # Your SWA domain
        "http://localhost:3000",  # Local dev
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 🔒 Security Best Practices

### **1. Use Azure Key Vault for Secrets**

```bash
# Create Key Vault
az keyvault create --name crop-ai-vault \
  --resource-group create-crop-ai-rg

# Store secrets
az keyvault secret set --vault-name crop-ai-vault \
  --name db-connection-string --value <your-secret>

# Access in Python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://crop-ai-vault.vault.azure.net/", credential=credential)
secret = client.get_secret("db-connection-string")
```

### **2. Enable HTTPS Everywhere**

✅ Static Web Apps: Automatic HTTPS  
✅ Container Instances: Use DNS name with HTTPS only  
✅ Update `environment.prod.ts` to use `https://` URLs

### **3. Environment-Specific Configuration**

Create `staticwebapp.config.json` for routing:

```json
{
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": [],
      "methods": ["GET", "POST", "PUT", "DELETE"],
      "rewrite": "https://crop-ai-api.centralindia.azurecontainers.io/api/*"
    },
    {
      "route": "/*",
      "serve": "/index.html",
      "statusCode": 200
    }
  ],
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/images/*", "/css/*"]
  }
}
```

---

## 📊 Monitoring & Logging

### **1. Application Insights (Free Tier)**

```bash
# Create Application Insights
az monitor app-insights component create \
  --app crop-ai-insights \
  --location centralindia \
  --resource-group create-crop-ai-rg \
  --application-type web

# Get instrumentation key
az monitor app-insights component show \
  --app crop-ai-insights \
  --resource-group create-crop-ai-rg \
  --query instrumentationKey
```

### **2. Add to Python Backend**

```python
from opencensus.ext.flask.flask_middleware import FlaskMiddleware
from opencensus.ext.azure.log_exporter import AzureLogHandler
import logging

# Setup Azure logging
logger = logging.getLogger(__name__)
logger.addHandler(AzureLogHandler(
    instrumentation_key="<your-instrumentation-key>"
))

# Log API calls
@app.get("/api/health")
async def health_check():
    logger.info("Health check called")
    return {"status": "healthy"}
```

### **3. View Logs**

```bash
# Stream container logs in real-time
az container logs --resource-group create-crop-ai-rg \
  --name crop-ai-api --follow
```

---

## 🔄 CI/CD Pipeline

### **Auto-Deploy with GitHub Actions**

Already set up by Azure Static Web Apps! Just:

1. Commit to `main` branch
2. GitHub Actions triggers automatically
3. Angular app builds
4. Deploys to Azure Static Web Apps
5. Live in ~2 minutes

### **Manual Docker Image Updates**

```bash
# When you update backend code:
az acr build --registry cropairegistry \
  --image crop-ai-api:latest .

# Restart container instance
az container restart --resource-group create-crop-ai-rg \
  --name crop-ai-api
```

---

## 💵 Cost Optimization Tips

1. **Use Azure Free Account Benefits**
   - $200 free credit for 30 days
   - 12 months of free services (Static Web Apps, Container Registry)
   - Always-free services (Application Insights, Key Vault limited)

2. **Right-Size Resources**
   - Start with 1 vCPU, 1GB RAM for ACI
   - Monitor actual usage
   - Scale down if underutilized

3. **Use Spot Instances (if available)**
   - 70% discount on compute
   - Good for non-critical workloads

4. **Optimize Storage**
   - Use Cool tier for infrequent access
   - Archive tier for backups (99% cheaper!)

5. **Monitor Costs in Real-Time**
   - Azure Cost Management tool
   - Set up budget alerts

---

## 🎯 Deployment Timeline

| Step | Time | Complexity |
|------|------|-----------|
| Build Angular production | 5 min | Easy |
| Set up Static Web Apps | 10 min | Easy |
| Create Container Registry | 5 min | Easy |
| Push Docker image | 5 min | Medium |
| Create Container Instance | 5 min | Medium |
| Configure CORS & env vars | 10 min | Medium |
| Test & verify | 15 min | Medium |
| **Total** | **~55 min** | **Moderate** |

---

## ✅ Pre-Deployment Checklist

- [ ] Angular production build tested locally
- [ ] Docker image builds without errors
- [ ] Python backend API tested with CORS enabled
- [ ] Environment variables configured
- [ ] API endpoint URLs updated for production
- [ ] HTTPS enabled on both frontend and backend
- [ ] Secrets stored in Azure Key Vault
- [ ] Monitoring/logging configured
- [ ] Cost alerts set up
- [ ] Backup strategy defined

---

## 🚀 Quick Start Commands (All-in-One)

```bash
#!/bin/bash
# Deploy crop-ai to Azure

# 1. Build Angular
cd /workspaces/crop-ai/frontend/angular
ng build --configuration production

# 2. Create Azure resources
az group create --name create-crop-ai-rg --location centralindia

# 3. Create & deploy Static Web App
az staticwebapp create \
  --name crop-ai-landing \
  --resource-group create-crop-ai-rg \
  --source https://github.com/dlai-sd/crop-ai \
  --location centralindia \
  --branch main

# 4. Create Container Registry
az acr create --resource-group create-crop-ai-rg \
  --name cropairegistry --sku Basic

# 5. Build & push Docker image
az acr build --registry cropairegistry \
  --image crop-ai-api:latest .

# 6. Deploy Container Instance
az container create \
  --resource-group create-crop-ai-rg \
  --name crop-ai-api \
  --image cropairegistry.azurecr.io/crop-ai-api:latest \
  --cpu 1 --memory 1 \
  --ports 8000 \
  --dns-name-label crop-ai-api \
  --registry-login-server cropairegistry.azurecr.io \
  --registry-username $(az acr credential show --resource-group create-crop-ai-rg --name cropairegistry --query username -o tsv) \
  --registry-password $(az acr credential show --resource-group create-crop-ai-rg --name cropairegistry --query passwords[0].value -o tsv) \
  --ip-address Public

echo "✅ Deployment complete!"
echo "Frontend: https://crop-ai-landing.azurestaticapps.net"
echo "Backend: https://crop-ai-api.centralindia.azurecontainers.io"
```

---

## 📞 Support & Troubleshooting

### **Static Web App not showing content**
```bash
# Check build output
az staticwebapp show --name crop-ai-landing \
  --resource-group create-crop-ai-rg --query customDomains
```

### **Container Instance not accessible**
```bash
# Check container logs
az container logs --resource-group create-crop-ai-rg \
  --name crop-ai-api

# Verify public IP
az container show --resource-group create-crop-ai-rg \
  --name crop-ai-api --query ipAddress.fqdn
```

### **CORS errors in browser console**
- Check `staticwebapp.config.json` routing rules
- Verify backend CORS middleware configuration
- Test API endpoint directly: `curl -i https://crop-ai-api.../health`

---

## 📚 Useful Documentation Links

- [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Azure Container Instances](https://learn.microsoft.com/en-us/azure/container-instances/)
- [Azure Container Registry](https://learn.microsoft.com/en-us/azure/container-registry/)
- [Azure Cost Management](https://learn.microsoft.com/en-us/azure/cost-management-billing/)

---

**Total Estimated Monthly Cost: $40-60 USD**  
**Perfect for MVP/Demo Stage**  

Ready to deploy? Let me know! 🚀
