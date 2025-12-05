# Database Selection Decision Framework

**Date:** December 5, 2025  
**Status:** Discussion & Decision-Making  
**Impact Level:** Critical (affects all future work)

---

## Executive Summary

This document guides the database technology selection for the Crop AI system. We need to choose between multiple database options that meet these requirements:
- **Low cost** (minimal operational overhead)
- **High performance** (minimal latency)
- **License-free** (open-source preferred)
- **Just-in-time support** (community-driven)
- **Multi-modal data** (text + images + videos)
- **Scalability** (grow with application needs)

---

## Core Requirements Analysis

### Functional Requirements
```
Data Types to Store:
├── Textual Data
│   ├── Crop identification metadata
│   ├── User annotations
│   ├── Analysis results
│   └── Configuration parameters
│
├── Images
│   ├── Satellite imagery (GeoTIFF, PNG, JPEG)
│   ├── Training dataset images
│   ├── Thumbnail previews
│   └── Size: 1-50MB per image
│
└── Videos (Future)
    ├── Time-series satellite footage
    ├── Drone footage
    ├── Size: 50-500MB per video
    └── Streaming requirements
```

### Non-Functional Requirements
| Requirement | Priority | Constraint |
|------------|----------|-----------|
| Latency | Critical | < 200ms for reads, < 500ms for writes |
| Throughput | High | 1K+ concurrent users |
| Availability | High | 99%+ uptime |
| Cost | High | ~$50-60/month total infrastructure budget |
| Scalability | High | Should handle 10x growth |
| License | Mandatory | Open-source, no licensing fees |
| Operations | Medium | Minimal operational overhead |
| On-Demand Operation | High | Start/stop during business hours only; no forced 24/7 operation |

---

## Critical Requirement: On-Demand Web Operation

This is a **game-changer requirement** that significantly impacts database selection. The system should:
- ✅ Start up when business hours begin
- ✅ Shut down when business hours end (or on-demand)
- ✅ Not force 24/7 operation (saves costs & resources)
- ✅ Resume quickly with minimal downtime

**Impact on Database Selection:**

| Database | Start/Stop | Resume Time | Data Persistence | Cost Savings |
|----------|-----------|-------------|-----------------|--------------|
| **PostgreSQL (Managed)** | ⭐⭐⭐⭐ Easy | 30-60 sec | ✅ Fully persistent | ⭐⭐⭐⭐ ~40% |
| **PostgreSQL (Self-hosted VM)** | ⭐⭐⭐⭐⭐ Very easy | 10-30 sec | ✅ Fully persistent | ⭐⭐⭐⭐⭐ ~60% |
| **MongoDB Atlas** | ⭐⭐⭐ Easy | 1-2 min | ✅ Fully persistent | ⭐⭐⭐ ~35% |
| **SQLite** | ⭐⭐⭐⭐⭐ Trivial | 0 sec (no server) | ✅ Fully persistent | ⭐⭐⭐⭐⭐ ~80% (embedded) |
| **Vector DB (Qdrant)** | ⭐⭐⭐⭐ Easy | 30 sec | ✅ Fully persistent | ⭐⭐⭐⭐ ~50% |
| **Firebase** | ⚠️ No option | Always on | ✅ Persistent | ❌ No savings (always charged) |

### Business Hour Operation Model

```
┌─────────────────────────────────────────────────────────────────┐
│ 6:00 AM - Start Infrastructure (via Azure Automation)           │
│   ├── Start Azure Virtual Machine (if self-hosted)              │
│   ├── Start PostgreSQL instance (if managed)                    │
│   └── Warm up application servers                               │
│                                                                  │
│ 6:30 AM - System Ready for Operations                           │
│   └── All services operational, data accessible                 │
│                                                                  │
│ 8:00 AM - 6:00 PM - Normal Operations                           │
│   └── Accept requests, process data, store results              │
│                                                                  │
│ 6:00 PM - Begin Shutdown (graceful)                             │
│   ├── Stop accepting new requests after 6 PM                    │
│   ├── Complete in-flight transactions                           │
│   └── Backup data (automated)                                   │
│                                                                  │
│ 6:30 PM - Infrastructure Shutdown                               │
│   ├── Stop PostgreSQL instance                                  │
│   ├── Stop application servers                                  │
│   └── Stop Virtual Machine                                      │
│                                                                  │
│ 6:30 PM - 6:00 AM - Offline (No costs, no operations)           │
│                                                                  │
│ COST IMPACT:                                                     │
│ • Normal 24/7: $100/month                                        │
│ • Business hours only (12/24): $50/month ⭐ 50% savings         │
│                                                                  │
│ • 8 AM - 6 PM operation (10 hrs): $42/month ⭐ 58% savings      │
│ • Extended hours (7 AM - 8 PM): $58/month ⭐ 42% savings       │
└─────────────────────────────────────────────────────────────────┘
```

### Implementation with Azure Automation

```PowerShell
# Azure Automation Runbook: Start-CropAiDatabase
# Scheduled: 5:45 AM (before business hours)

param(
    [string]$ResourceGroup = "crop-ai-rg",
    [string]$DatabaseServer = "crop-ai-postgres",
    [string]$VMName = "crop-ai-vm"
)

# Start PostgreSQL (managed service)
Start-AzPostgreSqlServer -ResourceGroupName $ResourceGroup `
                         -ServerName $DatabaseServer

# Or start VM (if self-hosted)
Start-AzVM -ResourceGroupName $ResourceGroup -Name $VMName

# Verify connectivity
$healthy = Test-Connection -ComputerName $DatabaseServer -Count 1
if ($healthy) { Write-Output "Database ready" }

---

# Azure Automation Runbook: Stop-CropAiDatabase
# Scheduled: 6:15 PM (after business hours)

param(
    [string]$ResourceGroup = "crop-ai-rg",
    [string]$DatabaseServer = "crop-ai-postgres"
)

# Graceful shutdown sequence
Stop-AzPostgreSqlServer -ResourceGroupName $ResourceGroup `
                        -ServerName $DatabaseServer `
                        -Force

# Backup is automatically created before shutdown
Write-Output "Database stopped. Backup created."
```

---

## Decision Tree: Database Technology Selection

```
┌─────────────────────────────────────────────────────────────────────┐
│         START: Database Technology Selection for Crop AI            │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
                ▼                         ▼
        ┌────────────────┐      ┌────────────────┐
        │  Store Images? │      │   Text-first   │
        │    (Primary)   │      │   (Secondary)  │
        └────────┬───────┘      └────────┬───────┘
                 │                       │
          ┌──────┴──────┐               │
          │             │               │
          ▼             ▼               ▼
    ┌──────────┐  ┌──────────┐  ┌──────────────┐
    │ Blob     │  │ Native   │  │ Traditional  │
    │ Storage  │  │ Search   │  │ Database     │
    │ (S3-like)│  │ Engine   │  │ (SQL/NoSQL)  │
    └────┬─────┘  └────┬─────┘  └──────┬───────┘
         │             │               │
         ▼             ▼               ▼
    ┌─────────────┐ ┌──────────┐ ┌──────────┐
    │ Metadata:   │ │Milvus    │ │PostgreSQL│
    │ PostgreSQL/ │ │Pinecone  │ │MongoDB   │
    │ MongoDB     │ │Qdrant    │ │Firebase  │
    │             │ │Weaviate  │ │CosmosDB  │
    │ Blob Store: │ └────┬─────┘ └──────────┘
    │ S3/Azure/   │      │
    │ Local FS    │      ▼
    │             │  ┌──────────┐
    │ Cost: $$-$$$│  │Purpose?  │
    │ Latency: ⭐ │  └────┬─────┘
    │             │       │
    │             │  ┌────┴─────┐
    │             │  │           │
    │             │  ▼           ▼
    │             │ Crop      Image
    │             │ Data      Search
    │             │  │           │
    │             │  ▼           ▼
    │             │ ✅        ⭐⭐
    │             │ Good      Best
    └─────────────┘
         │
         ▼
    ┌──────────────────┐
    │ HYBRID APPROACH  │
    │ (RECOMMENDED)    │
    │                  │
    │ PostgreSQL       │
    │ + Blob Storage   │
    │ + Optional Search│
    │ Engine           │
    └──────────────────┘
```

---

## Option Analysis: Detailed Comparison

### Option 1: PostgreSQL + Object Storage (HYBRID)

**Architecture:**
```
┌─────────────────────────────────────────┐
│         Application Layer               │
│  (FastAPI Backend)                      │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌──────────────┐
│ PostgreSQL  │  │ Object Store │
│             │  │              │
│ • Metadata  │  │ • Images     │
│ • Vector    │  │ • Videos     │
│   (pgvector)│  │ • Raw Data   │
│ • Indexing  │  │              │
└─────────────┘  └──────────────┘
```

#### Pros ✅
- **Best all-rounder** for multi-modal data
- **Mature ecosystem** (23+ years development)
- **ACID compliance** ensures data integrity
- **Vector support** (pgvector extension) for AI/ML
- **Excellent indexing** (BTREE, HASH, GiST, GIN)
- **Cost**: FREE (open-source)
- **Latency**: <50ms typical queries
- **Scalability**: Handles millions of records
- **Community**: 500K+ developers, extensive documentation
- **Flexibility**: Can store metadata + JSON + arrays
- **Azure support**: Managed service available (cheap)

#### Cons ❌
- Larger learning curve for advanced features
- Requires separate blob storage for images/videos
- Operational overhead for backups

#### Estimated Costs
```
Azure Database for PostgreSQL (Flexible Server):
- Compute: B1s (1 vCore, 2GB RAM) = $30-40/month
- Storage: 128GB SSD = $15-20/month
- Backups: Included (35 days)
- Geo-redundancy: $10-15/month (optional)
───────────────────────────────────────
Total: $55-75/month (or cheaper with Azure Free Credits)

Azure Blob Storage:
- Hot tier: $0.0184 per GB/month
- 1TB images = $18-20/month
```

#### Best For
- ✅ Structured data + images/videos
- ✅ Complex queries on metadata
- ✅ Vector search for AI/ML features
- ✅ Long-term data retention
- ✅ Compliance requirements

---

### Option 2: MongoDB + Object Storage

**Architecture:**
```
┌──────────────────────────────────────┐
│    Application Layer (FastAPI)       │
└──────────────┬───────────────────────┘
               │
       ┌───────┴────────────┐
       │                    │
       ▼                    ▼
┌──────────────┐    ┌──────────────┐
│  MongoDB     │    │ Object Store │
│              │    │              │
│ • JSON docs  │    │ • Images     │
│ • Metadata   │    │ • Videos     │
│ • Flexible   │    │ • Raw Data   │
│   schema     │    │              │
└──────────────┘    └──────────────┘
```

#### Pros ✅
- **Flexible schema** (JSON documents)
- **Easy to start** (minimal schema design)
- **Horizontal scaling** (sharding support)
- **Good community** (growing adoption)
- **Cost**: FREE (open-source)
- **Latency**: <100ms typical queries

#### Cons ❌
- **Weaker relational capabilities** than PostgreSQL
- **No native ACID** (transactions added in v4.0, complex)
- **Higher memory footprint** than PostgreSQL
- **Vector search less mature** (Atlas Search less flexible)
- **Operational complexity** for self-hosted
- **No native image/video support**

#### Estimated Costs
```
MongoDB Atlas (Managed):
- Shared cluster (free tier limited to 512MB)
- M10 cluster: $57/month
- Storage per GB: $0.10-$0.30
- Auto-scaling available

Or Self-hosted:
- Similar infrastructure to PostgreSQL
- Higher CPU/memory overhead
```

#### Best For
- ✅ Rapid prototyping
- ✅ Highly flexible data models
- ✅ Large-scale horizontal scalability
- ⚠️ Less ideal for this use case (overkill for structured crop data)

---

### Option 3: SQLite + Local/Cloud Storage

**Architecture:**
```
┌──────────────────────────────────────┐
│    Application (FastAPI)             │
└──────────────┬───────────────────────┘
               │
       ┌───────┴────────────┐
       │                    │
       ▼                    ▼
┌──────────────┐    ┌──────────────┐
│  SQLite      │    │ Cloud/Local  │
│  (File-based)│    │ Storage      │
│              │    │              │
│ • Single file│    │ • Images     │
│ • Embedded   │    │ • Videos     │
│ • No server  │    │              │
└──────────────┘    └──────────────┘
```

#### Pros ✅
- **Extremely simple** setup (single file)
- **Zero infrastructure** cost
- **ACID compliance**
- **No server needed**
- **Perfect for MVP/prototype**
- **Latency**: <10ms local queries

#### Cons ❌
- **NOT suitable for production** multi-user systems
- **Concurrency issues** at scale
- **Limited to single machine** (no clustering)
- **Backup complexity** increases with data size
- **Can't handle 1K+ concurrent users**
- **Performance degrades** with large datasets (>100GB)

#### Estimated Costs
```
SQLite: FREE
Storage: Your compute cost only
```

#### Best For
- ✅ Development/testing only
- ✅ MVP validation
- ❌ NOT for production crop identification system

---

### Option 4: Specialized Vector Databases (Milvus, Qdrant, Weaviate)

**Architecture:**
```
┌──────────────────────────────────────────┐
│    Application (FastAPI)                 │
└──────────────┬───────────────────────────┘
               │
       ┌───────┴────────────────────┐
       │                            │
       ▼                            ▼
┌──────────────────┐      ┌──────────────────┐
│ Vector Database  │      │ Metadata Storage │
│ (Milvus/Qdrant)  │      │ (PostgreSQL)     │
│                  │      │                  │
│ • Image vectors  │      │ • Crop info      │
│ • Similarity     │      │ • User data      │
│ • Fast search    │      │ • Timestamps     │
└──────────────────┘      └──────────────────┘
```

#### Pros ✅
- **Blazing-fast vector search** (<1ms for 1M vectors)
- **Perfect for image similarity** search
- **Purpose-built for ML/AI** workflows
- **Excellent for finding similar crops** across images
- **Cost**: FREE (open-source for Milvus/Qdrant)

#### Cons ❌
- **Requires separate metadata storage** (not all-in-one)
- **Operational complexity** (separate system to manage)
- **Learning curve** for vector concepts
- **Not ideal for text-only queries**
- **Overkill if not doing vector search** initially
- **Managed services expensive** (Pinecone $12+/month)

#### Estimated Costs
```
Self-hosted Qdrant:
- Compute (same as PostgreSQL) = $30-40/month
- No additional licensing

Pinecone (Managed):
- Starter: FREE (up to 100K vectors)
- Paid: $12+/month
```

#### Best For
- ✅ If you need to find similar crops from satellite images
- ✅ ML model inference on image vectors
- ✅ Future AI/ML features
- ⚠️ Requires PostgreSQL alongside for metadata

---

### Option 5: Firebase (Google's Managed)

**Architecture:**
```
┌──────────────────────────────────────────┐
│    Application (FastAPI)                 │
└──────────────┬───────────────────────────┘
               │
       ┌───────┴────────────────────┐
       │                            │
       ▼                            ▼
┌──────────────────┐      ┌──────────────────┐
│  Firestore       │      │  Cloud Storage   │
│  (NoSQL)         │      │  (Blob Storage)  │
│                  │      │                  │
│ • Real-time docs │      │ • Images         │
│ • Metadata       │      │ • Videos         │
└──────────────────┘      └──────────────────┘
```

#### Pros ✅
- **Fully managed** (zero ops)
- **Real-time capabilities**
- **Easy API** (good for prototyping)
- **Integrated with Google Cloud**

#### Cons ❌
- **Vendor lock-in** (Google-only)
- **Expensive at scale** ($6+/month → $100+/month)
- **Less flexibility** for complex queries
- **Pay-per-operation** model (unpredictable costs)
- **Limited vector search** (recent addition, expensive)

#### Estimated Costs
```
Firestore:
- Free tier: 1GB storage, 50K reads/day
- Beyond that: $0.06 per 100K reads
- At 10K/day: ~$18-25/month

Cloud Storage:
- Hot tier: $0.020/GB (1TB = $20/month)

Total: $40-50/month minimum
```

#### Best For
- ✅ Pure prototyping (not recommended for production)
- ❌ Not ideal for cost-conscious projects

---

## Decision Matrix: Scoring Comparison

| Factor | Weight | PostgreSQL | MongoDB | SQLite | Vector DB | Firebase |
|--------|--------|------------|---------|--------|-----------|----------|
| **Cost** | 20% | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) | ⭐⭐⭐ (3) |
| **Performance** | 20% | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) |
| **Scalability** | 15% | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐ (2) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) |
| **Image/Video Support** | 15% | ⭐⭐⭐⭐ (4) | ⭐⭐⭐ (3) | ⭐⭐⭐ (3) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) |
| **Ease of Use** | 10% | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐ (3) | ⭐⭐⭐⭐⭐ (5) |
| **License/Support** | 10% | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐ (3) |
| **Data Integrity** | 10% | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐ (3) | ⭐⭐⭐⭐ (4) |
| **Operational Overhead** | - | ⭐⭐⭐⭐ (4) | ⭐⭐⭐ (3) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐ (2) | ⭐⭐⭐⭐⭐ (5) |
| **On-Demand Operation** | 15% | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐ (4) | ⭐⭐⭐⭐⭐ (5) | ⭐⭐⭐⭐ (4) | ❌ (0) |
| | | | | | | |
| **WEIGHTED SCORE** | - | **4.6/5** 🥇 | **4.1/5** 🥈 | **3.8/5** | **4.2/5** 🥉 | **3.4/5** ⚠️ |

---

## Recommended Solution: Hybrid Architecture

### Primary Recommendation: **PostgreSQL + Azure Blob Storage**

```
Tier 1: Metadata & Structured Data
├── PostgreSQL (Azure Database for PostgreSQL)
├── Tables:
│   ├── crops (id, name, region, season, etc.)
│   ├── satellite_imagery_metadata (id, crop_id, date, coordinates, etc.)
│   ├── analysis_results (id, crop_id, confidence, predictions, vectors)
│   ├── users (id, email, organization, etc.)
│   └── annotations (id, crop_id, user_id, label, timestamp)
│
└── Vector Extension (pgvector)
    └── Store image embeddings for similarity search

Tier 2: Blob Storage
├── Azure Blob Storage (Hot tier)
├── Images: /satellite-imagery/{crop_id}/{timestamp}.tif
├── Thumbnails: /thumbnails/{crop_id}/{timestamp}.jpg
└── Videos: /video-series/{crop_id}/

Tier 3: Optional Future Enhancement
└── Qdrant (if vector search becomes heavy)
    └── For finding similar crops across regions
```

### Why This Combination?

1. **PostgreSQL**
   - Best for structured crop data (low latency queries)
   - ACID compliance ensures data consistency
   - pgvector extension supports AI/ML workflows
   - Mature monitoring & backup strategies
   - Cost-effective ($30-40/month)

2. **Azure Blob Storage**
   - Designed specifically for images/videos
   - Scales infinitely without database overhead
   - Geographic redundancy optional
   - $0.018/GB (1TB = $18/month)
   - CDN integration for fast downloads

3. **Scalability Path**
   - **Phase 1** (Now): PostgreSQL + Blob
   - **Phase 2** (When needed): Add Qdrant for vector search
   - **Phase 3** (Growth): PostgreSQL read replicas
   - **Phase 4** (Enterprise): Full sharding if needed

---

## Migration Path & Implementation Roadmap

### Phase 1: MVP (Weeks 1-2)
```sql
CREATE TABLE crops (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    region VARCHAR(255),
    country VARCHAR(255),
    crop_type VARCHAR(100),
    season VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE satellite_imagery (
    id SERIAL PRIMARY KEY,
    crop_id INTEGER REFERENCES crops(id),
    blob_uri VARCHAR(512),  -- Azure Blob Storage path
    captured_date DATE,
    resolution_meters FLOAT,
    cloud_coverage_percent FLOAT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE analysis_results (
    id SERIAL PRIMARY KEY,
    imagery_id INTEGER REFERENCES satellite_imagery(id),
    model_version VARCHAR(50),
    predicted_crop_type VARCHAR(100),
    confidence FLOAT,
    soil_health_score INT,
    irrigation_needed BOOLEAN,
    metadata JSONB,  -- Store additional results
    created_at TIMESTAMP DEFAULT NOW()
);

-- Vector extension (Phase 1.5)
CREATE EXTENSION IF NOT EXISTS vector;

ALTER TABLE analysis_results 
ADD COLUMN image_embedding vector(768);  -- For ML models

CREATE INDEX ON analysis_results USING ivfflat (image_embedding vector_cosine_ops);
```

### Phase 2: Production Hardening (Weeks 3-4)
- Implement connection pooling (PgBouncer)
- Set up replication & backups
- Add indexing strategy
- Performance tuning

### Phase 3: Vector Search Enhancement (Weeks 5-6)
- Deploy Qdrant if needed
- Sync image vectors from PostgreSQL
- Implement similarity search API

---

## Cost Projection (18-month view)

### Scenario A: 24/7 Operation (Always On)
```
PostgreSQL + Azure Blob Storage (Always On - NOT RECOMMENDED)
├── Month 1-3 (MVP Phase):
│   ├── PostgreSQL: $40-50/month
│   ├── Blob Storage (100GB): $2/month
│   └── TOTAL: $42-52/month
│
└── Long-term: $50-100/month (depending on scale)
```

### Scenario B: Business Hours Operation (Recommended)
```
PostgreSQL + Azure Blob Storage (Business Hours Only - 8 AM - 6 PM)
├── Month 1-3 (MVP Phase):
│   ├── PostgreSQL (managed, on-demand): $20-25/month ⭐ 50% savings
│   ├── Blob Storage (100GB, always): $2/month
│   ├── Azure Automation (scheduling): $1/month
│   └── TOTAL: $23-28/month ⭐ 45-50% cost reduction
│
├── Month 4-12 (Growth Phase):
│   ├── PostgreSQL (M20s tier, 12hr/day): $20-25/month
│   ├── Blob Storage (500GB): $9/month
│   ├── Read Replicas (optional, on-demand): $15-20/month
│   ├── Azure Automation: $1/month
│   └── TOTAL: $45-55/month ⭐ 45-50% cost reduction
│
└── Month 13-18 (Scale Phase):
    ├── PostgreSQL: $25-30/month (12hr/day)
    ├── Blob Storage (2TB): $36/month
    ├── Read Replicas: $20-25/month (on-demand)
    ├── Qdrant Vector DB: $15/month (on-demand)
    ├── Azure Automation: $1/month
    └── TOTAL: $97-107/month ⭐ 45-50% cost reduction vs 24/7
```

### Scenario C: Extended Hours Operation (7 AM - 8 PM, 13 hrs)
```
PostgreSQL + Azure Blob Storage (Extended Hours)
├── Monthly Cost: ~$55-65/month ⭐ 40% cost reduction
└── Better for growing user base with overlap business hours
```

### Cost Comparison Chart (Monthly)

```
24/7 Operation:       |████████████ $100/month
Business Hrs (12h):   |██████ $50/month         ⭐ 50% SAVINGS
Extended Hours (13h): |███████ $60/month        ⭐ 40% SAVINGS
```

### Annual Savings with On-Demand Operation

```
12 Months × $25/month (business hours)    = $300/month ⭐
vs.
12 Months × $50/month (24/7)              = $600/month

ANNUAL SAVINGS: $300/year (50% reduction)
18 MONTHS SAVINGS: $450/year
```

**Key Advantage:** No forced 24/7 operation = predictable, minimal costs + meets business needs


---

## Risk Assessment & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| **Database outage** | Medium | High | Daily automated backups, geo-redundancy |
| **Storage runaway costs** | Low | Medium | Blob lifecycle policies, archive after 2 years |
| **Vector search needed late** | Medium | Low | pgvector ready for Phase 2, easy migration to Qdrant |
| **Vendor lock-in** | Low | Low | PostgreSQL + Blob are industry standard, portable |
| **Performance at 10x scale** | Medium | Medium | Read replicas planned, monitoring in place |

---

## Decision Summary Table

| Aspect | PostgreSQL + Blob | Why This Choice |
|--------|-------------------|-----------------|
| **Cost** | $37-206/month | Scales with usage, no surprises |
| **Performance** | <50ms queries | Proven at billions of records |
| **License** | 100% free/open | No licensing costs ever |
| **Data Types** | Text + Images + Videos | All native support |
| **Operational** | Low overhead | Managed service available |
| **Future-proof** | Vector-ready | pgvector + Qdrant pathway |
| **Community** | 500K+ developers | Extensive docs & support |

---

## Next Steps (Decision Points)

**Decision Required:**
1. ✅ **Confirm PostgreSQL + Azure Blob Storage** as primary choice?
2. **Choose deployment option:**
   - Option A: Azure Database for PostgreSQL (managed, easier)
   - Option B: Self-hosted PostgreSQL (more control, slightly cheaper)
3. **Timeline:** Start with Phase 1 MVP this week?
4. **Backup strategy:** 3x daily automated backups + weekly geo-backup?

**Questions for Discussion:**
- Do you anticipate heavy vector search needs in Phase 1, or can we defer to Phase 2?
- Should we set up read replicas immediately (safer) or optimize for cost initially?
- Any compliance/regulatory requirements for data residency?

---

## Appendix: Technology Landscape

### PostgreSQL Ecosystem
- **pgvector** - Vector similarity search
- **PostGIS** - Geospatial queries (useful for satellite imagery)
- **pg_trgm** - Text search optimization
- **jsonb** - JSON data with indexing
- **TimescaleDB** - Time-series extension (for temporal crop data)

### Azure Integration
- **Azure Database for PostgreSQL** - Managed service
- **Azure Blob Storage** - Object storage
- **Azure Backup** - Automated backup service
- **Application Insights** - Monitoring integration

---

**Document Version:** 1.0  
**Last Updated:** December 5, 2025  
**Status:** Ready for Team Review & Decision
