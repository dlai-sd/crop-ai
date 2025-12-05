"""
REGISTRATION SERVICE - FLOW DIAGRAMS & ARCHITECTURE

Visual representations of registration flows and system architecture
============================================================================
"""

# Registration Flows
# ==================

## Email Registration Flow
┌──────────────────────────────────────────────────────────────────────────┐
│                       EMAIL REGISTRATION FLOW                             │
└──────────────────────────────────────────────────────────────────────────┘

User                              Registration Service                     Database
 │                                      │                                    │
 ├──────── 1. POST /start ──────────────>│                                    │
 │         (email, role)                │                                    │
 │                                      ├─ Generate registration_id ────────>│
 │                                      │                                    │
 │                                      ├─ Store session ─────────────────>│
 │                                      │                                    │
 │<──────── 2. Response ─────────────────┤                                    │
 │         (registration_id)            │                                    │
 │                                      ├─ Send email ─────────────────────>│
 │                                      │  (verification token)             │
 │                                      │                                    │
 │ [Check Email]                        │                                    │
 │ [Click Link with token]              │                                    │
 │                                      │                                    │
 ├──────── 3. POST /verify-token ───────>│                                    │
 │         (registration_id, token)     │                                    │
 │                                      ├─ Validate token ──────────────────>│
 │                                      │                                    │
 │<──────── 4. Response ─────────────────┤                                    │
 │         (verified: true)             ├─ Update session status ─────────>│
 │                                      │  (email_verified)                 │
 │                                      │                                    │
 ├──────── 5. POST /farmer/complete ────>│                                    │
 │         (registration_id, profile)   │                                    │
 │                                      ├─ Create UserProfile ─────────────>│
 │                                      │                                    │
 │                                      ├─ Create FarmerProfile ──────────>│
 │                                      │                                    │
 │                                      ├─ Create Metadata ──────────────>│
 │                                      │                                    │
 │<──────── 6. Response ─────────────────┤                                    │
 │         (success, JWT tokens)        ├─ Cleanup session ───────────────>│
 │                                      │                                    │
 ✓ Registration Complete                │                                    │


## SSO Registration Flow (Google/Microsoft/Facebook)
┌──────────────────────────────────────────────────────────────────────────┐
│                           SSO REGISTRATION FLOW                           │
└──────────────────────────────────────────────────────────────────────────┘

User               Registration Service         OAuth Provider           Database
 │                        │                           │                      │
 ├─ Click "Sign in with Google" ─────────────────────>│                      │
 │                        │                           │                      │
 │<──────── Redirect to OAuth login ──────────────────┤                      │
 │                        │                           │                      │
 │ [Sign in with Google]  │                           │                      │
 │ [Consent permissions]  │                           │                      │
 │                        │                           │                      │
 ├────────── Auth code ──────────────────────────────>│                      │
 │                        │                           │                      │
 │<───────── Redirect with auth code ─────────────────┤                      │
 │                        │                           │                      │
 ├──────── /sso/callback ──────────────────────────────>│                      │
 │         (code, state, provider)                     │                      │
 │                        │                           │                      │
 │                        ├─ Exchange code for token ─>│                      │
 │                        │                           │                      │
 │                        │<─ Return tokens ──────────┤                      │
 │                        │                           │                      │
 │                        ├─ Get user info ──────────>│                      │
 │                        │                           │                      │
 │                        │<─ User data ──────────────┤                      │
 │                        │                           │                      │
 │                        ├─ Check if user exists ────────────────────────>│
 │                        │                           │                      │
 │                        │<──── No (new user) ─────────────────────────────┤
 │                        │                           │                      │
 │                        ├─ Generate registration_id ───────────────────>│
 │                        │                           │                      │
 │<──────── Response ──────────────────────────────────┤                      │
 │         (registration_id)                          │                      │
 │                        │                           │                      │
 ├──────── /farmer/complete ──────────────────────────>│                      │
 │         (registration_id, farm data)               │                      │
 │                        │                           │                      │
 │                        ├─ Create UserProfile ─────────────────────────>│
 │                        │                           │                      │
 │                        ├─ Create FarmerProfile ───────────────────────>│
 │                        │                           │                      │
 │                        ├─ Create SSOAccount ──────────────────────────>│
 │                        │  (tokens encrypted)       │                      │
 │                        │                           │                      │
 │<──────── Response ──────────────────────────────────┤                      │
 │         (success, JWT)                             │                      │
 │                        │                           │                      │
 ✓ SSO Registration Complete                          │                      │


## SMS Registration Flow
┌──────────────────────────────────────────────────────────────────────────┐
│                         SMS REGISTRATION FLOW                             │
└──────────────────────────────────────────────────────────────────────────┘

User                       Registration Service                  SMS Provider
 │                                │                                   │
 ├────── POST /start ──────────────>│                                   │
 │       (mobile, role)            │                                   │
 │                                 ├─ Generate OTP (6 digits) ────────┤
 │                                 │                                   │
 │                                 ├─ Send OTP via SMS ───────────────>│
 │                                 │                                   │
 │<────── Response ─────────────────┤                                   │
 │       (registration_id)         │                                   │
 │                                 │                                   │
 │ [Receive SMS with OTP]          │                                   │
 │ [Enter 6-digit code]            │                                   │
 │                                 │                                   │
 ├────── POST /verify-token ───────>│                                   │
 │       (registration_id, OTP)    │                                   │
 │                                 ├─ Validate OTP ────────────────────
 │                                 │  (expiry check, attempt limit)    │
 │                                 │                                   │
 │<────── Response ─────────────────┤                                   │
 │       (verified: true)          │                                   │
 │                                 │                                   │
 ├────── POST /farmer/complete ────>│                                   │
 │       (registration_id, profile)│                                   │
 │                                 │                                   │
 │<────── Response ─────────────────┤                                   │
 │       (success, JWT)            │                                   │
 │                                 │                                   │
 ✓ SMS Registration Complete       │                                   │


# System Architecture
# ===================

## Microservice Architecture (SOA)

┌────────────────────────────────────────────────────────────────────────┐
│                          API GATEWAY / Load Balancer                    │
└────────────────────────────────────────────────────────────────────────┘
                  │                        │                    │
        ┌─────────▼──────────┐  ┌─────────▼──────────┐  ┌─────▼────────┐
        │ Authentication     │  │  Registration      │  │  Prediction  │
        │ Service            │  │  Service           │  │  Service     │
        │                    │  │                    │  │              │
        │ • JWT validation   │  │ • Multi-role       │  │ • ML models  │
        │ • RBAC             │  │ • SSO (Google...)  │  │ • Inference  │
        │ • Sessions         │  │ • Verification     │  │              │
        └────────────────────┘  └────────────────────┘  └──────────────┘
                  │                        │                    │
        ┌─────────▼──────────┐  ┌─────────▼──────────┐  ┌─────▼────────┐
        │   PostgreSQL       │  │   PostgreSQL       │  │  PostgreSQL  │
        │   (Auth DB)        │  │   (Registration DB)│  │  (ML DB)     │
        └────────────────────┘  └────────────────────┘  └──────────────┘


## Registration Service Components

┌──────────────────────────────────────────────────────────────────────────┐
│                     REGISTRATION SERVICE                                  │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ API Routes                                                       │   │
│  │ • /register/start                                                │   │
│  │ • /register/verify-token                                         │   │
│  │ • /register/sso/callback                                         │   │
│  │ • /register/farmer/complete                                      │   │
│  │ • /register/partner/complete                                     │   │
│  │ • /register/customer/complete                                    │   │
│  │ • /register/profile/{role}/{user_id}                             │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                      │                                                    │
│  ┌──────────────────▼──────────────────┐  ┌────────────────────────┐   │
│  │ Core Services                       │  │ External Integrations  │   │
│  │                                     │  │                        │   │
│  │ • SSO Manager                       │  │ • OAuth Providers:     │   │
│  │   - Google OAuth                    │  │   - Google             │   │
│  │   - Microsoft OAuth                 │  │   - Microsoft          │   │
│  │   - Facebook OAuth                  │  │   - Facebook           │   │
│  │                                     │  │                        │   │
│  │ • Verification Service              │  │ • Email Providers:     │   │
│  │   - Email verification              │  │   - SMTP               │   │
│  │   - SMS OTP                          │  │   - SendGrid           │   │
│  │   - Token management                │  │   - AWS SES            │   │
│  │                                     │  │                        │   │
│  │ • CRUD Operations                   │  │ • SMS Providers:       │   │
│  │   - UserProfile                     │  │   - Twilio             │   │
│  │   - Role profiles                   │  │   - AWS SNS            │   │
│  │   - SSO accounts                    │  │   - Custom             │   │
│  └──────────────────┬──────────────────┘  └────────────────────────┘   │
│                     │                                                    │
│  ┌──────────────────▼──────────────────────────────────────────────┐   │
│  │ Data Layer                                                      │   │
│  │                                                                  │   │
│  │ • SQLAlchemy ORM                                                │   │
│  │ • 7 Models (UserProfile, Farmer, Partner, Customer, SSO, etc)  │   │
│  │ • 25+ CRUD operations                                           │   │
│  └──────────────────▼──────────────────────────────────────────────┘   │
│                     │                                                    │
│  ┌──────────────────▼──────────────────┐  ┌────────────────────────┐   │
│  │ PostgreSQL Database                 │  │ Redis Cache            │   │
│  │                                     │  │                        │   │
│  │ • user_profiles                     │  │ • Sessions             │   │
│  │ • farmer_profiles                   │  │ • OAuth states         │   │
│  │ • partner_profiles                  │  │ • Crops cache          │   │
│  │ • customer_profiles                 │  │ • Business types       │   │
│  │ • sso_accounts                      │  │                        │   │
│  │ • verification_tokens               │  │                        │   │
│  │ • registration_metadata             │  │                        │   │
│  └─────────────────────────────────────┘  └────────────────────────┘   │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘


## Registration Session State Machine

    ┌─────────┐
    │ PENDING │  (Initial state after /start)
    └────┬────┘
         │
         ├──────────────────────────────┐
         │                              │
    ┌────▼─────────────────┐      ┌────▼──────────────┐
    │ EMAIL_VERIFIED       │      │ MOBILE_VERIFIED   │
    │ (after /verify-token)│      │ (after /verify-token)
    └────┬──────────────────┘      └────┬──────────────┘
         │                              │
         └──────────────┬───────────────┘
                        │
                   ┌────▼──────────┐
                   │ COMPLETED     │
                   │ (after full   │
                   │  registration)│
                   └───────────────┘


## Seasonal Peak Handling Architecture

┌────────────────────────────────────────────────────────────────────────┐
│                    SEASONAL PEAK SUPPORT                               │
├────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│ Horizontal Scaling:                                                     │
│ ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐                 │
│ │ Reg App │   │ Reg App │   │ Reg App │   │ Reg App │                 │
│ │Instance1│   │Instance2│   │Instance3│   │Instance4│                 │
│ └────┬────┘   └────┬────┘   └────┬────┘   └────┬────┘                 │
│      └──────────┬─────────────────┬──────────────┘                      │
│                 │ Load Balancer   │                                      │
│                 └────────┬────────┘                                      │
│                          │                                               │
│ Database Connection Pooling:                                            │
│ ┌──────────────────────────────────────────────────────────┐           │
│ │ PostgreSQL Connection Pool (pool_size=20, max_overflow=10)           │
│ │ • Connection reuse (min latency)                          │           │
│ │ • Pre-ping (detect stale connections)                     │           │
│ │ • Pool recycle (prevent timeout)                          │           │
│ └──────────────────────────────────────────────────────────┘           │
│                                                                         │
│ Redis Caching & Session Storage:                                        │
│ ┌──────────────────────────────────────────────────────────┐           │
│ │ Redis Cluster                                             │           │
│ │ • User sessions (TTL: 1 hour)                             │           │
│ │ • OAuth state tokens (TTL: 10 min)                        │           │
│ │ • Crop lists cache (TTL: 1 day)                           │           │
│ │ • Business types cache (TTL: 1 day)                       │           │
│ └──────────────────────────────────────────────────────────┘           │
│                                                                         │
│ Async Task Queue:                                                       │
│ ┌──────────────────────────────────────────────────────────┐           │
│ │ Celery / RabbitMQ                                         │           │
│ │ • Email verification (non-blocking)                       │           │
│ │ • SMS OTP delivery (non-blocking)                         │           │
│ │ • Analytics processing                                    │           │
│ └──────────────────────────────────────────────────────────┘           │
│                                                                         │
│ Analytics & Monitoring:                                                │
│ ┌──────────────────────────────────────────────────────────┐           │
│ │ Registration Metadata Tracking                            │           │
│ │ • form_completion_time (identify bottlenecks)            │           │
│ │ • registration_method (track most-used paths)            │           │
│ │ • device_type (optimize for top platforms)               │           │
│ │ • form_abandonment_stage (conversion optimization)        │           │
│ │ • Peak detection (device type distribution during peaks)  │           │
│ └──────────────────────────────────────────────────────────┘           │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘


# Data Flow Diagram
# =================

Registration Request
        │
        ▼
┌─────────────────────────────┐
│ API Validation (Pydantic)   │
│ • Input validation          │
│ • Type checking             │
└────────────────┬────────────┘
                 │
                 ▼
        ┌─────────────────────┐
        │ Session Check       │
        │ • Verify session    │
        │ • Check expiry      │
        └────────────┬────────┘
                     │
                     ▼
        ┌───────────────────────────┐
        │ Service Layer             │
        │ • SSO processing          │
        │ • Verification handling   │
        │ • CRUD operations         │
        └────────────┬──────────────┘
                     │
                     ▼
        ┌───────────────────────────┐
        │ Database Layer            │
        │ • Create/update records   │
        │ • Transaction handling    │
        │ • Constraint validation   │
        └────────────┬──────────────┘
                     │
                     ▼
        ┌───────────────────────────┐
        │ External Services         │
        │ • Email (SMTP)            │
        │ • SMS (Twilio/SNS)        │
        │ • OAuth (Google/MS/FB)    │
        └────────────┬──────────────┘
                     │
                     ▼
              Response
            (Success/Error)


# Deployment Topology (Production)
# =================================

┌─────────────────────────────────────────────────────────────────┐
│                      LOAD BALANCER (AWS ELB)                    │
├─────────────────────────────────────────────────────────────────┤
│  HTTPS traffic distribution (TLS 1.3)                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
    ┌───▼────┐       ┌───▼────┐       ┌──▼────┐
    │Reg App │       │Reg App │       │Reg App│
    │Pod 1   │       │Pod 2   │       │Pod 3  │
    │(K8s)   │       │(K8s)   │       │(K8s)  │
    └─┬──────┘       └───┬────┘       └──┬────┘
      │                  │                 │
      └──────────────┬───┴─────────────────┘
                     │
        ┌────────────▼────────────┐
        │ Connection Pool         │
        │ PostgreSQL (RDS)        │
        │ • Primary instance      │
        │ • Read replica          │
        └────────────┬────────────┘
                     │
        ┌────────────▼────────────┐
        │ Redis Cluster           │
        │ • Session storage       │
        │ • Caching               │
        └─────────────────────────┘
