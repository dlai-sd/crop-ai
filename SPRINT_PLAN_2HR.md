# 2-Hour Production Hardening Sprint - Strategic Plan

## 📋 SITUATION ANALYSIS

### Current State
✅ GitHub CI exists (basic Python testing + Docker build)
✅ Docker setup ready for ACR push
✅ Application Insights already in requirements.txt
✅ Dockerfile configured correctly
✅ App uses FastAPI (perfect for logging)

### What We Need to Add
1. **Code Review Integration** - Copilot Code Review in PRs
2. **Security Hardening** - HTTPS backend + Key Vault
3. **CI/CD Enhancement** - Docker push to ACR + auto-deploy
4. **Monitoring** - Application Insights + Container Insights + Cost Alerts

---

## 🎯 2-HOUR EXECUTION PLAN

### PHASE 1: Code Review Integration (10 minutes)
**Goal:** Enable GitHub Copilot code review on PRs

**Tasks:**
- [ ] Add `codeql-analysis.yml` workflow for security scanning
- [ ] Configure branch protection rules requiring code review
- [ ] Add CODEOWNERS file for automatic reviewer assignment
- [ ] Configure Copilot PR review settings

**Why first:** Enables automated security checks on all code changes

---

### PHASE 2: Security & HTTPS Backend (25 minutes)
**Goal:** Enable HTTPS on backend + Key Vault integration

**Strategy:**
- Option A (Quick - 20 min): Use Application Gateway (HTTPS termination)
- Option B (Simple - 15 min): Use App Service instead of Container Instance
- **RECOMMENDED:** Option B - App Service migration

**Tasks:**
- [ ] Create App Service Plan (B1 tier - $10-15/month)
- [ ] Deploy container to App Service (auto HTTPS)
- [ ] Create Azure Key Vault (free tier)
- [ ] Add secrets: DB connection, API keys
- [ ] Update container env vars from Key Vault
- [ ] Update CORS headers in FastAPI

**Cost Impact:** +$10-15/month (worth it for HTTPS + Key Vault)

---

### PHASE 3: CI/CD Enhancement (35 minutes)
**Goal:** Automated build, push to ACR, deploy to Azure

**Workflow:**
```
git push → GitHub Actions
  ├─ Build Docker image
  ├─ Run tests
  ├─ Push to ACR
  └─ Auto-deploy to Container Instance/App Service
```

**Tasks:**
- [ ] Add Azure login action to CI workflow
- [ ] Add Docker build-push to ACR step
- [ ] Add App Service deploy step
- [ ] Configure secrets: AZURE_CREDENTIALS
- [ ] Test workflow with dummy commit

**Time Breakdown:**
- Modify CI workflow: 10 min
- Add deployment steps: 15 min
- Configure Azure credentials: 5 min
- Test and verify: 5 min

---

### PHASE 4: Monitoring & Observability (35 minutes)
**Goal:** Application Insights, Container Insights, Cost Alerts

**Tasks:**

**4A. Application Insights (15 min)**
- [ ] Create Application Insights resource
- [ ] Add instrumentation key to FastAPI app
- [ ] Configure dashboard for key metrics
- [ ] Set up alerts for errors (threshold > 5/min)

**4B. Container Insights (10 min)**
- [ ] Enable Container Insights on ACI/App Service
- [ ] Create log queries for performance
- [ ] Set up real-time monitoring dashboard

**4C. Cost Alerts (5 min)**
- [ ] Create budget alert (trigger at $70/month)
- [ ] Configure daily cost reports
- [ ] Set up dashboard in Azure Portal

**4D. GitHub Action Monitoring (5 min)**
- [ ] Add workflow failure notifications
- [ ] Create badges in README

---

## 💡 STRATEGIC INSIGHTS

### What's Smart About This Approach
1. **Sequential Dependencies** - Each phase builds on previous
2. **Risk Minimization** - Phase 2 keeps backend running while upgrading
3. **Cost Optimization** - App Service is only $2-3 more than ACI
4. **Automation Payoff** - CI/CD saves hours of manual deployment
5. **Visibility** - Monitoring catches issues before users report them

### Potential Bottlenecks & Solutions
| Bottleneck | Impact | Solution | ETA |
|-----------|--------|----------|-----|
| App Service migration downtime | 5 min | Keep old ACI during transition | handled |
| Azure credentials in secrets | Security risk | Use OIDC federation | 3 min |
| Key Vault rate limits | Rate errors | Cache secrets in app | 2 min |
| Application Insights lag | Delayed metrics | Accept 30s delay (normal) | N/A |

### Time Buffer
- Planned: 105 minutes
- Available: 120 minutes
- Buffer: 15 minutes (can use for testing/fixes)

---

## 🚀 EXECUTION ORDER (Critical)

**MUST DO IN THIS ORDER:**

1. ✅ **Code Review** - 10 min (no dependencies)
2. ✅ **CI/CD Setup** - 35 min (before any deployment)
3. ✅ **Security/HTTPS** - 25 min (while workflows run)
4. ✅ **Monitoring** - 35 min (observes everything)

**Why:** This way:
- Code Review catches issues early
- CI/CD automates future deployments
- Security hardens the backend
- Monitoring observes the whole system

---

## 📝 SPECIFIC FILE CHANGES NEEDED

### New Files to Create
1. `.github/workflows/security-scan.yml` - CodeQL + Copilot review
2. `.github/CODEOWNERS` - Auto-assign reviewers
3. `src/crop_ai/monitoring.py` - Application Insights setup
4. `.github/workflows/deploy.yml` - Enhanced with ACR push + App Service

### Existing Files to Modify
1. `.github/workflows/ci.yml` - Add Azure login, Docker push, deploy steps
2. `src/crop_ai/api.py` - Add Application Insights instrumentation
3. `requirements.txt` - Already has applicationinsights ✓
4. `Dockerfile` - No changes needed ✓

---

## ✅ SUCCESS CRITERIA

After 2 hours:
- [ ] Code review workflow runs on PRs
- [ ] Copilot reviews new code automatically
- [ ] Backend has HTTPS certificate
- [ ] Secrets stored in Key Vault
- [ ] CI/CD automatically deploys on git push
- [ ] Application Insights logs all API calls
- [ ] Cost alerts configured
- [ ] All systems monitored in real-time
- [ ] README updated with new process

---

## 🎯 QUICK START CHECKLIST

```
Phase 1 (10 min):
  [ ] Create security scan workflow
  [ ] Add CODEOWNERS file
  [ ] Enable branch protection

Phase 2 (25 min):
  [ ] Create Key Vault
  [ ] Migrate to App Service or add Application Gateway
  [ ] Update CORS in FastAPI
  [ ] Test HTTPS connection

Phase 3 (35 min):
  [ ] Enhance CI workflow
  [ ] Add Docker push to ACR
  [ ] Add App Service deploy
  [ ] Configure AZURE_CREDENTIALS secret
  [ ] Test full pipeline

Phase 4 (35 min):
  [ ] Create Application Insights resource
  [ ] Add instrumentation to FastAPI
  [ ] Enable Container Insights
  [ ] Create cost budget alert
  [ ] Set up monitoring dashboards
```

---

## 📊 ESTIMATED OUTCOME

**After 2 Hours:**
- ✅ Automated security scanning on every PR
- ✅ HTTPS backend with encrypted secrets
- ✅ One-click deployments via git push
- ✅ Real-time monitoring and alerting
- ✅ Cost tracking and budget controls
- ✅ Full observability stack

**Productivity Gain:**
- Manual deployments: ELIMINATED
- Security reviews: AUTOMATED
- Issue detection: REAL-TIME
- Future sprints: 30% faster

---

## 🔍 QUESTIONS FOR CONFIRMATION

Before we start:
1. **App Service or Application Gateway?** (recommend App Service - simpler)
2. **Monitoring granularity?** (recommend: ALL endpoints + errors + performance)
3. **Cost alert threshold?** (recommend: $70/month)
4. **Code review strictness?** (recommend: warn but allow override)

---

Generated: December 5, 2025, 9:00 AM
Ready to execute in 2-hour sprint window
