# Azure Deployment - Quick Reference Card

## 🎯 Quick Summary

**Your App:** Angular SPA + Python FastAPI Backend  
**Best Azure Option:** Static Web Apps (Free) + Container Instances ($40-50/mo)  
**Total Cost:** ~$50/month (bare minimum, very scalable)

---

## 💰 Cost Comparison

| Solution | Monthly Cost | Pros | Cons |
|----------|-------------|------|------|
| **Azure (Recommended)** | ~$50 | Bare minimum, auto-scaling, auto-HTTPS | 2 services to manage |
| AWS (EC2 + S3) | ~$50-80 | Flexible | More complex |
| DigitalOcean (Droplet) | ~$5-30 | Cheaper | Limited scaling |
| Heroku | ~$100+ | Simple deployment | Expensive for scale |

---

## 🚀 What You Get (Azure Bare Minimum)

```
✅ Angular SPA
   - Free Static Web Apps hosting
   - Global CDN
   - Auto HTTPS
   - Auto-deploy on git push

✅ Python API Backend
   - Azure Container Instances
   - ~35-50 USD/month
   - 1 vCPU, 1GB RAM
   - Public IP with DNS

✅ Monitoring
   - Application Insights (Free)
   - Real-time logging
   - Error tracking

✅ Security
   - Azure Key Vault (Free limited)
   - Managed HTTPS
   - CORS ready
```

---

## 📋 Pre-Deployment Checklist

### Code Level
- [ ] `ng build --configuration production` runs without errors
- [ ] Angular dist/ folder is < 3MB
- [ ] Docker build succeeds
- [ ] Backend runs on 0.0.0.0:8000
- [ ] CORS middleware configured
- [ ] Environment variables separated from code

### Azure Level
- [ ] Azure account created (get free $200 credit)
- [ ] Azure CLI installed: `az --version`
- [ ] GitHub repo ready (dlai-sd/crop-ai)
- [ ] Dockerfile present in root

---

## ⚡ 5-Minute Deployment Flow

### 1. Build Angular (2 min)
```bash
cd frontend/angular
npm run build:prod  # or: ng build --configuration production
```

### 2. Create Azure Resources (1 min)
- Go to Azure Portal
- Search "Static Web Apps"
- Connect GitHub repo
- Point to `frontend/angular/dist/crop-ai-ng`

### 3. Deploy Backend (2 min)
```bash
# Create registry
az acr create -n cropairegistry -g crop-ai-rg --sku Basic

# Push image
az acr build -r cropairegistry --image crop-ai-api:latest .

# Deploy container
az container create -g crop-ai-rg -n crop-ai-api \
  --image cropairegistry.azurecr.io/crop-ai-api:latest \
  --cpu 1 --memory 1 --ports 8000 --ip-address Public
```

### 4. Update Environment (1 min)
- Update `environment.prod.ts` with backend URL
- Commit to main
- Auto-redeploy!

---

## 🔑 Key Azure Services

| Service | Purpose | Cost |
|---------|---------|------|
| Static Web Apps | Host your Angular SPA | Free |
| Container Registry | Store Docker images | $5/month |
| Container Instances | Run Python API | $35-50/month |
| App Insights | Monitoring | Free (limited) |
| Key Vault | Store secrets | Free (limited) |

---

## 🌍 Expected URLs After Deployment

```
Frontend (SPA):  https://crop-ai-landing.azurestaticapps.net
Backend (API):   https://crop-ai-api.centralindia.azurecontainers.io
```

---

## ❌ Common Issues & Fixes

### "Static Web App shows 404"
- ✅ Check `app_location` in deployment settings
- ✅ Verify `dist/crop-ai-ng` contains `index.html`

### "CORS errors in frontend"
- ✅ Add backend URL to `staticwebapp.config.json`
- ✅ Verify backend CORS middleware is configured

### "Container Instance times out"
- ✅ Check public IP: `az container show -g crop-ai-rg -n crop-ai-api --query ipAddress.fqdn`
- ✅ View logs: `az container logs -g crop-ai-rg -n crop-ai-api --follow`

### "High costs"
- ✅ Use Azure Cost Management to identify spike
- ✅ Consider scheduled shutdown for off-hours
- ✅ Right-size Container Instance if underutilized

---

## 📊 Monitoring

### Check Cost in Real-Time
```bash
az consumption usage list --subscription-id <id> --query "[0:5]"
```

### View Container Logs
```bash
az container logs -g crop-ai-rg -n crop-ai-api --follow
```

### Monitor Frontend Performance
- Azure Portal → Static Web App → Analytics
- See traffic, errors, performance metrics

---

## 🎯 Next Steps

1. **Today:** Review this guide, set up Azure free account
2. **Tomorrow:** Deploy frontend to Static Web Apps
3. **Later:** Deploy backend to Container Instances
4. **Production:** Add custom domain, SSL certificate

---

## 📞 Quick Commands Reference

```bash
# List all resources
az resource list -g crop-ai-rg --output table

# Delete everything (to stop costs)
az group delete -n crop-ai-rg

# Restart container
az container restart -g crop-ai-rg -n crop-ai-api

# View environment variables
az container show -g crop-ai-rg -n crop-ai-api \
  --query containers[0].environmentVariables
```

---

**Total Time to Deploy: ~30-45 minutes**  
**Cost to Start: $0 (free tier)**  
**Monthly Operating Cost: ~$50 (bare minimum)**

Ready to deploy? 🚀
