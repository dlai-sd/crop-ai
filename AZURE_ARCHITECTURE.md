# Azure Architecture & Infrastructure Design

## 🏗️ Complete Architecture

### **Current Local Setup (Development)**
```
┌──────────────────────────────────────────────────────────┐
│            Your Codespace Development Environment         │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  ┌──────────────────┐         ┌──────────────────────┐   │
│  │  Angular SPA     │         │  Python FastAPI      │   │
│  │  Port: 4200      │         │  Port: 8000          │   │
│  │  npm start       │◄───────►│  uvicorn api:app     │   │
│  └──────────────────┘         └──────────────────────┘   │
│           ▲                              ▲                │
│           │ http://localhost:4200        │                │
│           │ http://localhost:8000        │                │
│           │                              │                │
│  ┌────────┴──────────────────────────────┴─────────────┐ │
│  │   Leaflet.js (Satellite Maps)                       │ │
│  │   - Esri World Imagery tiles                        │ │
│  │   - Village labels overlay                          │ │
│  │   - Geolocation markers                             │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

### **Azure Production Setup (Recommended)**
```
┌────────────────────────────────────────────────────────────────┐
│                     Azure Cloud Platform                        │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              Azure Static Web Apps (FREE)               │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  Angular SPA (Production Build)                  │  │  │
│  │  │  ✅ 100 GB bandwidth/month (FREE)                │  │  │
│  │  │  ✅ Global CDN included                          │  │  │
│  │  │  ✅ Auto HTTPS + TLS/SSL                         │  │  │
│  │  │  ✅ GitHub Actions auto-deploy                  │  │  │
│  │  │                                                  │  │  │
│  │  │  Static Files:                                   │  │  │
│  │  │  - index.html, main.js, styles.css              │  │  │
│  │  │  - assets/, leaflet/                            │  │  │
│  │  │                                                  │  │  │
│  │  │  URL: https://crop-ai-landing.azurestaticapps.net  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  │  ┌──────────────────────────────────────────────────┐  │  │
│  │  │  API Proxy (Optional Advanced)                   │  │  │
│  │  │  Routes /api/* to backend                        │  │  │
│  │  └──────────────────────────────────────────────────┘  │  │
│  │                                                          │  │
│  └─────────────────────────────────────────────────────────┘  │
│                            │                                   │
│                            │ HTTPS                             │
│                            │                                   │
│  ┌─────────────────────────▼─────────────────────────────┐  │
│  │    Azure Container Instances ($35-50/month)          │  │
│  ├─────────────────────────────────────────────────────┤  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │  Python FastAPI Container                   │   │  │
│  │  │  ├─ 1 vCPU                                  │   │  │
│  │  │  ├─ 1 GB RAM                                │   │  │
│  │  │  ├─ Uvicorn ASGI Server                     │   │  │
│  │  │  ├─ Port: 8000                              │   │  │
│  │  │  └─ Public IP with DNS                      │   │  │
│  │  │                                              │   │  │
│  │  │  Application Features:                       │   │  │
│  │  │  - Satellite image processing               │   │  │
│  │  │  - ML inference endpoints                   │   │  │
│  │  │  - Crop health analysis                     │   │  │
│  │  │  - Weather integration                      │   │  │
│  │  │                                              │   │  │
│  │  │  URL: https://crop-ai-api.centralindia.azurecontainers.io  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                       │  │
│  │  Monitoring:                                         │  │
│  │  └─ Container Logs (Real-time streaming)            │  │
│  │     az container logs -g crop-ai-rg -n crop-ai-api   │  │
│  │                                                       │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │   Azure Container Registry (Basic Tier - $5/month)    │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  • Stores Docker images (crop-ai-api:latest)           │  │
│  │  • Private registry for your images                     │  │
│  │  • Webhook triggers on image push                       │  │
│  │                                                          │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │   Application Insights (Monitoring - FREE)              │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  • Real-time application performance monitoring         │  │
│  │  • Error tracking & debugging                           │  │
│  │  • User analytics & behavior tracking                   │  │
│  │  • Custom metrics from your application                 │  │
│  │  • Alerts & notifications                               │  │
│  │                                                          │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │   Azure Blob Storage (Optional - Pay per GB)            │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  Use Cases:                                             │  │
│  │  • Store satellite imagery cache                        │  │
│  │  • Backup prediction databases                          │  │
│  │  • Store user uploads                                   │  │
│  │  • Archive historical analysis                          │  │
│  │                                                          │  │
│  │  Cost: ~$0.02-0.05 per GB (Cool tier)                 │  │
│  │                                                          │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │   Azure Key Vault (Secrets Management - FREE)           │  │
│  ├─────────────────────────────────────────────────────────┤  │
│  │                                                          │  │
│  │  Stores:                                                │  │
│  │  • Database connection strings                          │  │
│  │  • API keys                                             │  │
│  │  • OAuth tokens                                         │  │
│  │  • Certificates                                         │  │
│  │                                                          │  │
│  │  Access from Python backend:                            │  │
│  │  from azure.keyvault.secrets import SecretClient        │  │
│  │                                                          │  │
│  └─────────────────────────────────────────────────────────┘  │
│                                                                  │
└────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagram

### **User Request Flow (Frontend to Backend)**

```
User Browser
    │
    ├─ Request: GET https://crop-ai-landing.azurestaticapps.net
    │
    └─► Azure CDN (Edge Location)
         │
         └─► Azure Static Web Apps
              │
              ├─ Serve: index.html (Angular App)
              ├─ Serve: main.js, styles.css
              ├─ Load: Leaflet.js, satellite tiles
              │
              └─► Angular App Loaded
                  │
                  ├─ User clicks "I Am" → "Farmer"
                  ├─ Smooth scroll to Carousel
                  │
                  └─ (Optional) User clicks "Get Crop Analysis"
                     │
                     └─► POST /api/analyze
                         │
                         └─► HTTPS Request
                             │
                             └─► Azure Container Instances
                                  │
                                  ├─ Python FastAPI Router
                                  ├─ Validate Input
                                  ├─ Process Satellite Data
                                  ├─ Run ML Model
                                  ├─ Generate Analysis
                                  │
                                  └─► JSON Response
                                      │
                                      └─► Angular Frontend
                                          │
                                          └─► Display Results
```

---

## 📊 Service Tier Comparison

### **Scaling Options**

#### **Tier 1: Bare Minimum (MVP) - $50/month**
```
├─ Static Web Apps (FREE)
├─ Container Instances (1 vCPU, 1GB RAM - $35-50)
└─ Container Registry (Basic - $5)
```

#### **Tier 2: Growing User Base - $100-150/month**
```
├─ Static Web Apps (FREE + Custom Domain)
├─ App Service (B1, auto-scaling - $12-20)
├─ Azure SQL Database (Basic - $35-50)
├─ Container Registry (Standard - $5)
└─ Application Insights (with more data retention)
```

#### **Tier 3: Production Scale - $500+/month**
```
├─ Static Web Apps (Premium - $20)
├─ App Service Plan (Standard - $100+)
├─ Azure Database for PostgreSQL (Flexible Server)
├─ Redis Cache for performance
├─ Load Balancer for multi-region
├─ CDN Premium
└─ Advanced monitoring & security
```

---

## 🔐 Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Azure Security & Compliance                │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Layer 1: Network Security                              │
│  ├─ HTTPS/TLS everywhere (encrypted in transit)         │
│  ├─ Static Web Apps: Built-in DDoS protection           │
│  ├─ Container Instances: Private IP option              │
│  └─ Network Security Groups (NSG)                       │
│                                                          │
│  Layer 2: Application Security                          │
│  ├─ CORS properly configured                            │
│  ├─ Input validation & sanitization                     │
│  ├─ SQL injection prevention (ORM)                      │
│  ├─ XSS protection (Angular built-in)                   │
│  └─ CSRF tokens                                         │
│                                                          │
│  Layer 3: Secrets Management                            │
│  ├─ Azure Key Vault (encrypted at rest)                 │
│  ├─ No hardcoded secrets in code                        │
│  ├─ Environment variable injection                      │
│  └─ Access control & audit logs                         │
│                                                          │
│  Layer 4: Data Protection                               │
│  ├─ Encryption at rest (Blob Storage)                   │
│  ├─ Encryption in transit (TLS 1.2+)                    │
│  ├─ Backup & disaster recovery                          │
│  └─ Compliance: GDPR, SOC 2                             │
│                                                          │
│  Layer 5: Monitoring & Logging                          │
│  ├─ Application Insights (telemetry)                    │
│  ├─ Azure Audit Logs (activity)                         │
│  ├─ Alert rules & notifications                         │
│  └─ Security recommendations                            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## 💾 Database Integration (Optional)

### **If you need persistent storage:**

#### **Option 1: Azure SQL Database** (Recommended for relational data)
```
Cost: ~$35-50/month (Basic tier)

Features:
- Fully managed SQL Server
- Automatic backups (35 days)
- High availability
- Easy scaling

Connection from Python:
import pyodbc
conn = pyodbc.connect(f'mssql+pyodbc://user:password@server.database.windows.net/crop_ai?driver=ODBC+Driver+17+for+SQL+Server')
```

#### **Option 2: Azure Cosmos DB** (For document/NoSQL data)
```
Cost: ~$25-50/month (serverless tier)

Features:
- Global distribution
- Auto-scaling
- JSON document storage
- Real-time analytics

Connection from Python:
from azure.cosmos import CosmosClient
client = CosmosClient(url, key)
```

#### **Option 3: Azure PostgreSQL** (For open-source)
```
Cost: ~$30-40/month (Flexible Server)

Features:
- Managed PostgreSQL
- Native JSON support
- Advanced analytics
- PostGIS for geospatial data (perfect for satellite)

Connection from Python:
import psycopg2
conn = psycopg2.connect("dbname=crop_ai user=admin password=*** host=server.postgres.database.azure.com")
```

---

## 🚀 Deployment Workflow Diagram

```
Developer Commit
    │
    ├─ Push to main branch (GitHub)
    │
    └─► GitHub Actions Workflow Triggered
         │
         ├─ Build Angular
         │  ├─ npm install
         │  ├─ ng build --prod
         │  └─ Create dist/ folder
         │
         ├─ Deploy Frontend
         │  ├─ Azure Static Web Apps
         │  ├─ Upload to CDN
         │  ├─ Run smoke tests
         │  └─ Go live! (~2 minutes)
         │
         ├─ [Optional] Build Backend Docker
         │  ├─ docker build .
         │  ├─ docker push to ACR
         │  ├─ Update Container Instance
         │  └─ Health checks pass (~5 minutes)
         │
         └─► ✅ Live in Production!
             │
             └─ Monitor in Application Insights
                ├─ Real-time metrics
                ├─ Error logs
                └─ User analytics
```

---

## 💡 Cost Optimization Strategies

```
Monthly Cost Breakdown:

Static Web Apps:      $0    (FREE Tier - 100GB/month bandwidth)
  └─ Perfect for: SPA hosting, CDN, auto HTTPS

Container Instances:  $35   (1 vCPU, 1GB RAM, 730 hours/month)
  ├─ Utilization: 24/7
  ├─ Cost/hour: $0.0476
  └─ Optimization: Schedule shutdown if not 24/7

Container Registry:   $5    (Basic tier)
  └─ Includes: 10 GB storage

Application Insights: $0    (FREE up to 5GB/month)
  ├─ Retention: 90 days
  └─ Perfect for: Monitoring & debugging

Blob Storage:         $5-10 (If using - Cool tier)
  └─ Cost: ~$0.02/GB

TOTAL:                ~$50-60/month

SAVINGS OPPORTUNITIES:
┌─ Turn off Container Instance during development (save ~$30/month)
├─ Use Azure Spot Instances (70% discount, but can be preempted)
├─ Reserved Instances (prepay for 1-3 years, ~30% discount)
├─ Monitor costs weekly (Azure Cost Management)
└─ Set up budget alerts ($60 limit in this case)
```

---

## 🎯 Resource Allocation

```
For DLAI Crop AI MVP:

┌─ Frontend SPA
│  ├─ Static Web Apps (FREE)
│  ├─ Storage: ~2-3 MB (optimized build)
│  └─ Bandwidth: 100 GB/month included
│
├─ Backend API
│  ├─ Container Instances
│  ├─ CPU: 1 vCPU (sufficient for ~100 req/sec)
│  ├─ Memory: 1 GB (for Python + FastAPI)
│  └─ Right-size: Monitor with Application Insights
│
├─ Image Storage (Optional)
│  ├─ Blob Storage
│  ├─ Usage: Store satellite imagery
│  └─ Cost: Pay per GB
│
└─ Database (If needed)
   ├─ Azure SQL / PostgreSQL
   ├─ Start: Basic tier (~$35/month)
   └─ Scale: Up as data grows
```

---

**This architecture is:**
- ✅ Highly scalable (can grow from 100 to 1M users)
- ✅ Cost-effective ($50-60 for MVP)
- ✅ Production-ready (auto HTTPS, monitoring, backups)
- ✅ Developer-friendly (auto-deployment, easy debugging)

**Ready to deploy?** Start with the AZURE_QUICK_REFERENCE.md! 🚀
