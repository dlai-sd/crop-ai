# Blob Storage & Lifecycle Management Strategy

**Status:** 🔴 PRIORITY 2 - Before MVP Launch  
**Decision Date:** December 5, 2025  
**Last Updated:** December 5, 2025

---

## Executive Summary

Crop AI handles satellite imagery and analysis results (5-50MB per image). We need **cost-effective blob storage with automatic tiering** to reduce costs while maintaining fast access to recent data.

### Decision Summary

| Technology | Cost (100GB) | Setup | Tiering | Multi-Cloud |
|------------|-------------|-------|---------|-------------|
| Azure Blob (RECOMMENDED) | $2-5/mo | 15 min | ✅ Auto | ✅ Yes |
| AWS S3 | $2.30/mo | 15 min | ⚠️ Manual | ✅ Native |
| Google Cloud Storage | $1.95/mo | 15 min | ✅ Auto | ✅ Native |
| MinIO (Self-hosted) | $100+/mo | 2 hours | ✅ Manual | ✅ Yes |

### Recommendation

**Use Azure Blob Storage with Lifecycle Management**
- Automatic tiering (Hot → Cool → Archive)
- $2-5/month for MVP (100GB)
- Built-in redundancy & disaster recovery
- Integrates seamlessly with existing Azure infrastructure
- Optional AWS S3 backup for multi-cloud DR

---

## Problem Statement

Crop AI generates satellite imagery and analysis outputs:
- **Input:** Satellite images (5-50MB each)
- **Output:** Analysis results (1-10MB each)
- **Usage Pattern:** 80% of access is in first 7 days, 15% in 8-30 days, 5% after 30 days
- **Retention:** Keep all data for compliance (1+ year)
- **Cost:** Storage gets expensive quickly without optimization

### Storage Cost Without Optimization
```
Scenario: 100 crops analyzed/month, 10 images each
├─ 1000 images/month × 25MB = 25GB/month
├─ 12 months = 300GB total
├─ Azure Hot tier: 300GB × $0.021/GB = $6.30/month (ongoing)
├─ 1 year retention = $6.30 × 12 = $75.60/year
└─ 3 year retention = $6.30 × 36 = $226.80/year

BUT: Most old images are rarely accessed!
```

### Storage Cost WITH Lifecycle Tiering (RECOMMENDED)
```
Lifecycle Strategy: Hot (7 days) → Cool (30 days) → Archive (365+ days)

Scenario: 100 crops analyzed/month, 10 images each

Month 1 (Recent data):
├─ 25GB in Hot tier (0-7 days old)
└─ Cost: 25GB × $0.021/GB = $0.525

Month 2:
├─ 25GB new data in Hot tier (0-7 days)
├─ 25GB previous data in Cool tier (7-30 days old)
└─ Cost: (25 × $0.021) + (25 × $0.0125) = $0.525 + $0.3125 = $0.8375

Month 3 (Steady state):
├─ 25GB in Hot tier (current month)
├─ 25GB in Cool tier (previous month)
├─ 50GB in Archive tier (2+ months old)
└─ Cost: (25 × $0.021) + (25 × $0.0125) + (50 × $0.004) = $0.525 + $0.3125 + $0.20 = $1.0375

Year 1 (12 months, 300GB total):
├─ Active tier (Hot): ~25GB
├─ Warm tier (Cool): ~25GB  
├─ Cold tier (Archive): ~250GB
└─ Monthly cost (steady state): $1.04
└─ Annual cost: $1.04 × 12 = $12.48

SAVINGS: $75.60 (no tiering) → $12.48 (with tiering) = 83.5% SAVINGS! 💰
```

---

## Option Analysis

### Option 1: Azure Blob Storage (RECOMMENDED)

**How it works:**
```
1. Create storage account in Azure
2. Create blob container
3. Setup lifecycle management policy
4. Upload objects to blob
5. Lifecycle policy automatically moves objects
6. Retrieve objects based on access pattern
```

**Pros:**
- ✅ Fully managed (no servers to maintain)
- ✅ Automatic lifecycle tiering
- ✅ 3 tiers: Hot ($0.021/GB), Cool ($0.0125/GB), Archive ($0.004/GB)
- ✅ Built-in redundancy (LRS, GRS, RA-GRS)
- ✅ 99.9% uptime SLA
- ✅ 11 nines durability (99.999999999%)
- ✅ Integrates with existing Azure infrastructure
- ✅ Can replicate to AWS S3 for DR
- ✅ Blob versioning & soft delete
- ✅ Access logs & monitoring built-in
- ✅ No setup complexity

**Cons:**
- ❌ Azure lock-in (though replication to S3 mitigates)
- ❌ Egress costs (first 5GB free, then $0.087/GB)
- ❌ Cold storage (Archive) has retrieval latency (1-15 hours)

**Cost Analysis (MVP):**

| Tier | GB/Month | Price/GB | Monthly Cost |
|------|----------|----------|--------------|
| Hot | 25 | $0.021 | $0.525 |
| Cool | 25 | $0.0125 | $0.3125 |
| Archive | 50 | $0.004 | $0.20 |
| **Total** | **100** | **Average $0.0107** | **$1.04** |

**Growth Phase (1TB total):**
```
Hot: 50GB × $0.021 = $1.05
Cool: 200GB × $0.0125 = $2.50
Archive: 750GB × $0.004 = $3.00
─────────────────────────
Total: $6.55/month ($78.60/year)
```

**Enterprise Phase (10TB total):**
```
Hot: 100GB × $0.021 = $2.10
Cool: 500GB × $0.0125 = $6.25
Archive: 9400GB × $0.004 = $37.60
─────────────────────────
Total: $45.95/month ($551.40/year)
```

**Implementation (15 minutes):**

```bash
# 1. Create storage account
az storage account create \
  --name cropaistorage \
  --resource-group crop-ai-rg \
  --location eastus \
  --sku Standard_LRS

# 2. Create blob container
az storage container create \
  --account-name cropaistorage \
  --name satellite-imagery \
  --public-access off

# 3. Get storage account key
az storage account keys list \
  --account-name cropaistorage \
  --resource-group crop-ai-rg \
  --query '[0].value' -o tsv
```

**Lifecycle Management Policy (JSON):**

```json
{
  "rules": [
    {
      "name": "cool-after-7-days",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 7
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": []
        }
      },
      "enabled": true
    },
    {
      "name": "archive-after-30-days",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 30
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": []
        }
      },
      "enabled": true
    },
    {
      "name": "delete-after-365-days",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": []
        }
      },
      "enabled": false  # Disabled for now; enable after 1 year retention decision
    }
  ]
}
```

**Implementation via Azure Portal:**
```
1. Go to Storage Account → Lifecycle Management
2. Click "Add Rule"
3. Rule 1: Move to Cool after 7 days
4. Rule 2: Move to Archive after 30 days
5. Save & apply
```

**Python SDK Integration:**

```python
# requirements.txt
azure-storage-blob==12.14.0

# storage/service.py
from azure.storage.blob import BlobServiceClient, BlobSasPermissions, generate_blob_sas
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class BlobStorageService:
    def __init__(self, connection_string: str, container_name: str = "satellite-imagery"):
        self.blob_service_client = BlobServiceClient.from_connection_string(connection_string)
        self.container_client = self.blob_service_client.get_container_client(container_name)
        self.container_name = container_name
    
    def upload_image(self, crop_id: int, file_path: str, file_name: str) -> str:
        """Upload satellite image to blob storage"""
        try:
            # Create blob name with path: crops/{crop_id}/satellite_images/{file_name}
            blob_name = f"crops/{crop_id}/satellite_images/{file_name}"
            
            # Upload file
            with open(file_path, "rb") as data:
                blob_client = self.container_client.get_blob_client(blob_name)
                blob_client.upload_blob(data, overwrite=True)
            
            logger.info(f"Uploaded {blob_name} ({file_path})")
            return blob_name
        
        except Exception as e:
            logger.error(f"Error uploading {file_path}: {str(e)}")
            raise
    
    def upload_analysis_result(self, crop_id: int, analysis_id: int, result_json: str) -> str:
        """Upload analysis result to blob storage"""
        try:
            blob_name = f"crops/{crop_id}/analyses/{analysis_id}/result.json"
            
            blob_client = self.container_client.get_blob_client(blob_name)
            blob_client.upload_blob(result_json, overwrite=True)
            
            logger.info(f"Uploaded analysis result {blob_name}")
            return blob_name
        
        except Exception as e:
            logger.error(f"Error uploading analysis result: {str(e)}")
            raise
    
    def download_image(self, blob_name: str) -> bytes:
        """Download satellite image"""
        try:
            blob_client = self.container_client.get_blob_client(blob_name)
            download_stream = blob_client.download_blob()
            return download_stream.readall()
        
        except Exception as e:
            logger.error(f"Error downloading {blob_name}: {str(e)}")
            raise
    
    def get_download_url(self, blob_name: str, expiry_hours: int = 24) -> str:
        """Generate time-limited download URL for sharing"""
        try:
            sas_token = generate_blob_sas(
                account_name=self.blob_service_client.account_name,
                container_name=self.container_name,
                blob_name=blob_name,
                account_key=self.blob_service_client.credential.account_key,
                permission=BlobSasPermissions(read=True),
                expiry=datetime.utcnow() + timedelta(hours=expiry_hours)
            )
            
            url = f"https://{self.blob_service_client.account_name}.blob.core.windows.net/{self.container_name}/{blob_name}?{sas_token}"
            return url
        
        except Exception as e:
            logger.error(f"Error generating SAS URL: {str(e)}")
            raise
    
    def delete_blob(self, blob_name: str) -> bool:
        """Delete blob (before lifecycle cleanup)"""
        try:
            blob_client = self.container_client.get_blob_client(blob_name)
            blob_client.delete_blob()
            logger.info(f"Deleted {blob_name}")
            return True
        
        except Exception as e:
            logger.error(f"Error deleting {blob_name}: {str(e)}")
            raise
    
    def list_blobs(self, prefix: str = "") -> list:
        """List all blobs, optionally filtered by prefix"""
        try:
            blobs = []
            for blob in self.container_client.list_blobs(name_starts_with=prefix):
                blobs.append({
                    "name": blob.name,
                    "size": blob.size,
                    "last_modified": blob.last_modified,
                    "tier": getattr(blob, "access_tier", "Hot")
                })
            return blobs
        
        except Exception as e:
            logger.error(f"Error listing blobs: {str(e)}")
            raise
    
    def get_blob_properties(self, blob_name: str) -> dict:
        """Get blob metadata"""
        try:
            blob_client = self.container_client.get_blob_client(blob_name)
            properties = blob_client.get_blob_properties()
            
            return {
                "name": blob_name,
                "size": properties.size,
                "last_modified": properties.last_modified,
                "tier": properties.access_tier,
                "content_type": properties.content_settings.content_type,
                "creation_time": properties.creation_time
            }
        
        except Exception as e:
            logger.error(f"Error getting blob properties: {str(e)}")
            raise

# crops/routes.py
from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from ..storage.service import BlobStorageService
from ..auth.dependencies import get_current_user
from ..database import get_db
import os

router = APIRouter(prefix="/crops", tags=["crops"])

# Initialize blob storage service
blob_service = BlobStorageService(
    connection_string=os.getenv("AZURE_STORAGE_CONNECTION_STRING")
)

@router.post("/{crop_id}/upload-image")
async def upload_crop_image(
    crop_id: int,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    """Upload satellite image for crop"""
    try:
        # Validate file type
        if file.content_type not in ["image/tiff", "image/jpeg", "image/png"]:
            raise HTTPException(status_code=400, detail="Invalid image format")
        
        # Validate file size (max 100MB)
        file_content = await file.read()
        if len(file_content) > 100 * 1024 * 1024:
            raise HTTPException(status_code=413, detail="File too large (max 100MB)")
        
        # Save temporarily
        temp_path = f"/tmp/{file.filename}"
        with open(temp_path, "wb") as f:
            f.write(file_content)
        
        # Upload to blob storage
        blob_name = blob_service.upload_image(crop_id, temp_path, file.filename)
        
        # Clean up temp file
        os.remove(temp_path)
        
        return {
            "blob_name": blob_name,
            "size": len(file_content),
            "message": "Image uploaded successfully"
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{crop_id}/images")
async def list_crop_images(
    crop_id: int,
    current_user: dict = Depends(get_current_user)
):
    """List all images for a crop"""
    try:
        prefix = f"crops/{crop_id}/satellite_images/"
        blobs = blob_service.list_blobs(prefix)
        return {"images": blobs}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/{crop_id}/images/{image_name}/download-url")
async def get_image_download_url(
    crop_id: int,
    image_name: str,
    current_user: dict = Depends(get_current_user)
):
    """Generate download URL for image (expires in 24 hours)"""
    try:
        blob_name = f"crops/{crop_id}/satellite_images/{image_name}"
        url = blob_service.get_download_url(blob_name, expiry_hours=24)
        return {"download_url": url}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

**Monitoring:**

```python
# monitoring/blob_storage_monitor.py
from azure.storage.blob import BlobServiceClient
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class BlobStorageMonitor:
    def __init__(self, connection_string: str):
        self.blob_service_client = BlobServiceClient.from_connection_string(connection_string)
    
    def get_storage_stats(self, container_name: str) -> dict:
        """Get storage statistics by tier"""
        container_client = self.blob_service_client.get_container_client(container_name)
        
        stats = {
            "hot": {"count": 0, "size": 0},
            "cool": {"count": 0, "size": 0},
            "archive": {"count": 0, "size": 0}
        }
        
        for blob in container_client.list_blobs():
            tier = blob.access_tier.lower() if blob.access_tier else "hot"
            stats[tier]["count"] += 1
            stats[tier]["size"] += blob.size
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "stats": stats,
            "total_blobs": sum(s["count"] for s in stats.values()),
            "total_size_gb": sum(s["size"] for s in stats.values()) / (1024**3)
        }
    
    def estimate_monthly_cost(self, stats: dict) -> float:
        """Estimate monthly cost based on current storage"""
        hot_cost = (stats["stats"]["hot"]["size"] / (1024**3)) * 0.021
        cool_cost = (stats["stats"]["cool"]["size"] / (1024**3)) * 0.0125
        archive_cost = (stats["stats"]["archive"]["size"] / (1024**3)) * 0.004
        
        return hot_cost + cool_cost + archive_cost
    
    def log_stats(self, container_name: str):
        """Log storage statistics"""
        stats = self.get_storage_stats(container_name)
        cost = self.estimate_monthly_cost(stats)
        
        logger.info(f"Blob Storage Stats: {stats['total_blobs']} blobs, {stats['total_size_gb']:.2f} GB")
        logger.info(f"Estimated Monthly Cost: ${cost:.2f}")
        logger.info(f"Tier Breakdown: Hot={stats['stats']['hot']['size']/(1024**3):.2f}GB, "
                   f"Cool={stats['stats']['cool']['size']/(1024**3):.2f}GB, "
                   f"Archive={stats['stats']['archive']['size']/(1024**3):.2f}GB")
```

---

### Option 2: AWS S3 with Intelligent-Tiering

**How it works:**
```
1. Upload objects to S3
2. Enable S3 Intelligent-Tiering
3. AWS automatically moves objects between tiers based on access
4. No manual intervention needed
```

**Pros:**
- ✅ Intelligent automatic tiering (based on actual access patterns)
- ✅ More cost-effective than lifecycle (no guessing on tier transitions)
- ✅ Integrates well with AWS ecosystem
- ✅ Can replicate to Azure for multi-cloud
- ✅ 11 nines durability

**Cons:**
- ❌ More expensive than lifecycle ($0.0125/1000 requests for intelligent-tiering)
- ❌ Latency tiers (Frequent, Infrequent, Archive Access, Deep Archive)
- ❌ Complex pricing model
- ❌ AWS lock-in

**Cost (MVP):**
```
100GB storage with Intelligent-Tiering:
├─ Storage: 100GB × $0.023 (avg) = $2.30
├─ Intelligent-Tiering: 100GB × $0.0125/1000 objects ≈ $0.10
└─ Total: ~$2.40/month

Growth (1TB):
├─ Storage: 1TB × $0.023 = $23
├─ Intelligent-Tiering: 1000GB × $0.0125/1000 objects ≈ $1
└─ Total: ~$24/month
```

**When to use:**
- Already using AWS
- Access patterns unpredictable
- Need fine-grained control per object

---

### Option 3: Google Cloud Storage with Nearline

**Pros:**
- ✅ Cost-effective ($0.01/GB/month for older data)
- ✅ Automatic class transitions
- ✅ Works well with Google AI/ML services
- ✅ 11 nines durability

**Cons:**
- ❌ Retrieval costs for coldline ($0.01/GB)
- ❌ 30-day minimum storage
- ❌ Google ecosystem lock-in

**Cost (MVP):**
```
100GB over 3 months (lifecycle: Standard → Nearline → Coldline)
├─ Month 1 (Standard): 100GB × $0.020 = $2.00
├─ Month 2 (Nearline): 100GB × $0.010 = $1.00
├─ Month 3+ (Coldline): 100GB × $0.004 = $0.40
└─ Average: ~$1.13/month
```

**When to use:**
- Using Google Cloud AI services
- Data access patterns follow standard lifecycle
- Already in Google ecosystem

---

### Option 4: MinIO (Self-Hosted)

**How it works:**
```
1. Deploy MinIO on VMs
2. Configure replication & backup
3. Manage all tiering/lifecycle yourself
```

**Pros:**
- ✅ Full control
- ✅ No vendor lock-in
- ✅ Works anywhere (on-premises, hybrid cloud)

**Cons:**
- ❌ Requires server management (VMs, networking, backups)
- ❌ $100-200/month infrastructure cost
- ❌ Operational overhead (backups, replication, upgrades)
- ❌ Not cost-effective for MVP

**Cost (MVP):**
```
MinIO cluster (3 nodes for HA):
├─ 3x Standard_D2s_v3 VMs: 3 × $60 = $180/month
├─ Storage (managed disks): $50/month
├─ Networking: $10/month
├─ Backup storage: $10/month
└─ Total: $250/month

Plus operational overhead (maintenance, monitoring, etc.)
```

**When to use:**
- On-premises deployment required
- Strict data residency requirements
- Multi-petabyte scale (where license costs amortize)

---

## Recommended Architecture

### MVP Phase: Azure Blob with Lifecycle

```
Architecture:
┌─────────────────────────────────┐
│   FastAPI Application           │
│  (Upload/Download Images)       │
└──────────┬──────────────────────┘
           │
           ▼
┌─────────────────────────────────┐
│  Azure Blob Storage             │
│  (Automatic Lifecycle)          │
│                                 │
│ Hot Tier (0-7 days)   → 25GB    │
│ Cool Tier (7-30 days) → 25GB    │
│ Archive (30+ days)    → 250GB   │
└────────────┬────────────────────┘
             │
             ├─→ 99.9% SLA
             ├─→ 11 nines durability
             ├─→ Automatic redundancy
             └─→ $1-5/month for MVP
```

### Growth Phase: Multi-Cloud

```
Architecture:
┌──────────────────────────────────────┐
│   FastAPI Application                │
└──┬─────────────────────────┬──────────┘
   │                         │
   ▼                         ▼
┌──────────────────┐  ┌──────────────────┐
│ Azure Blob       │  │ AWS S3 (Backup)  │
│ (Primary)        │  │ (DR Replica)     │
│ Hot→Cool→Archive │  │ Lifecycle sync   │
└──────────────────┘  └──────────────────┘
   
   Async replication every 1 hour
   ↓
   Regional redundancy (within Azure)
   ↓
   Cross-cloud redundancy (AWS backup)
```

### Enterprise Phase: Multi-Region

```
Architecture:
┌──────────────────────────────────────────────────────┐
│   Global API Load Balancer (Azure Front Door)         │
└──────────────┬──────────────────────┬─────────────────┘
               │                      │
        ┌──────▼────────┐      ┌──────▼────────┐
        │ US East       │      │ EU West       │
        │ Azure Blob    │      │ Azure Blob    │
        │ (Primary)     │      │ (Replica)     │
        └───────────────┘      └───────────────┘
               │                      │
               └──────────────────────┘
                      │
                  Async replication (RTC = 1 hour)
```

---

## Implementation Plan

### Phase 1: Setup Azure Blob (Day 1)

**Effort:** 1 hour

```bash
# 1. Create storage account
az storage account create \
  --name cropaistorage \
  --resource-group crop-ai-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --access-tier Hot

# 2. Create containers
az storage container create \
  --account-name cropaistorage \
  --name satellite-imagery

az storage container create \
  --account-name cropaistorage \
  --name analysis-results

# 3. Get connection string
az storage account show-connection-string \
  --name cropaistorage \
  --resource-group crop-ai-rg \
  --query connectionString -o tsv
```

### Phase 2: Setup Lifecycle Policies (Day 1)

**Effort:** 30 minutes

```json
PUT /subscriptions/{subscription-id}/resourceGroups/crop-ai-rg/providers/Microsoft.Storage/storageAccounts/cropaistorage/managementPolicies/default?api-version=2021-02-01

{
  "properties": {
    "policy": {
      "rules": [
        {
          "enabled": true,
          "name": "move-to-cool-7days",
          "type": "Lifecycle",
          "definition": {
            "actions": {
              "baseBlob": {
                "tierToCool": {
                  "daysAfterModificationGreaterThan": 7
                }
              }
            },
            "filters": {
              "blobTypes": ["blockBlob"],
              "prefixMatch": []
            }
          }
        },
        {
          "enabled": true,
          "name": "move-to-archive-30days",
          "type": "Lifecycle",
          "definition": {
            "actions": {
              "baseBlob": {
                "tierToArchive": {
                  "daysAfterModificationGreaterThan": 30
                }
              }
            },
            "filters": {
              "blobTypes": ["blockBlob"],
              "prefixMatch": []
            }
          }
        }
      ]
    }
  }
}
```

### Phase 3: Integrate with FastAPI (Day 1-2)

**Effort:** 2 hours

- Create `BlobStorageService` class
- Implement upload/download endpoints
- Add SAS URL generation for sharing
- Write integration tests

### Phase 4: Setup Monitoring (Day 2)

**Effort:** 1 hour

- Create storage stats collection
- Log monthly cost estimates
- Setup alerts for unusual spikes

### Phase 5: Optional AWS Replication (Week 2)

**Effort:** 4 hours

- Setup S3 bucket
- Configure async replication
- Test failover scenarios

---

## Storage Patterns

### Satellite Imagery Storage Pattern

```
Container: satellite-imagery/

crops/
├─ {crop_id}/
│  ├─ satellite_images/
│  │  ├─ 2024-12-01_ndvi.tiff
│  │  ├─ 2024-12-15_ndvi.tiff
│  │  └─ 2024-12-25_ndvi.tiff
│  └─ analyses/
│     ├─ {analysis_id}/
│     │  ├─ result.json
│     │  ├─ thermal_map.png
│     │  └─ yield_forecast.json
│     └─ {analysis_id}/
│        └─ ...

metadata/
├─ crops/
│  ├─ {crop_id}.json          # Crop metadata
│  └─ {crop_id}_images.json   # Image manifest
└─ analyses/
   ├─ {analysis_id}.json      # Analysis metadata
   └─ {analysis_id}_images.json # Generated images
```

### Database Schema for Blob References

```sql
-- References to blob storage
CREATE TABLE blob_references (
  id SERIAL PRIMARY KEY,
  blob_name VARCHAR(255) NOT NULL,
  blob_type VARCHAR(50),  -- 'satellite_image', 'analysis_result', etc
  blob_size BIGINT,  -- Size in bytes
  content_type VARCHAR(100),
  tier VARCHAR(20),  -- Hot, Cool, Archive
  crop_id INTEGER REFERENCES crops(id),
  analysis_id INTEGER REFERENCES analyses(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  last_accessed TIMESTAMP,
  INDEX (crop_id, blob_type),
  INDEX (analysis_id)
);

-- Track storage costs
CREATE TABLE storage_costs (
  id SERIAL PRIMARY KEY,
  month DATE,
  tier VARCHAR(20),
  size_gb DECIMAL(10, 2),
  cost_usd DECIMAL(10, 4),
  created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Cost Monitoring

### Monthly Cost Tracking

```python
# monitoring/cost_tracker.py
from azure.storage.blob import BlobServiceClient
from datetime import datetime, timedelta
from sqlalchemy import Session
from app.models import StorageCost

class CostTracker:
    def __init__(self, connection_string: str):
        self.client = BlobServiceClient.from_connection_string(connection_string)
    
    TIER_PRICES = {
        "Hot": 0.021,      # per GB/month
        "Cool": 0.0125,
        "Archive": 0.004
    }
    
    def calculate_monthly_cost(self, container_name: str, db: Session):
        """Calculate and store monthly storage cost"""
        container = self.client.get_container_client(container_name)
        
        costs = {}
        for tier in self.TIER_PRICES:
            costs[tier] = {"size_gb": 0, "cost": 0}
        
        # Calculate size by tier
        for blob in container.list_blobs():
            tier = blob.access_tier or "Hot"
            size_gb = blob.size / (1024**3)
            
            if tier not in costs:
                costs[tier] = {"size_gb": 0, "cost": 0}
            
            costs[tier]["size_gb"] += size_gb
            costs[tier]["cost"] += size_gb * self.TIER_PRICES.get(tier, 0)
        
        # Store in database
        today = datetime.now().date()
        for tier, data in costs.items():
            cost_record = StorageCost(
                month=today,
                tier=tier,
                size_gb=data["size_gb"],
                cost_usd=data["cost"]
            )
            db.add(cost_record)
        
        db.commit()
        
        total_cost = sum(data["cost"] for data in costs.values())
        return {
            "month": today,
            "total_cost": total_cost,
            "by_tier": costs
        }
```

### Alerts

```python
# monitoring/alerts.py
class StorageAlerts:
    @staticmethod
    async def check_monthly_cost(db: Session, threshold: float = 10):
        """Alert if monthly cost exceeds threshold"""
        today = datetime.now().date()
        month_start = today.replace(day=1)
        
        costs = db.query(StorageCost).filter(
            StorageCost.month >= month_start
        ).all()
        
        total_cost = sum(c.cost_usd for c in costs)
        
        if total_cost > threshold:
            # Send alert
            logger.warning(f"Storage cost exceeded threshold: ${total_cost:.2f} > ${threshold}")
            # Integration with alerting service (Slack, PagerDuty, etc)
    
    @staticmethod
    async def check_tier_distribution(container_name: str, expected_archive_pct: float = 0.6):
        """Alert if archive tier is lower than expected (indicates lifecycle issue)"""
        stats = get_storage_stats(container_name)
        total_size = sum(s["size"] for s in stats["stats"].values())
        archive_size = stats["stats"]["archive"]["size"]
        archive_pct = archive_size / total_size if total_size > 0 else 0
        
        if archive_pct < expected_archive_pct:
            logger.warning(f"Archive tier lower than expected: {archive_pct*100:.1f}% < {expected_archive_pct*100:.1f}%")
```

---

## Disaster Recovery Strategy

### Backup Strategy

```
Primary: Azure Blob (Hot/Cool/Archive lifecycle)
├─ Regional redundancy: LRS (Local Redundant Storage) within single region
└─ RTC = 0 (synchronous within region)

Secondary: AWS S3 (Backup replica)
├─ Replicated asynchronously (every 1 hour)
├─ Regional redundancy: Multi-AZ
└─ RTC = 1 hour, RPO = 1 hour

Recovery:
├─ Regional outage: Switch to AWS S3 (1 hour RTO)
├─ Data corruption: Restore from daily snapshots
└─ Accidental deletion: 7-day soft delete window
```

### Soft Delete & Versioning

```python
# Enable soft delete for 7 days
az storage blob service-properties delete-policy update \
  --account-name cropaistorage \
  --days-retained 7 \
  --enable true

# Enable versioning
az storage blob service-properties update \
  --account-name cropaistorage \
  --enable-change-feed true \
  --enable-versioning true
```

---

## Implementation Checklist

### Phase 1: Setup Azure Blob (Day 1)
- [ ] Create storage account
- [ ] Create containers (satellite-imagery, analysis-results)
- [ ] Get connection string
- [ ] Setup lifecycle management policies
- [ ] Enable soft delete (7 days)
- [ ] Enable blob versioning
- [ ] Configure CORS for Angular frontend
- [ ] Test upload/download manually

### Phase 2: Integrate with FastAPI (Day 1-2)
- [ ] Install azure-storage-blob package
- [ ] Create BlobStorageService class
- [ ] Implement upload endpoint
- [ ] Implement download endpoint
- [ ] Implement list endpoint
- [ ] Implement SAS URL generation
- [ ] Add error handling
- [ ] Write integration tests (8+ tests)
- [ ] Test with real satellite imagery

### Phase 3: Setup Monitoring (Day 2)
- [ ] Create cost monitoring job
- [ ] Log storage statistics daily
- [ ] Setup alerts for cost threshold
- [ ] Dashboard with storage usage
- [ ] Monthly cost report

### Phase 4: Optional AWS Replication (Week 2)
- [ ] Create S3 bucket
- [ ] Configure async replication
- [ ] Write failover procedure
- [ ] Test disaster recovery
- [ ] Document recovery steps

---

## Known Issues & Workarounds

### Issue 1: Archive Tier Retrieval Latency
**Problem:** Archive tier has 1-15 hours retrieval latency  
**Solution:** Don't move frequently-accessed data to archive; adjust lifecycle policy

```json
{
  "name": "archive-after-90-days",
  "definition": {
    "actions": {
      "baseBlob": {
        "tierToArchive": {
          "daysAfterModificationGreaterThan": 90
        }
      }
    }
  }
}
```

### Issue 2: Cool Tier Minimum 30-Day Storage
**Problem:** Minimum 30-day charge even if deleted earlier  
**Solution:** Keep frequently accessed data in Hot tier; use Cool tier for 30+ day minimum

### Issue 3: Rehydration Costs
**Problem:** Rehydrating from Archive to Hot is expensive ($0.001/GB)  
**Solution:** Plan retrieval strategy; use API to rehydrate to Cool first (cheaper)

```python
# Rehydrate to Cool tier (cheaper than Hot)
blob_client.set_blob_tier("Cool")
```

---

## Summary

| Aspect | Details |
|--------|---------|
| **Recommended Technology** | Azure Blob Storage with Lifecycle |
| **Setup Time** | 2 hours |
| **MVP Cost** | $1-5/month (100GB) |
| **Growth Cost** | $6.55/month (1TB) |
| **Enterprise Cost** | $45.95/month (10TB) |
| **Tiering Strategy** | Hot (7d) → Cool (30d) → Archive (365d) |
| **Cost Savings** | 83.5% with lifecycle vs no tiering |
| **Disaster Recovery** | 7-day soft delete + optional AWS backup |
| **Deployment** | Week 2 of MVP |

---

**Next:** Proceed to Logging & Observability (Priority 3).
