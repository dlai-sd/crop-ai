# Queue Infrastructure for AI Model Serving

**Date:** December 5, 2025  
**Status:** Design & Architecture Discussion  
**Focus:** Async Job Queue for ML Model Inference  
**Impact:** Critical component for scalability & performance

---

## Executive Summary

**Crop AI needs a Queue Infrastructure because:**

1. **Long-running AI inference** (model processing takes 5-30 seconds)
2. **Satellite image analysis** is computationally expensive
3. **Async model serving** keeps API responsive (don't block user requests)
4. **Batch processing** multiple satellite images efficiently
5. **Distributed processing** across multiple workers
6. **Result fetching** with polling/webhooks

**Recommended Architecture: Redis Queue (RQ) + Celery alternative**

```
User Request
     │
     ▼
  FastAPI
     │
  ┌──┴──────────────────┐
  │ Enqueue Job         │
  │ (return job_id)     │
  ▼                     ▼
Return 202            Redis Queue
(Accepted)                 │
  │                   ┌─────┴──────┬──────────┐
  │                   │            │          │
  │                   ▼            ▼          ▼
  │                Worker1      Worker2   Worker3
  │                 (GPU)        (GPU)     (GPU)
  │                   │            │          │
  │                   └─────┬──────┴──────────┘
  │                         │
  │                    Model Results
  │                    (stored in DB)
  │                         │
  └────────────────────────►│
                            ▼
                     Poll /api/results/{job_id}
                            │
                            ▼
                      Return Results
                      (200 OK or 202 Processing)
```

---

## Part 1: Understanding the AI Model Serving Challenge

### Why Queue Infrastructure?

```
PROBLEM: Synchronous AI Model Serving
═══════════════════════════════════════

User Request
    │
    ├─► Satellite Image (5-50MB)
    ├─► Process through AI Model
    │   ├─ Load model (2-3 sec)
    │   ├─ Preprocess image (1-2 sec)
    │   ├─ Run inference (5-15 sec)  ← BOTTLENECK
    │   └─ Postprocess (1-2 sec)
    │   TOTAL: 10-25 seconds ❌
    │
    └─► Return Results
        HTTP Timeout (60 sec limit)
        User sees spinner for 25 seconds ❌


SOLUTION: Async Job Queue
═════════════════════════════════════════

User Request
    │
    └─► Enqueue Job (100ms)
        │
        ├─► Return 202 Accepted ✅ (fast!)
        │   {"job_id": "abc123"}
        │
        └─► User Polls for Results
            /api/results/abc123
            
Meanwhile:
    Queue
    │
    ├─► Worker 1 processes job (GPU intensive)
    ├─► Worker 2 processes next job
    ├─► Worker 3 processes next job
    │
    └─► Results stored in Redis/PostgreSQL
    
User can check status anytime:
    - Still processing (202)
    - Complete with results (200)
    - Failed with error (400)
```

### Typical AI Model Inference Timeline

```
Crop Identification Model Inference:

Input: Satellite Image (512x512 px, 10MB GeoTIFF)
    │
    ▼
Model Load (first request):         2-3 seconds ⏱️
    │
    ▼
Image Preprocessing:
    ├─ Load from blob storage        1 second
    ├─ Normalize bands              0.5 second
    ├─ Resize/crop                  0.5 second
    └─ Convert to model format      0.2 second
    │
    ▼ TOTAL PREPROCESSING: 2.2 seconds

    ▼
Inference (GPU/TPU):
    ├─ Forward pass                 5-10 seconds ← MAIN BOTTLENECK
    └─ Post-processing              1-2 seconds
    │
    ▼ TOTAL INFERENCE: 6-12 seconds

    ▼
Result Post-Processing:
    ├─ Format JSON                  0.2 second
    ├─ Store in PostgreSQL          0.3 second
    ├─ Cache in Redis               0.1 second
    └─ Webhook notification         0.2 second
    │
    ▼ TOTAL POST: 0.8 seconds

═══════════════════════════════════════
TOTAL TIME: 11-17 seconds per image ⏱️

Synchronous: User waits 17 seconds ❌
Async Queue: User waits 0.1 seconds ✅
```

---

## Part 2: Queue Technology Options

### Option 1: Redis Queue (RQ)

```
What it is:
  Simple Python job queue backed by Redis
  ├─ Jobs stored in Redis
  ├─ Workers process jobs
  ├─ Results stored in Redis
  └─ Pure Python, easy integration

Architecture:
  
  FastAPI App          Redis          Workers
  ─────────────        ─────          ───────
  
  enqueue_job()  ────► Queue:jobs  ──► Worker 1 (process)
                         Queue:jobs ──► Worker 2 (process)
                         Queue:jobs ──► Worker 3 (process)
                             ▲
                    Results stored here
                    (Redis cache)
```

#### Pros ✅
- **Simple setup** (no infrastructure)
- **Pure Python** (pip install rq)
- **Redis-based** (we already have Redis for caching)
- **Easy monitoring** (rq-dashboard)
- **Low memory** footprint per worker
- **Excellent for Python** workloads
- **Cost-effective** (no additional services)

#### Cons ❌
- **No built-in persistence** (jobs lost if Redis restarts)
- **Single-node only** (no distributed queue)
- **Scaling limited** to one Redis instance
- **No dead-letter queue** by default
- **Less feature-rich** than Celery/Kafka

#### Cost
```
Using existing Redis instance:
- No additional cost ✅
- Reuse: $8-10/month Redis
```

#### Implementation
```python
from rq import Queue
from redis import Redis
import time

redis_conn = Redis(host='crop-ai-cache.redis.cache.windows.net')
q = Queue(connection=redis_conn)

# Define job function
def process_satellite_image(image_path, crop_id):
    """Run AI model on satellite image"""
    import torch
    model = load_model()
    image = load_image(image_path)
    prediction = model.predict(image)
    save_results(crop_id, prediction)
    return prediction

# Enqueue job from FastAPI
@app.post("/api/crops/{crop_id}/analyze")
async def analyze_crop(crop_id: int, file: UploadFile):
    # Store image in blob storage first
    image_path = await upload_to_blob(file)
    
    # Enqueue job (non-blocking)
    job = q.enqueue(
        process_satellite_image,
        image_path,
        crop_id,
        job_timeout='30m'
    )
    
    return {
        "job_id": job.id,
        "status": "queued",
        "estimated_wait": "15 seconds"
    }

# Poll for results
@app.get("/api/results/{job_id}")
async def get_result(job_id: str):
    job = Job.fetch(job_id, connection=redis_conn)
    
    if job.is_finished:
        return {"status": "complete", "result": job.result}
    elif job.is_failed:
        return {"status": "failed", "error": job.exc_info}
    else:
        return {"status": "processing", "progress": job.meta.get('progress', 0)}
```

---

### Option 2: Celery + RabbitMQ

```
What it is:
  Distributed task queue with message broker (RabbitMQ/Redis)
  ├─ Messages in RabbitMQ
  ├─ Workers process tasks
  ├─ Results in backend (Redis/DB)
  └─ Highly scalable

Architecture:
  
  FastAPI App         RabbitMQ        Workers
  ─────────────       ────────        ───────
  
  send_task()  ─────► Exchange:jobs ─► Worker 1 (GPU)
                         Queue:tasks ─► Worker 2 (GPU)
                                    ─► Worker 3 (GPU)
                                    ─► Worker 4 (CPU)
                                    
                      Separate Broker & Workers
                      (Production-grade)
```

#### Pros ✅
- **Highly scalable** (distributed workers across clouds)
- **Production-proven** (used by Spotify, Instagram)
- **Message persistence** (RabbitMQ guarantee)
- **Advanced features** (routing, priority queues)
- **Multi-language** (C, Java, Node, Python)
- **Dead-letter queue** support
- **Monitoring tools** (Flower dashboard)
- **Retry logic** built-in

#### Cons ❌
- **Higher complexity** (more moving parts)
- **RabbitMQ overhead** (another service)
- **Higher operational burden** (monitor RabbitMQ)
- **More resource-intensive** (RabbitMQ memory)
- **Steeper learning curve**
- **May be overkill** for MVP

#### Cost
```
Additional infrastructure:
- RabbitMQ (Azure Service Bus): $10-15/month
- Monitoring (Flower): Free or $5/month
TOTAL ADDED: $10-20/month
```

#### Implementation
```python
from celery import Celery
from celery.result import AsyncResult

# Initialize Celery with RabbitMQ
app = Celery(
    'crop_ai',
    broker='amqp://user:pass@rabbitmq.azure.com//',
    backend='redis://cache.redis.windows.net:6379'
)

@app.task(bind=True)
def process_satellite_image(self, image_path, crop_id):
    """Celery task for AI inference"""
    try:
        self.update_state(
            state='PROGRESS',
            meta={'current': 0, 'total': 100}
        )
        
        model = load_model()
        image = load_image(image_path)
        prediction = model.predict(image)
        
        self.update_state(meta={'current': 100})
        save_results(crop_id, prediction)
        return prediction
    except Exception as exc:
        self.update_state(state='FAILURE', meta=str(exc))
        raise

# FastAPI endpoint
@app.post("/api/crops/{crop_id}/analyze")
async def analyze_crop(crop_id: int, file: UploadFile):
    image_path = await upload_to_blob(file)
    
    # Enqueue Celery task
    task = process_satellite_image.delay(image_path, crop_id)
    
    return {"job_id": task.id, "status": "queued"}

@app.get("/api/results/{job_id}")
async def get_result(job_id: str):
    result = AsyncResult(job_id)
    
    if result.ready():
        return {"status": "complete", "result": result.get()}
    else:
        return {"status": "processing", "progress": result.info}
```

---

### Option 3: Azure Service Bus Queues

```
What it is:
  Fully managed message queue service (Azure-native)
  ├─ Messages in Azure Service Bus
  ├─ Workers read from queue
  ├─ Results in PostgreSQL/Redis
  └─ Enterprise-grade queue

Architecture:
  
  FastAPI (Azure)   Service Bus      Worker VMs (Azure)
  ──────────────    ───────────      ─────────────────
  
  Send Message ────► Queue:jobs ────► Worker 1 (process)
                       Queue:jobs ────► Worker 2 (process)
                       Queue:jobs ────► Worker 3 (process)
                       
                    Built-in Enterprise Features
                    (DLQ, Batching, Sessions)
```

#### Pros ✅
- **Fully managed** (zero operations)
- **Azure-native** (seamless integration)
- **Enterprise features** (DLQ, partitioning, sessions)
- **Reliability** (99.9% SLA)
- **Pay-per-operation** (cost-effective)
- **Auto-scaling** built-in
- **Security** (managed authentication)

#### Cons ❌
- **Vendor lock-in** (Azure only)
- **Higher complexity** than RQ
- **Pricing unpredictable** (pay per message)
- **Not suitable** for multi-cloud
- **Overkill for MVP**

#### Cost
```
Azure Service Bus (Premium):
- Base: $5/month
- Per-message: $0.05 per million messages
- At 10K jobs/day: $15/month
TOTAL: $20+/month
```

#### Implementation
```python
from azure.servicebus import ServiceBusClient, ServiceBusMessage
import json

# Azure Service Bus setup
connstr = "Endpoint=sb://crop-ai.servicebus.windows.net/;..."
client = ServiceBusClient.from_connection_string(connstr)

@app.post("/api/crops/{crop_id}/analyze")
async def analyze_crop(crop_id: int, file: UploadFile):
    image_path = await upload_to_blob(file)
    
    # Send message to Service Bus
    sender = client.get_queue_sender("crop-analysis-jobs")
    
    job_data = {
        "job_id": str(uuid.uuid4()),
        "image_path": image_path,
        "crop_id": crop_id
    }
    
    message = ServiceBusMessage(json.dumps(job_data))
    sender.send_messages(message)
    
    return {"job_id": job_data["job_id"], "status": "queued"}

# Worker process (runs on VM)
def worker_process_jobs():
    receiver = client.get_queue_receiver("crop-analysis-jobs")
    
    with receiver:
        for msg in receiver:
            job_data = json.loads(str(msg))
            
            # Process AI model
            result = process_satellite_image(
                job_data["image_path"],
                job_data["crop_id"]
            )
            
            # Complete message
            receiver.complete_message(msg)
```

---

### Option 4: Apache Kafka

```
What it is:
  Distributed event streaming platform
  ├─ High throughput (millions of messages/sec)
  ├─ Message persistence (durable log)
  ├─ Consumer groups (distributed processing)
  └─ Enterprise-grade streaming

Architecture:
  
  FastAPI         Kafka Brokers     Consumer Group
  ───────         ─────────────     ──────────────
  
  Send Event ────► Partition 0 ────► Worker 1
                   Partition 1 ────► Worker 2
                   Partition 2 ────► Worker 3
                   
                Massive Scale
                (100K+ msgs/sec)
```

#### Pros ✅
- **Extreme throughput** (millions of events/sec)
- **Durable log** (replay capability)
- **Real-time processing** (Kafka Streams)
- **Event sourcing** pattern
- **Perfect for streaming** satellite data

#### Cons ❌
- **Massive overkill** for MVP
- **Steep learning curve**
- **Complex operations** (cluster management)
- **Higher resource costs** ($50+/month)
- **Not ideal** for simple job queue pattern
- **Better for data streaming** than job queues

#### Cost
```
Confluent Cloud (Managed Kafka):
- Cluster: $50-100/month minimum
- Not cost-effective for MVP
```

#### Verdict for MVP
❌ **Too complex, too expensive for job queue needs**
✅ **Consider for Phase 2** if doing real-time satellite streaming

---

## Part 3: Comparison Matrix

| Factor | RQ | Celery | Azure Service Bus | Kafka |
|--------|-----|--------|------------------|-------|
| **Complexity** | ⭐ Simple | ⭐⭐⭐ Medium | ⭐⭐ Easy (managed) | ⭐⭐⭐⭐⭐ Complex |
| **Scalability** | ⭐⭐ (single Redis) | ⭐⭐⭐⭐ (distributed) | ⭐⭐⭐⭐⭐ (unlimited) | ⭐⭐⭐⭐⭐ (massive) |
| **Cost** | ⭐⭐⭐⭐⭐ ($0 added) | ⭐⭐⭐ ($10-20/mo) | ⭐⭐⭐ ($20+/mo) | ⭐ ($50+/mo) |
| **Operations** | ⭐⭐⭐⭐ (simple) | ⭐⭐⭐ (medium) | ⭐⭐⭐⭐⭐ (managed) | ⭐ (very complex) |
| **Persistence** | ⭐⭐ (Redis-dependent) | ⭐⭐⭐⭐ (RabbitMQ) | ⭐⭐⭐⭐⭐ (guaranteed) | ⭐⭐⭐⭐⭐ (durable log) |
| **Multi-Cloud** | ⭐⭐⭐⭐ (Redis-based) | ⭐⭐⭐⭐ (any broker) | ❌ (Azure only) | ⭐⭐⭐ (with Confluent) |
| **Monitoring** | ⭐⭐⭐ (rq-dashboard) | ⭐⭐⭐⭐ (Flower) | ⭐⭐⭐⭐⭐ (Azure Portal) | ⭐⭐⭐⭐ (Kafka UI) |
| **Production-Ready** | ⭐⭐⭐ (good for medium) | ⭐⭐⭐⭐⭐ (proven) | ⭐⭐⭐⭐⭐ (enterprise) | ⭐⭐⭐⭐⭐ (enterprise) |
| **Learning Curve** | ⭐⭐ (easy) | ⭐⭐⭐ (medium) | ⭐⭐ (easy) | ⭐⭐⭐⭐ (hard) |
| **MVP Suitability** | ⭐⭐⭐⭐⭐ (perfect) | ⭐⭐⭐ (good) | ⭐⭐ (managed but adds cost) | ❌ (overkill) |
| | | | | |
| **OVERALL SCORE** | **4.4/5** 🥇 | **4.2/5** 🥈 | **3.8/5** 🥉 | **2.5/5** ❌ |

---

## Part 4: RECOMMENDED: Redis Queue (RQ) for MVP

### Why RQ for Crop AI?

```
✅ PERFECT FIT BECAUSE:

1. SIMPLICITY
   └─ One Python library (pip install rq)
   └─ No additional infrastructure
   └─ Works with existing Redis cache layer

2. COST
   └─ $0 additional cost (reuse Redis)
   └─ Versus Celery ($10-20/mo for RabbitMQ)
   └─ Versus Kafka ($50+/mo)

3. SCALE SUFFICIENT FOR MVP
   └─ Redis handles 100K ops/sec
   └─ MVP: ~100 jobs/day
   └─ Growth: ~1000 jobs/day
   └─ Still 100x under capacity

4. OPERATOR-FRIENDLY
   └─ No RabbitMQ/Kafka cluster to manage
   └─ Single point of management (Redis)
   └─ Easy monitoring (rq-dashboard)
   └─ Easy debugging (simple model)

5. MULTI-CLOUD READY
   └─ Redis works everywhere (Azure, AWS, GCP)
   └─ No vendor lock-in
   └─ Easy to migrate to Celery later if needed

6. PERFECT FOR GPU WORKLOADS
   └─ Long-running jobs supported
   └─ Job status tracking
   └─ Easy result retrieval
   └─ Worker pool management built-in
```

### RQ Architecture for Crop AI

```
┌──────────────────────────────────────────────────────┐
│                  FastAPI Application                 │
│          (crop_ai/api/routes/analysis.py)            │
└────────────┬──────────────────────────────────────────┘
             │
      ┌──────┴─────────┐
      │                │
      ▼                ▼
  ┌─────────────┐  ┌─────────────────────┐
  │ Validation  │  │ Enqueue Job         │
  │ & Upload    │  │ (return 202)        │
  └─────────────┘  └──────────┬──────────┘
                              │
                    ┌─────────▼─────────┐
                    │                   │
              ┌─────▼────┐        ┌─────▼────┐
              │           │        │          │
              ▼           ▼        ▼          ▼
          ┌───────────────────────────────────────┐
          │      Redis Queue (Existing Cache)     │
          │  Queue Name: "satellite_analysis"     │
          │  Max Workers: 3 (GPU constraint)      │
          └───────────────────────────────────────┘
              │           │        │          │
              ▼           ▼        ▼          ▼
          ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐
          │ RQ   │  │ RQ   │  │ RQ   │  │ RQ   │
          │Worker│  │Worker│  │Worker│  │Worker│
          │ 1    │  │ 2    │  │ 3    │  │ 4    │
          │(GPU) │  │(GPU) │  │(GPU) │  │(CPU) │
          └──┬───┘  └──┬───┘  └──┬───┘  └──┬───┘
             │         │         │         │
             └────┬────┴────┬────┴────┬────┘
                  │         │         │
          ┌───────▼─────────▼─────────▼────┐
          │  Model Inference Processing    │
          │                                │
          │ Load Model (2-3 sec)           │
          │ Preprocess (2 sec)             │
          │ Inference (10 sec)    ← GPU   │
          │ Postprocess (1 sec)            │
          │ Save Results (1 sec)           │
          │                                │
          │ TOTAL: ~16 seconds/job         │
          └───────┬────────────────────────┘
                  │
        ┌─────────▼──────────┐
        │                    │
        ▼                    ▼
    PostgreSQL          Redis Cache
    (Results)           (Quick lookup)
    • Store analysis    • Job status
    • Store vectors     • Result cache
    • Audit trail       • Session data


WORKFLOW EXAMPLE:
═══════════════════════════════════════

1. User uploads satellite image
   ├─ /api/crops/42/analyze (POST)
   └─ File: satellite_2025_12_05.tif (45MB)

2. FastAPI processes request
   ├─ Upload to Azure Blob Storage
   ├─ Validate image format
   ├─ Enqueue RQ job
   └─ Return 202 Accepted (0.1 seconds) ✅
      {"job_id": "rq:job:abc123", "status": "queued"}

3. User sees result immediately
   ├─ "Processing satellite image..."
   └─ Can leave and come back later

4. RQ Worker picks up job
   ├─ Worker 1: GPU available? No, processing batch
   ├─ Worker 2: GPU available? Yes!
   ├─ Job moves from queue to processing
   ├─ Status: "processing"

5. Worker 2 processes image
   ├─ Load PyTorch model + weights (3 sec, cached)
   ├─ Download image from blob (2 sec)
   ├─ Preprocess image (2 sec)
   ├─ Run GPU inference (10 sec)   ← GPU acceleration
   ├─ Postprocess results (1 sec)
   ├─ Save to PostgreSQL (0.5 sec)
   ├─ Cache in Redis (0.1 sec)
   └─ Mark job complete (0.2 sec)
      TOTAL: ~18 seconds

6. User polls for results
   ├─ /api/results/abc123 (GET)
   ├─ Status: "processing" (202) - first 15 seconds
   ├─ Status: "complete" (200) - after 18 seconds
   └─ Result: {
        "crop_type": "wheat",
        "confidence": 0.94,
        "soil_health": 8.2,
        "irrigation_needed": false,
        "ndvi": 0.67
      }

7. Result caching
   ├─ Similar images cache results (Redis)
   ├─ Re-running same image = instant result
   └─ No re-inference needed
```

---

## Part 5: Implementation Plan - RQ + Workers

### Architecture Deployment

```
Phase 1: Single Worker (MVP)
┌───────────────────────────┐
│   FastAPI (Azure)         │
│   • API endpoints         │
│   • Job enqueueing        │
└───────────┬───────────────┘
            │
     ┌──────▼──────┐
     │ Redis Queue │
     └──────┬──────┘
            │
     ┌──────▼──────┐
     │  RQ Worker  │
     │  (1 GPU VM) │
     │  • Inference│
     │  • ML Model │
     └─────────────┘

Cost: $30-40/month GPU VM


Phase 2: Multiple Workers (Growth)
┌───────────────────────────┐
│   FastAPI (Azure)         │
└───────────┬───────────────┘
            │
     ┌──────▼──────┐
     │ Redis Queue │
     └──────┬──────┘
            │
    ┌───────┼───────┬─────┐
    │       │       │     │
    ▼       ▼       ▼     ▼
  Worker Worker Worker Worker
   (GPU)  (GPU)  (GPU)  (CPU)
   1      2      3      4

Cost: $120-150/month (4 VMs)
Throughput: 4 parallel jobs


Phase 3: Auto-scaling (Scale)
┌───────────────────────────┐
│   FastAPI (Azure)         │
└───────────┬───────────────┘
            │
     ┌──────▼──────┐
     │ Redis Queue │
     └──────┬──────┘
            │
    ┌───────┴───────┬────────────┐
    │               │            │
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ VMSS     │  │ VMSS     │  │ VMSS     │
  │(Azure)   │  │(Batch)   │  │(Spot VMs)│
  │ 1-5 VMs  │  │ + GPU    │  │Cheaper   │
  │          │  │          │  │          │
  └──────────┘  └──────────┘  └──────────┘
  Auto-scale based on queue depth
```

### Code Implementation

```python
# app/tasks/models.py - RQ Task Definition
from rq import get_current_job
from crop_ai.models.inference import CropIdentificationModel
from crop_ai.storage.blob import BlobStorage
from crop_ai.db.models import AnalysisResult

model = None  # Cache model in worker memory

def load_model():
    """Load model once per worker"""
    global model
    if model is None:
        model = CropIdentificationModel.from_pretrained(
            'crop-ai/v2.0'
        )
    return model

def process_satellite_image(image_path: str, crop_id: int) -> dict:
    """RQ task: Process satellite image through ML model"""
    
    job = get_current_job()
    job.meta['progress'] = 10
    job.save_meta()
    
    try:
        # Step 1: Download image from blob storage
        job.meta['progress'] = 20
        job.meta['status'] = 'downloading_image'
        job.save_meta()
        
        blob_storage = BlobStorage()
        image_data = blob_storage.download(image_path)
        
        # Step 2: Load model (cached in worker)
        job.meta['progress'] = 30
        job.meta['status'] = 'loading_model'
        job.save_meta()
        
        model = load_model()
        
        # Step 3: Preprocess image
        job.meta['progress'] = 40
        job.meta['status'] = 'preprocessing'
        job.save_meta()
        
        import torch
        import torchvision.transforms as transforms
        
        transform = transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.5],
                std=[0.5]
            )
        ])
        
        tensor_image = transform(image_data)
        batch = tensor_image.unsqueeze(0)
        
        # Step 4: Run inference on GPU
        job.meta['progress'] = 60
        job.meta['status'] = 'running_inference'
        job.save_meta()
        
        with torch.no_grad():
            predictions = model(batch)
        
        # Step 5: Process results
        job.meta['progress'] = 80
        job.meta['status'] = 'postprocessing'
        job.save_meta()
        
        crop_type = predictions['crop_type']
        confidence = float(predictions['confidence'])
        soil_health = float(predictions['soil_health'])
        ndvi = float(predictions['ndvi'])
        irrigation_needed = bool(predictions['irrigation_needed'])
        
        result = {
            'crop_type': crop_type,
            'confidence': confidence,
            'soil_health': soil_health,
            'ndvi': ndvi,
            'irrigation_needed': irrigation_needed,
            'timestamp': datetime.now().isoformat(),
            'model_version': 'v2.0'
        }
        
        # Step 6: Store results
        job.meta['progress'] = 90
        job.meta['status'] = 'storing_results'
        job.save_meta()
        
        # Save to PostgreSQL
        from crop_ai.db import get_db
        db = get_db()
        
        analysis = AnalysisResult(
            crop_id=crop_id,
            image_path=image_path,
            predicted_crop_type=crop_type,
            confidence=confidence,
            soil_health_score=int(soil_health * 10),
            irrigation_needed=irrigation_needed,
            metadata=result
        )
        db.add(analysis)
        db.commit()
        
        # Cache result in Redis
        from crop_ai.cache import redis_client
        import json
        
        cache_key = f"analysis:{crop_id}"
        redis_client.setex(
            cache_key,
            86400,  # 24 hour TTL
            json.dumps(result, default=str)
        )
        
        job.meta['progress'] = 100
        job.meta['status'] = 'complete'
        job.save_meta()
        
        return result
        
    except Exception as exc:
        job.meta['status'] = 'failed'
        job.meta['error'] = str(exc)
        job.save_meta()
        raise


# app/api/routes/analysis.py - FastAPI Endpoints
from fastapi import APIRouter, File, UploadFile, HTTPException
from rq import Queue
from redis import Redis
from rq.job import Job

router = APIRouter(prefix="/api", tags=["analysis"])

redis_conn = Redis(host='cache.redis.windows.net')
q = Queue(connection=redis_conn)

@router.post("/crops/{crop_id}/analyze")
async def analyze_satellite_image(crop_id: int, file: UploadFile):
    """
    Start satellite image analysis (async)
    Returns: job_id for polling results
    """
    
    # Validate file
    if not file.filename.endswith(('.tif', '.tiff', '.geotiff', '.png', '.jpg')):
        raise HTTPException(
            status_code=400,
            detail="Invalid image format. Use TIF, PNG, or JPG"
        )
    
    # Upload to blob storage
    from crop_ai.storage.blob import BlobStorage
    blob = BlobStorage()
    
    image_path = await blob.upload(
        file=file,
        crop_id=crop_id,
        folder='satellite_imagery'
    )
    
    # Enqueue job
    job = q.enqueue(
        'app.tasks.models.process_satellite_image',
        image_path,
        crop_id,
        job_timeout='30m',
        result_ttl='1d',
        failure_ttl='7d'
    )
    
    return {
        "job_id": job.id,
        "status": "queued",
        "crop_id": crop_id,
        "message": "Satellite image analysis started. Use job_id to poll for results.",
        "poll_url": f"/api/results/{job.id}",
        "estimated_wait_seconds": 15
    }


@router.get("/results/{job_id}")
async def get_analysis_result(job_id: str):
    """
    Poll for analysis results
    Returns: 202 if processing, 200 with results if complete
    """
    
    try:
        job = Job.fetch(job_id, connection=redis_conn)
    except:
        raise HTTPException(status_code=404, detail="Job not found")
    
    if job.is_finished:
        return {
            "status": "complete",
            "job_id": job.id,
            "result": job.result
        }
    
    elif job.is_failed:
        raise HTTPException(
            status_code=400,
            detail=f"Job failed: {job.exc_info}"
        )
    
    else:
        # Still processing
        progress = job.meta.get('progress', 0)
        status_msg = job.meta.get('status', 'queued')
        
        return {
            "status": "processing",
            "job_id": job.id,
            "progress_percent": progress,
            "current_step": status_msg
        }


@router.delete("/jobs/{job_id}")
async def cancel_job(job_id: str):
    """Cancel pending or running job"""
    
    try:
        job = Job.fetch(job_id, connection=redis_conn)
        job.cancel()
        
        return {"status": "cancelled", "job_id": job.id}
    except:
        raise HTTPException(status_code=404, detail="Job not found")


@router.get("/queue/stats")
async def get_queue_stats():
    """Get queue statistics"""
    
    return {
        "queued_jobs": len(q),
        "workers_active": len(q.started_jobs),
        "finished_jobs": q.finished_job_registry.count,
        "failed_jobs": q.failed_job_registry.count
    }
```

### Worker Startup Script

```bash
#!/bin/bash
# scripts/start_rq_worker.sh

# Load environment
source .env

# Install dependencies
pip install rq psycopg2 torch torchvision

# Set up logging
export RQ_LOG_LEVEL=INFO

# Start RQ Worker
# --with-scheduler: enable job scheduling
# -w 1: single worker (GPU bottleneck)
# -u: unbuffered output

rq worker \
    --name "crop-ai-worker-1" \
    --with-scheduler \
    --job-monitoring-interval 30 \
    --worker-ttl 420 \
    --job-monitoring-interval 30 \
    --log-level INFO \
    satellite_analysis

# Output: Started worker "crop-ai-worker-1"
# Monitoring Redis queue: satellite_analysis
```

---

## Part 6: Deployment Architecture

### Single-Region MVP Deployment

```
Azure Region: East US
═══════════════════════════════════════════════════

┌─────────────────────────────────────┐
│  Static Web App (Frontend)          │
│  Angular SPA                        │
│  https://crop-ai.azurestaticapps.com
└─────────────────────────────────────┘
                  │
        ┌─────────▼────────────┐
        │                      │
        ▼                      ▼
┌──────────────────┐  ┌──────────────────────┐
│  API Container   │  │  Blob Storage        │
│  (FastAPI)       │  │  (Satellite Images)  │
│  Instance: 1vCPU │  │  Hot Tier            │
│  Memory: 1GB     │  │  $18-20/month        │
│  Cost: $40-50/mo │  │                      │
└────────┬─────────┘  └──────────────────────┘
         │
         ├──────────────┬────────────────────┐
         │              │                    │
         ▼              ▼                    ▼
    ┌────────┐  ┌─────────────┐  ┌───────────────┐
    │PostgreSQL│ │Redis Queue  │  │GPU Worker VM  │
    │Database │ │(Cache)      │  │Standard_D4s   │
    │Flex 1vC │ │2GB          │  │4vCPU, 16GB RAM│
    │$35-40/mo│ │$8-10/month  │  │$60-70/month   │
    └────────┘  └─────────────┘  └───────────────┘
         │              │              │
         └──────────────┴──────────────┘
                  │
         ┌────────▼─────────┐
         │                  │
         ▼                  ▼
    Results        Job Status
    (Store)        (Queue)

TOTAL MONTHLY COST: $161-180
```

### Multi-Region Growth Deployment

```
Azure (Primary)           AWS (Replica)
═════════════════════════════════════════════════

East US Region            US-East Region
┌──────────────────┐     ┌──────────────────┐
│ PostgreSQL v17   │────►│ Read Replica     │
│ (Primary)        │     │ (Standby)        │
│ $35-40/mo        │     │ $25-30/mo        │
└──────────────────┘     └──────────────────┘
         │                       │
         ▼                       ▼
    ┌────────────┐           ┌────────────┐
    │Redis Queue │           │Redis Queue │
    │$8-10/mo    │           │$8-10/mo    │
    └────────────┘           └────────────┘
         │                       │
    ┌────┴────┬────┐        ┌────┴────┬────┐
    │          │    │        │         │    │
    ▼          ▼    ▼        ▼         ▼    ▼
 Worker1   Worker2 Worker3  Worker4  Worker5 Worker6
 (GPU)     (GPU)   (GPU)    (GPU)    (GPU)   (GPU)
$60ea=$180  -       -       $60ea=$360 -      -

TOTAL: $296-330/month (6 workers, 2 regions)
```

---

## Part 7: Monitoring & Operations

### RQ Dashboard Setup

```python
# requirements.txt
rq-dashboard==0.14.0

# app/main.py
from rq_dashboard import blueprint as rq_dashboard

app.register_blueprint(
    rq_dashboard,
    url_prefix="/rq"
)

# Access at: http://localhost:8000/rq/
# Shows:
# - Queue depth
# - Active jobs
# - Failed jobs
# - Worker status
# - Job history
```

### Monitoring Metrics

```
Key Metrics to Track:
═══════════════════════════════════

1. Queue Depth
   └─ Alert if > 50 pending jobs (workers too slow)

2. Job Processing Time
   └─ Alert if > 30 seconds (slow GPU/model)

3. Worker Health
   └─ Alert if workers offline

4. Failed Jobs
   └─ Alert if > 5 failed jobs

5. Redis Memory
   └─ Alert if > 1GB used

6. GPU Utilization
   └─ Monitor GPU load per worker

Example Azure Alert:
┌─────────────────────────────────┐
│ Alert: Queue Depth > 50         │
│ Threshold: 50 jobs pending      │
│ Action: Auto-scale workers      │
│ Scale: +2 GPU workers           │
└─────────────────────────────────┘
```

---

## Part 8: Final Recommendation

### **Redis Queue (RQ) is the BEST choice for Crop AI**

```
DECISION SUMMARY:
═══════════════════════════════════════════

TECHNOLOGY: Redis Queue (RQ)
STATUS: ✅ RECOMMENDED

REASONS:
────────────────────────────────────────
✅ COST: $0 additional (reuse existing Redis)
✅ SIMPLICITY: Pure Python, one library
✅ PERFORMANCE: 100K+ ops/sec capacity
✅ SCALE: MVP to growth easily
✅ MULTI-CLOUD: Works everywhere
✅ OPERATIONS: Simple monitoring
✅ GPU-READY: Supports long-running jobs
✅ NO VENDOR LOCK-IN: Easy migration path

MIGRATION PATH:
────────────────────────────────────────
Phase 1 (MVP): RQ + 1 GPU worker
Phase 2 (Growth): RQ + 3-4 GPU workers  
Phase 3 (Scale): Migrate to Celery if needed

COST PROJECTION:
────────────────────────────────────────
MVP (1 GPU):           $161-180/month
Growth (3 GPU):        $280-320/month
Scale (6 GPU, 2x):     $296-330/month
```

---

## Part 9: Implementation Checklist

- [ ] Set up RQ in requirements.txt
- [ ] Create task functions (models.py)
- [ ] Create FastAPI endpoints (routes/analysis.py)
- [ ] Deploy Redis Queue configuration
- [ ] Launch first GPU worker instance
- [ ] Implement job monitoring dashboard
- [ ] Set up Azure Alerts for queue depth
- [ ] Test end-to-end workflow
- [ ] Load test with 10 concurrent jobs
- [ ] Document worker deployment process
- [ ] Create runbook for scaling workers
- [ ] Implement health check endpoint
- [ ] Set up dead-letter queue handling

---

**Document Version:** 1.0  
**Created:** December 5, 2025  
**Status:** Ready for Team Discussion & Implementation
