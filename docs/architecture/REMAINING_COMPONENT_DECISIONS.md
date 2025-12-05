# Critical Component Decisions - Architecture Roadmap

**Date:** December 5, 2025  
**Status:** Component Gap Analysis  
**Purpose:** Identify and prioritize remaining architectural decisions

---

## Executive Summary

You've locked in **3 foundational components** ✅:
- PostgreSQL v17 (Database)
- Redis (Cache)
- RQ (Job Queue)

**10 major component decisions** remain with varying priority levels.

**Recommendation:** Focus on **Priority 1 components** before MVP launch:
1. Authentication & Authorization (foundational, security-critical)
2. Blob Storage & Lifecycle (cost & performance critical)
3. Logging & Observability (operational necessity)

---

## All 10 Remaining Decisions (Priority Ranked)

### 🔴 PRIORITY 1: AUTHENTICATION & AUTHORIZATION

**Why Critical:**
- Foundational (touches every API endpoint)
- Must decide early (impacts API design)
- Security-critical (cannot retrofit safely)
- Determines multi-tenancy capabilities

**Key Questions:**
- How do we authenticate users?
- How do we manage API keys (for ML services)?
- How do we enforce permissions (RBAC)?
- How do we handle token refresh?
- Do we support SSO/OAuth2?

**Options to Evaluate:**

```
A) JWT + PostgreSQL (Simplest)
   ├─ Store users & roles in PostgreSQL
   ├─ Issue JWT tokens on login
   ├─ Validate JWT on each request
   ├─ Cost: $0 (use existing DB)
   ├─ Complexity: Low
   ├─ Best for: MVP, single tenant
   └─ Cons: No SSO, manual token refresh

B) OAuth2 + Azure AD (Enterprise)
   ├─ Delegate auth to Azure AD
   ├─ Support company directory
   ├─ Built-in MFA
   ├─ Cost: Free (included with Azure)
   ├─ Complexity: Medium
   ├─ Best for: Enterprise customers
   └─ Cons: Azure-specific

C) API Keys + Key Vault (Service-to-Service)
   ├─ For GPU workers & external integrations
   ├─ Store keys in Azure Key Vault
   ├─ Rate limit per API key
   ├─ Cost: $0.50/month (Key Vault)
   ├─ Complexity: Low
   ├─ Best for: Programmatic access
   └─ Cons: Not user-friendly

D) Hybrid: JWT + OAuth2 + API Keys (Complete)
   ├─ JWT for user frontend
   ├─ OAuth2 for SSO (optional)
   ├─ API Keys for external services
   ├─ Cost: $0-10/month
   ├─ Complexity: High
   ├─ Best for: Full-featured product
   └─ Cons: Most operational overhead
```

**RECOMMENDED:** JWT + PostgreSQL for MVP (simplest, lowest cost)
**MIGRATION PATH:** Add OAuth2 later when needed

---

### 🔴 PRIORITY 2: FILE/BLOB STORAGE & LIFECYCLE

**Why Critical:**
- Satellite imagery can be 50MB+ per file
- Storage costs grow quickly with scale
- Multi-cloud redundancy needed for DR
- Performance impact on image delivery

**Key Questions:**
- Where do we store satellite images?
- How long do we keep them?
- Do we need multi-cloud replication?
- How do we optimize costs?
- Do we need CDN for fast download?

**Options to Evaluate:**

```
A) Azure Blob Storage (Simplest - Currently In Use)
   ├─ Tiers:
   │  ├─ Hot: $0.018/GB (frequent access)
   │  ├─ Cool: $0.009/GB (30+ day minimum)
   │  └─ Archive: $0.002/GB (90+ day minimum)
   ├─ Lifecycle policies (auto-tier)
   ├─ Cost: $2/month (100GB), $18/month (1TB)
   ├─ Complexity: Low
   ├─ Best for: Azure-first
   └─ Redundancy: Geo-redundant optional ($10-20/mo)

B) AWS S3 (Multi-Cloud Hedge)
   ├─ Tiers:
   │  ├─ Standard: $0.023/GB
   │  ├─ Intelligent-Tiering: $0.0125/GB
   │  └─ Glacier: $0.004/GB
   ├─ Lifecycle policies
   ├─ Cost: $2.30/month (100GB), $23/month (1TB)
   ├─ Complexity: Medium (cross-cloud)
   ├─ Best for: Multi-cloud strategy
   └─ Redundancy: Built-in across regions

C) Azure Blob + S3 Replication (Multi-Cloud)
   ├─ Primary: Azure Blob (hot access)
   ├─ Secondary: AWS S3 (disaster recovery)
   ├─ Async replication (cheaper than sync)
   ├─ Cost: $20-30/month (100GB), $40-50/month (1TB)
   ├─ Complexity: High (dual management)
   ├─ Best for: Enterprise DR requirements
   └─ Recovery time: Minutes to hours

D) Azure Blob + CDN (Performance Focus)
   ├─ Primary: Azure Blob Storage
   ├─ Acceleration: Azure CDN ($20-50/month)
   ├─ Cost: $22-35/month (100GB + CDN)
   ├─ Complexity: Medium
   ├─ Best for: Global users, fast downloads
   └─ Latency: <100ms globally
```

**RECOMMENDED:** Azure Blob with lifecycle policies + optional S3 backup
**COST OPTIMIZATION:** Auto-tier to Cool after 30 days, Archive after 90 days
**ESTIMATED COST:** $10-20/month with lifecycle policies

---

### 🔴 PRIORITY 3: LOGGING & OBSERVABILITY

**Why Critical:**
- Essential for production debugging
- Incident response & root cause analysis
- Compliance & audit trail
- Performance troubleshooting

**Key Questions:**
- Where do we aggregate logs?
- How long do we retain logs?
- Can we search/filter in real-time?
- What's structured vs unstructured logging?
- How do we alert on errors?

**Options to Evaluate:**

```
A) Azure Log Analytics (Integrated - Simplest)
   ├─ Part of Azure Monitor
   ├─ KQL queries for searching
   ├─ Integration with Application Insights
   ├─ Cost: $3-5 per GB ingested (~$30-50/month)
   ├─ Retention: 90 days free, then paid
   ├─ Complexity: Low
   ├─ Best for: Azure-native projects
   └─ Cons: Azure-specific

B) ELK Stack (Elasticsearch, Logstash, Kibana)
   ├─ Self-hosted on VM
   ├─ Full control, powerful queries
   ├─ Elasticsearch: $40-60/month (self-hosted)
   ├─ Logstash + Kibana: $20-30/month
   ├─ Complexity: High (manage 3 services)
   ├─ Best for: Multi-cloud, full control
   └─ Cons: Operational overhead

C) Loki + Grafana (Lightweight)
   ├─ Optimized for container logs
   ├─ Uses labels instead of full indexing
   ├─ Grafana for visualization
   ├─ Cost: $20-40/month self-hosted
   ├─ Complexity: Medium
   ├─ Best for: Kubernetes/Docker
   └─ Cons: Learning curve

D) Datadog (Managed - Best Features)
   ├─ Logs + metrics + traces
   ├─ Auto-instrumentation
   ├─ Beautiful dashboards
   ├─ Cost: $100-200+/month (overkill for MVP)
   ├─ Complexity: Low (managed service)
   ├─ Best for: Enterprise scale
   └─ Cons: Expensive for MVP
```

**RECOMMENDED:** Azure Log Analytics (already in Azure ecosystem)
**COST:** $30-50/month for MVP volume
**RETENTION POLICY:** 30 days hot, 365 days cold archive

---

### 🟡 PRIORITY 4: API GATEWAY & RATE LIMITING

**Why Important:**
- Protects backend from overload
- Prevents DOS attacks
- Manages API versioning
- Implements request throttling

**Key Questions:**
- Do we need a dedicated API gateway?
- How do we rate limit? (per-user? per-key? global?)
- Can we route requests based on URL path?
- Do we need request/response transformation?

**Options to Evaluate:**

```
A) No API Gateway (Simplest)
   ├─ Rate limiting built into FastAPI
   ├─ Using slowapi library
   ├─ Cost: $0
   ├─ Complexity: Low
   ├─ Best for: MVP
   └─ Cons: No advanced routing

B) Azure API Management
   ├─ Managed gateway
   ├─ Rate limiting policies
   ├─ API versioning
   ├─ Cost: $50-200+/month
   ├─ Complexity: Medium
   ├─ Best for: Enterprise
   └─ Cons: Expensive for MVP

C) Kong (Open-Source)
   ├─ Self-hosted API gateway
   ├─ Rich plugin ecosystem
   ├─ Cost: $0 (+ $30-50/mo VM)
   ├─ Complexity: High
   ├─ Best for: Complex routing needs
   └─ Cons: Operational overhead

D) AWS API Gateway (If multi-cloud)
   ├─ Managed gateway
   ├─ $3.50 per million requests
   ├─ Cost: $10-20/month MVP
   ├─ Complexity: Low
   ├─ Best for: Multi-cloud
   └─ Cons: AWS-specific
```

**RECOMMENDED:** Built-in FastAPI rate limiting for MVP (slowapi library)
**MIGRATE TO:** Azure API Management if enterprise features needed

---

### 🟡 PRIORITY 5: MACHINE LEARNING MODEL MANAGEMENT

**Why Important:**
- Critical for ML product (versioning, A/B testing)
- Model deployment automation
- Prevents "model drift" issues
- Enables A/B testing of improvements

**Key Questions:**
- How do we version models?
- Can we A/B test two models?
- How do we deploy new models safely?
- How do we track which model made each prediction?
- Can we rollback to previous model?

**Options to Evaluate:**

```
A) Simple File Versioning (MVP)
   ├─ Store models in blob storage
   ├─ Name: model_v1.0.pth, model_v2.0.pth
   ├─ Track version in inference results
   ├─ Cost: $0
   ├─ Complexity: Low
   ├─ Best for: MVP (single model)
   └─ Cons: No A/B testing, manual rollback

B) MLflow (Open-Source Model Registry)
   ├─ Track experiments & models
   ├─ Model versioning & staging
   ├─ Self-hosted: $30-50/month
   ├─ Complexity: Medium
   ├─ Best for: ML teams
   └─ Cons: Another service to manage

C) Azure ML (Managed)
   ├─ Model registry
   ├─ A/B testing capabilities
   ├─ Deployment automation
   ├─ Cost: $50-100/month
   ├─ Complexity: Medium
   ├─ Best for: Azure-native ML
   └─ Cons: Lock-in

D) Weights & Biases (Modern)
   ├─ Experiment tracking
   ├─ Model versioning
   ├─ Visualization
   ├─ Cost: Free for research, $60+/month commercial
   ├─ Complexity: Low
   ├─ Best for: ML-first teams
   └─ Cons: Requires account
```

**RECOMMENDED:** Simple file versioning for MVP (add MLflow later)
**MIGRATION PATH:** Plan MLflow integration when doing A/B testing

---

### 🟡 PRIORITY 6: REAL-TIME NOTIFICATIONS

**Why Important:**
- User experience (know when analysis completes)
- Optional but improves usability
- Can be added post-MVP

**Key Questions:**
- When analysis completes, how do we notify user?
- Do we need push notifications (mobile)?
- Do we need email notifications?
- What's the retry strategy for failed notifications?

**Options to Evaluate:**

```
A) Polling Only (MVP - Simplest)
   ├─ User polls /api/results/{job_id}
   ├─ Check status every 5 seconds
   ├─ Cost: $0
   ├─ Complexity: Low
   ├─ Best for: MVP
   └─ Cons: Not real-time, battery drain on mobile

B) Webhooks (Recommended)
   ├─ We call user's webhook when done
   ├─ Requires user to implement endpoint
   ├─ Cost: $0
   ├─ Complexity: Low
   ├─ Best for: API-first users
   └─ Cons: Requires external endpoint

C) WebSockets (Real-Time)
   ├─ Keep connection open
   ├─ Push results immediately
   ├─ Cost: $0 (Redis adapter)
   ├─ Complexity: High
   ├─ Best for: SPA frontend
   └─ Cons: Connection management overhead

D) Email Notifications (SendGrid)
   ├─ Send email when analysis completes
   ├─ Cost: $10-20/month (high volume)
   ├─ Complexity: Low
   ├─ Best for: Optional email alerts
   └─ Cons: Not real-time

E) Mobile Push (Firebase Cloud Messaging)
   ├─ Send push to mobile app
   ├─ Cost: $0
   ├─ Complexity: Medium
   ├─ Best for: Mobile app
   └─ Cons: Requires mobile app
```

**RECOMMENDED:** Webhooks for MVP (most flexible)
**FUTURE:** Add WebSockets for SPA real-time updates

---

### 🟡 PRIORITY 7: ERROR HANDLING & RECOVERY

**Why Important:**
- Prevents cascading failures
- Improves reliability
- Enables graceful degradation

**Key Questions:**
- What happens when GPU inference fails?
- Do we retry failed jobs?
- What's the circuit breaker strategy?
- Do we have fallback models?
- How do we handle permanently failed jobs?

**Recommended Strategies:**

```
1. Retry Logic
   ├─ Retry failed jobs up to 3 times
   ├─ Exponential backoff (1s, 2s, 4s)
   ├─ Implementation: RQ supports this natively
   └─ Cost: $0

2. Circuit Breaker
   ├─ If GPU workers failing (>50%), reject new jobs
   ├─ Return 503 Service Unavailable
   ├─ Prevent cascade failures
   ├─ Implementation: PyBreaker library
   └─ Cost: $0

3. Dead-Letter Queue (DLQ)
   ├─ Move permanently failed jobs to DLQ
   ├─ Alert operations team
   ├─ Allow manual retry later
   ├─ Implementation: RQ supports this
   └─ Cost: $0

4. Fallback Model
   ├─ If primary model fails, use simpler model
   ├─ Trade accuracy for availability
   ├─ Implementation: Load 2 models in worker
   └─ Cost: $0 (extra GPU memory)

5. Request Timeout
   ├─ Set max job duration (30 min)
   ├─ Kill jobs exceeding timeout
   ├─ Prevent stuck jobs
   ├─ Implementation: RQ job_timeout parameter
   └─ Cost: $0
```

**RECOMMENDATION:** Implement all 5 strategies (RQ supports most natively)

---

### 🟡 PRIORITY 8: ASYNC RESULT DELIVERY & POLLING

**Why Important:**
- User experience: how quickly they get results
- API design: polling vs webhooks vs websockets
- Result TTL: when to clean up results

**Key Questions:**
- How long do we keep job results in Redis?
- Do we store results in PostgreSQL long-term?
- What's the API versioning strategy?
- Do we support WebSocket connections?

**Recommended Approach:**

```
Result Lifecycle:
─────────────────────────────────────

1. Job Queued (0-5 seconds)
   └─ Result not yet available

2. Job Processing (5-20 seconds)
   └─ User can poll status

3. Job Complete (20 seconds)
   ├─ Store in Redis (24 hour TTL)
   ├─ Store in PostgreSQL (permanent)
   └─ Return 200 OK with results

4. Result Retrieval (user polls)
   ├─ Check Redis first (fast, <1ms)
   ├─ If not in Redis, check PostgreSQL
   └─ Return cached result

5. Old Results (>24 hours)
   ├─ Delete from Redis (auto-expiry)
   ├─ Keep in PostgreSQL (audit trail)
   └─ Available for historical queries

API Design:
─────────────────────────────────────

GET /api/results/{job_id}

Response if processing:
{
  "status": "processing",
  "progress_percent": 45,
  "estimated_seconds_remaining": 10
}

Response if complete:
{
  "status": "complete",
  "result": {
    "crop_type": "wheat",
    "confidence": 0.94,
    ...
  }
}

Response if failed:
{
  "status": "failed",
  "error": "GPU out of memory"
}
```

**RECOMMENDATION:** Implement above pattern (Redis TTL + PostgreSQL archive)

---

### 🟡 PRIORITY 9: HTTP CACHING & CDN STRATEGY

**Why Important:**
- Improves performance for repeated requests
- Reduces database load
- CDN improves global access speed

**Key Questions:**
- What should be cached in HTTP headers?
- Should API responses be cached?
- Do we need CDN for API?
- How do we invalidate cache?

**Recommended Approach:**

```
HTTP Cache Headers:
──────────────────────

1. Static Frontend (SPA)
   ├─ Cache-Control: max-age=31536000 (1 year)
   ├─ Use file hashing (app.abc123.js)
   ├─ Cache-bust on deploy
   └─ Served via CDN

2. API Endpoints
   ├─ GET /api/crops/{id}
   │  └─ Cache-Control: max-age=300 (5 min)
   ├─ GET /api/results/{job_id}
   │  └─ Cache-Control: no-cache (dynamic)
   └─ POST endpoints
      └─ Cache-Control: no-store (never cache)

3. Images (Satellite)
   ├─ Cache-Control: max-age=2592000 (30 days)
   ├─ Serve via CDN + blob storage
   ├─ ETag for conditional requests
   └─ 304 Not Modified for unchanged

CDN Implementation:
──────────────────────

Option A: Azure CDN
├─ Endpoint: api-cdn.azureedge.net
├─ Cost: $0.15 per GB (first 10TB)
├─ At 1TB/month: $150/month
└─ Best for: Static assets

Option B: No CDN (MVP)
├─ Serve from blob storage directly
├─ Local Redis cache for API results
├─ Cost: $0
└─ Good enough for MVP
```

**RECOMMENDATION:** Skip CDN for MVP (use local Redis caching)
**MIGRATE TO:** Azure CDN when global users need it

---

### 🟡 PRIORITY 10: MULTI-REGION DEPLOYMENT STRATEGY

**Why Important:**
- Disaster recovery & high availability
- Reduced latency for global users
- Compliance requirements

**Key Questions:**
- How many regions do we start with?
- How do we sync data across regions?
- What's the RTO/RPO requirements?
- How do we route users to nearest region?

**Recommended Approach (Future - Not MVP):**

```
Phase 1 (MVP): Single Region
├─ Primary: Azure East US
├─ Backup: Manual (restore from backup)
├─ RTO: 4-8 hours
├─ Cost: $161-180/month

Phase 2: Active-Passive (Growth)
├─ Primary: Azure East US (writes)
├─ Secondary: AWS us-east (read replica)
├─ RTO: 30-60 minutes
├─ RPO: 5 minutes (lag acceptable)
├─ Cost: +$50-100/month

Phase 3: Active-Active (Scale)
├─ Primary: Azure East US
├─ Secondary: Azure Europe
├─ Tertiary: AWS Pacific
├─ Global routing (geo-DNS)
├─ RTO: <1 minute
├─ RPO: Near zero
├─ Cost: +$200-300/month
```

**RECOMMENDATION:** Start single-region MVP, plan Phase 2 for Q2 2026

---

## Prioritization Framework

```
IMMEDIATE (Before MVP Launch):
  🔴 Priority 1: Authentication & Authorization
  🔴 Priority 2: File/Blob Storage & Lifecycle
  🔴 Priority 3: Logging & Observability

BEFORE PRODUCTION:
  🟡 Priority 4: API Gateway & Rate Limiting (use FastAPI built-in)
  🟡 Priority 5: ML Model Management (simple versioning)
  🟡 Priority 7: Error Handling & Recovery

READY FOR MVP (Already Handled):
  ✅ Priority 8: Async Result Delivery (RQ handles)
  
NICE-TO-HAVE (Post-MVP):
  🟢 Priority 6: Real-Time Notifications (add webhooks later)
  🟢 Priority 9: HTTP Caching & CDN (optimize after launch)
  🟢 Priority 10: Multi-Region (Phase 2, 2026)
```

---

## Decision Matrix Summary

| Component | MVP | Growth | Scale | Complexity | Cost Impact |
|-----------|-----|--------|-------|-----------|-------------|
| Auth | JWT | JWT+OAuth2 | OAuth2+SAML | Medium | $0-20/mo |
| Blob | Azure Blob | Blob + S3 | Blob + S3 + CDN | Low | $20-50/mo |
| Logging | Log Analytics | Log Analytics | Datadog | Low | $30-100/mo |
| API Gateway | FastAPI | FastAPI | API Mgmt | Low | $0-50/mo |
| ML Model | File version | MLflow | MLflow | Low | $0-50/mo |
| Notifications | Polling | Webhooks | WebSocket | Medium | $0-30/mo |
| Error Handling | RQ retry | Circuit breaker | Full recovery | Low | $0 |
| Result Delivery | Redis TTL | Redis + DB | Streaming | Low | $0 |
| HTTP Cache | No CDN | No CDN | With CDN | Low | $0-150/mo |
| Multi-region | Single | Active-passive | Active-active | High | $0-300/mo |

---

## Total Cost Projection (with all decisions)

```
MVP (Immediate):
├─ Database: $35-40
├─ Cache: $8-10
├─ Queue: $0 (RQ)
├─ GPU Worker: $60-70
├─ Blob Storage: $5 (with lifecycle)
├─ Auth: $0 (JWT in DB)
├─ Logging: $30-40
└─ TOTAL MVP: $208-250/month

Growth (Q1 2026):
├─ Previous: $250
├─ 3x GPU Workers: +$180
├─ S3 Replication: +$20
├─ Webhooks/Notifications: +$10
├─ MLflow: +$40
└─ TOTAL GROWTH: $500/month

Scale (Q3 2026):
├─ Previous: $500
├─ Multi-region: +$300
├─ CDN: +$150
├─ API Gateway: +$50
├─ APM (Datadog): +$100
└─ TOTAL SCALE: $1100/month
```

---

## Recommended Action Plan

### This Week:
- [ ] **Decision 1: Authentication** → Choose JWT + PostgreSQL
- [ ] **Decision 2: Blob Storage** → Plan lifecycle policies (Hot 30d → Cool 90d → Archive)
- [ ] **Decision 3: Logging** → Set up Azure Log Analytics

### Next Week:
- [ ] **Decision 4: Error Handling** → Implement retry + circuit breaker in RQ
- [ ] **Decision 5: Result TTL** → Configure Redis 24-hour TTL
- [ ] **Decision 6: Rate Limiting** → Add slowapi to FastAPI

### Before Launch:
- [ ] **Decision 7: Model Versioning** → Name models by version (v1.0, v1.1, v2.0)
- [ ] **Decision 8: Monitoring** → Dashboard for queue depth, GPU load, errors

---

**Document Version:** 1.0  
**Created:** December 5, 2025  
**Status:** Ready for Team Decision-Making
