# Mobile App Development: Epics & Delivery Plan

**Approved Strategy:** Separate UI, Share Business Logic  
**Platform:** Flutter (cross-platform iOS/Android)  
**Target OS:** Android 13+, iOS 15+  
**Start Date:** Q1 2026  
**Key Advantage:** Smaller app size (20-30MB), faster frequent rollouts, superior real-time performance  

---

## Overview: Mobile App Delivery Roadmap

**Each Epic = Shippable Mobile App Feature**  
Each epic delivers a **fully functional mobile experience** that farmers can use, not just components.

```
Development Timeline:
Week -2 to 0: Epic 0 → CI/CD setup (infrastructure ready)
Week 1-4:    Epic 1 → First mobile app (Crop monitoring)
Week 5-8:    Epic 2 → AI predictions (functional)
Week 9-12:   Epic 3 → Community (gamification added)
Week 13-16:  Epic 4 → Full product (all features)
```

---

## Epic 0: CI/CD Setup & Infrastructure (Weeks -2 to 0)

**Goal:** Establish production-ready CI/CD pipeline before development starts  
**Deliverable:** Automated testing, building, and deployment workflows  
**Status:** ✅ COMPLETE (workflows created, ready for use)

### What Gets Built
- ✅ 2 GitHub Actions workflows (mobile-ci.yml, mobile-build.yml)
- ✅ Code quality standards (analysis_options.yaml)
- ✅ Flutter project structure with pubspec.yaml
- ✅ Test framework setup (unit, widget, integration tests)
- ✅ Security scanning (dependency audit, secret detection)
- ✅ SonarQube integration for code quality
- ✅ Coverage reporting (target: 80%)
- ✅ Android APK/AAB and iOS IPA build pipelines

### Key Components

**mobile-ci.yml Workflow:**
- Code Review: flutter analyze, dart format checks
- Unit Tests: Test coverage with 80% threshold
- Widget Tests: Critical screen testing
- Security Scan: Dependency vulnerabilities, secret detection
- SonarQube: Code quality analysis
- Runs on: Every commit to main/develop branches

**mobile-build.yml Workflow:**
- Android: APK (testing) + AAB (Play Store)
- iOS: IPA (TestFlight)
- Artifacts: Uploaded to GitHub Actions
- Runs on: Main branch after CI passes

**Folder Structure:**
```
mobile/
├─ lib/              # App source code
├─ test/             # Unit & widget tests
├─ android/          # Android config
├─ ios/              # iOS config
├─ pubspec.yaml      # Dependencies
└─ analysis_options.yaml # Linting rules
```

### Acceptance Criteria
- ✅ mobile-ci.yml passes all jobs
- ✅ mobile-build.yml builds APK, AAB, IPA successfully
- ✅ Coverage reports generated (>80% target)
- ✅ SonarQube connected and analyzing
- ✅ GitHub secrets configured
- ✅ Documentation complete (MOBILE_CICD_SETUP.md)
- ✅ Team trained on workflows

### Documentation
See **MOBILE_CICD_SETUP.md** for:
- Detailed workflow explanations
- Code quality standards
- Testing requirements
- Security scanning details
- Release process
- Troubleshooting guide

---

## Epic 1: Crop Monitoring Mobile App (Weeks 1-4)

**Goal:** Farmers can monitor their crops via mobile app  
**Deliverable:** Functional iOS + Android app  
**Users:** Individual farmers tracking farms  

### What Farmers Can Do (MVP):
- ✅ View all their farms/fields (location map pin + list)
- ✅ See current crop stage (seedling, growth, maturity, harvest)
- ✅ Check soil health summary (manual/sensor data)
- ✅ See weather forecast for next 7 days
- ✅ Offline mode: All data cached locally
- ✅ Sync when online: Updates from backend

### Architecture:

**Backend APIs (Shared with Web):**
```
GET /api/farmer/farms           # List all farms
GET /api/farm/{id}/details      # Current crop stage, soil health
GET /api/farm/{id}/weather      # 7-day forecast
GET /api/farm/{id}/sync         # Download for offline
POST /api/farm/{id}/sync        # Upload edits
```

**Mobile App Stack:**
```
Flutter Project Structure:
mobile/
├─ lib/
│  ├─ screens/
│  │  ├─ farm_list_screen.dart      # Shows all farms (with offline cache)
│  │  ├─ farm_details_screen.dart   # One farm details + weather
│  │  ├─ map_screen.dart            # Map view of all farms
│  │  └─ sync_screen.dart           # Offline indicator + sync status
│  ├─ services/
│  │  ├─ api_service.dart           # Calls backend APIs (Dio HTTP client)
│  │  ├─ storage_service.dart       # SQLite offline storage (Drift)
│  │  ├─ sync_service.dart          # Handles online/offline toggle (connectivity_plus)
│  │  └─ location_service.dart      # GPS for farm pinning (geolocator)
│  ├─ widgets/
│  │  ├─ farm_card.dart            # Reusable farm display
│  │  ├─ weather_card.dart         # Weather forecast display
│  │  ├─ sync_status_widget.dart    # Offline/online indicator
│  │  └─ offline_notice.dart        # Alert when offline
│  ├─ providers/
│  │  ├─ farm_provider.dart         # Manage farm data state (Riverpod)
│  │  ├─ sync_provider.dart         # Manage sync lifecycle
│  │  └─ connectivity_provider.dart # Detect online/offline
│  ├─ main.dart                     # App entry point + navigation
│  └─ app.dart                      # Main app widget
├─ pubspec.yaml                     # Flutter dependencies
├─ pubspec.lock                     # Locked dependency versions
└─ analysis_options.yaml             # Lint rules
```

### Acceptance Criteria:

- [ ] Farmers see list of farms on app launch (loaded from API)
- [ ] Tapping farm shows: crop name, stage, soil health, weather
- [ ] Map shows farm pins (farmland locations)
- [ ] **Offline:** All data accessible without network
- [ ] **Sync:** When online, push any local edits to backend
- [ ] **No sync errors:** If offline too long, queue changes gracefully
- [ ] Performance: App loads <2s, scrolling smooth (60fps)
- [ ] Works on Android 13+ & iOS 15+
- [ ] Installation size <50MB

### Backend Support (Already Exists from Phase 1):
- ✅ `/api/farm/*` endpoints in FastAPI
- ✅ Database has farm + crop data
- ✅ No new backend code needed

### Team Estimate:
- 2 Flutter devs
- 1.5 weeks core feature (Flutter faster prototyping)
- 1.5 weeks testing + refinement
- **Total: 3 weeks** (faster than React Native due to smaller bundle)

---

## Epic 2: AI Predictions Mobile App (Weeks 5-8)

**Goal:** Farmers get actionable AI predictions on mobile  
**Deliverable:** Functional prediction engine on mobile  
**Users:** Individual farmers getting risk/yield predictions  

### What Farmers Can Do:
- ✅ Tap "Get AI Insight" on farm
- ✅ See predicted crop yield (kg/acre)
- ✅ See risk factors (drought, pest, disease)
- ✅ Risk color-coded (red/yellow/green)
- ✅ Actionable recommendations ("Apply fertilizer in 3 days")
- ✅ Offline predictions (cached ML model locally)
- ✅ Share prediction with partner via message

### Architecture:

**Backend APIs (Extend Phase 1):**
```
POST /api/farm/{id}/predict              # Send farm data, get prediction
GET /api/farm/{id}/predict/history       # View past 10 predictions
POST /api/prediction/{id}/share          # Generate shareable link
GET /api/prediction/model/metadata       # Latest ML model info
```

**Mobile App Stack:**
```
Flutter Extension:
mobile/lib/
├─ screens/
│  ├─ prediction_screen.dart       # Show current prediction + risks
│  ├─ prediction_history_screen.dart # Past predictions timeline
│  └─ recommendation_screen.dart   # Action items from AI
├─ services/
│  ├─ prediction_service.dart      # Call /predict API (Dio)
│  ├─ ml_model_service.dart        # Load cached ML model (TF Lite Flutter)
│  └─ recommendation_service.dart  # Parse recommendations
├─ widgets/
│  ├─ risk_card.dart               # Color-coded risk (red/yellow/green)
│  ├─ yield_chart.dart             # Predicted yield visualization (fl_chart)
│  ├─ recommendation_item.dart     # Single action item
│  └─ share_button.dart            # Share prediction UI
└─ providers/
   ├─ prediction_provider.dart     # Fetch prediction + errors (Riverpod)
   ├─ ml_model_provider.dart       # Load + cache local ML model
   └─ recommendation_provider.dart # Parse AI output
```

**ML Model (Local on Mobile):**
```
mobile/assets/models/
├─ crop_yield_v1.tflite         # Quantized TF model (~5MB)
└─ model_metadata.json          # Input features, output schema
```

### Acceptance Criteria:

- [ ] Farmers tap "Get AI Insight" → Prediction in <3s
- [ ] Shows predicted yield (e.g., "2,400 kg/acre expected")
- [ ] Shows risk factors with explanations
- [ ] Color-coded risk (🟢 Low, 🟡 Medium, 🔴 High)
- [ ] Actionable recommendations (specific, time-bound)
- [ ] **Offline:** Prediction works without network (using cached model)
- [ ] **History:** View last 10 predictions with dates
- [ ] **Share:** Generate link to share prediction (via WhatsApp, etc.)
- [ ] Syncs predictions to backend when online
- [ ] Works on Android 13+ & iOS 15+

### Backend Support (New Code):
- 🆕 Extend `/api/farm/{id}/predict` with recommendations engine
- 🆕 Add prediction history storage
- 🆕 Generate shareable prediction links
- 🔄 Model versioning API

### Team Estimate:
- 2 Flutter devs (ML integration)
- 1 Backend dev (expand prediction APIs)
- 1.5 weeks core feature
- 1 week ML model + mobile optimization (Flutter TF Lite bindings mature)
- 0.5 weeks testing
- **Total: 3 weeks**

---

## Epic 3: Community & Gamification Mobile App (Weeks 9-12)

**Goal:** Farmers engage with community + earn badges  
**Deliverable:** Functional social + gamification layer  
**Users:** Individual farmers sharing experiences, earning achievements  

### What Farmers Can Do:
- ✅ View "Chaupal" community feed (posts, tips, discussions)
- ✅ Create post (text + photo) about their farm
- ✅ Comment on other farmer posts
- ✅ See earned badges + levels (Seedling → Annadata)
- ✅ Unlock badges by actions (first prediction, 10 posts, etc.)
- ✅ View leaderboard (top farmers by region)
- ✅ **Offline:** Read cached feed, compose posts (sync when online)

### Architecture:

**Backend APIs (New):**
```
GET /api/community/feed             # Feed of posts (paginated)
POST /api/community/posts           # Create new post
POST /api/community/posts/{id}/like # Like/unlike post
POST /api/community/comments        # Add comment
GET /api/farmer/badges              # View earned badges
GET /api/farmer/level               # Current level + progress
GET /api/leaderboard/regional       # Top farmers by region
POST /api/gamification/sync         # Update badge progress
```

**Mobile App Stack:**
```
Flutter Extension:
mobile/lib/
├─ screens/
│  ├─ chaupal_feed_screen.dart      # Community feed (scrollable)
│  ├─ create_post_screen.dart       # Text + photo composer
│  ├─ persona_screen.dart           # Profile + badges + level
│  ├─ leaderboard_screen.dart       # Top farmers by region
│  └─ post_detail_screen.dart       # Single post + comments
├─ services/
│  ├─ community_service.dart        # Feed + posts API calls (Dio)
│  ├─ gamification_service.dart     # Badge calculation + progress
│  ├─ engagement_service.dart       # Like/comment interactions
│  └─ offline_queue_service.dart    # Queue posts/comments when offline
├─ widgets/
│  ├─ post_card.dart                # Single post display (text + image)
│  ├─ badge_card.dart               # Badge with unlock condition
│  ├─ level_progress_widget.dart    # Level bar + next milestone
│  ├─ leaderboard_row.dart          # Farmer entry in leaderboard
│  ├─ comment_thread.dart           # Comments on post
│  └─ like_button.dart              # Like/unlike interaction
└─ providers/
   ├─ chaupal_feed_provider.dart    # Pagination + caching (Riverpod)
   ├─ gamification_provider.dart    # Badge tracking
   ├─ level_progress_provider.dart  # Calculate progress to next level
   └─ engagement_provider.dart      # Handle likes, comments, shares
```

**Gamification Logic (Backend - Source of Truth):**
```python
# src/crop_ai/gamification.py (existing from Phase 1)
def calculate_level(total_actions: int) -> tuple[int, str]:
    """Calculate farmer level (Seedling → Annadata)"""
    levels = [
        (0, "Seedling"),          # 0-50 actions
        (51, "Farmer"),           # 51-200
        (201, "Master Farmer"),   # 201-500
        (501, "Expert"),          # 501+
        (1000, "Annadata")        # 1000+ (legendary)
    ]
    
def unlock_badges(farmer_id: str) -> List[Badge]:
    """Determine which badges farmer has unlocked"""
    # Badge: First Prediction
    # Badge: 10 Community Posts
    # Badge: 100 Helpful Votes
    # Badge: Regional Leader
```

### Acceptance Criteria:

- [ ] Community feed loads with 20+ posts (paginated)
- [ ] Farmers can create posts with text + photo
- [ ] Photo upload optimized (<500KB on mobile)
- [ ] Comments thread on posts works smoothly
- [ ] Badge system calculates correctly (no false unlocks)
- [ ] Level progress shows clear path to next level
- [ ] Leaderboard shows top 10 farmers by region
- [ ] **Offline:** Draft posts saved locally, synced when online
- [ ] **Notifications:** Badge unlocked → Push notification
- [ ] Performance: Feed scrolls smooth (60fps), infinite scroll works
- [ ] Works on Android 13+ & iOS 15+

### Backend Support (New):
- 🆕 Community feed API with pagination
- 🆕 Post/comment storage + moderation
- 🆕 Badge unlock triggers
- 🆕 Leaderboard calculation
- 🆕 Regional aggregation for leaderboard

### Team Estimate:
- 2 Flutter devs (UI + engagement)
- 1 Backend dev (API + gamification)
- 1 Product manager (engagement mechanics)
- 1.5 weeks core features (Flutter faster)
- 1 week backend + badge logic
- 0.5 weeks testing + polish
- **Total: 3 weeks**

---

## Epic 4: Marketplace & Partner Connections (Weeks 13-16)

**Goal:** Farmers connect with partners (input suppliers, buyers)  
**Deliverable:** Functional marketplace on mobile  
**Users:** Farmers discovering services, partners offering services  

### What Farmers Can Do:
- ✅ Browse input suppliers (fertilizer, seeds, equipment rentals)
- ✅ View partner ratings + reviews
- ✅ Request quote for service (e.g., "Rent tractor for 2 days")
- ✅ Chat with partner about request
- ✅ See nearby services on map
- ✅ Track order status (requested → accepted → completed)
- ✅ Rate + review partner after transaction

### Architecture:

**Backend APIs (New):**
```
GET /api/marketplace/services        # Available services
GET /api/marketplace/services/{id}   # Service details
POST /api/marketplace/requests       # Farmer requests service
GET /api/marketplace/requests        # View my requests + status
POST /api/marketplace/messages       # Chat with partner
GET /api/marketplace/messages/{id}   # Conversation history
POST /api/marketplace/reviews        # Submit review
GET /api/marketplace/nearby          # Services near farm (geo)
```

**Mobile App Stack:**
```
Flutter Extension:
mobile/lib/
├─ screens/
│  ├─ marketplace_screen.dart      # Browse services
│  ├─ service_detail_screen.dart   # Service + partner info + reviews
│  ├─ request_quote_screen.dart    # Form to request service
│  ├─ my_requests_screen.dart      # Order history + status
│  ├─ chat_screen.dart             # Conversation with partner (Firebase Realtime)
│  ├─ nearby_services_screen.dart  # Map of nearby services (google_maps_flutter)
│  └─ review_screen.dart           # Rate + review after transaction
├─ services/
│  ├─ marketplace_service.dart     # Browse + request APIs (Dio)
│  ├─ messaging_service.dart       # Chat + notifications (Firebase)
│  ├─ location_service.dart        # Geo queries for nearby services
│  └─ review_service.dart          # Rating + review
├─ widgets/
│  ├─ service_card.dart            # Service listing (name, price, rating)
│  ├─ partner_profile.dart         # Partner info + reviews
│  ├─ rating_bar.dart              # 5-star rating display
│  ├─ chat_bubble.dart             # Message in conversation
│  ├─ map_marker.dart              # Service on map
│  └─ review_form.dart             # Text + rating form
└─ providers/
   ├─ marketplace_provider.dart    # Browse + filter (Riverpod)
   ├─ messaging_provider.dart      # Chat state (Firebase listener)
   ├─ nearby_provider.dart         # Geo queries
   └─ review_provider.dart         # Rating system
```

### Acceptance Criteria:

- [ ] Farmers browse 100+ services with filters (category, rating)
- [ ] Service detail shows: price, availability, partner reviews
- [ ] Request flow: Input quantity → Confirm → Chat with partner
- [ ] Chat works real-time (Firebase or WebSocket)
- [ ] Order tracking: Status updates (pending → confirmed → completed)
- [ ] Map shows services within 5km of farm
- [ ] Review system: 5-star + text, visible to other farmers
- [ ] **Offline:** Browse cached services, compose requests (sync online)
- [ ] Notifications: Order status changes, partner replies
- [ ] Performance: Browse smooth, search results <1s
- [ ] Works on Android 13+ & iOS 15+

### Backend Support (New):
- 🆕 Service listing + search
- 🆕 Request/order management
- 🆕 Real-time messaging
- 🆕 Review aggregation + ranking
- 🆕 Geo-location queries

### Team Estimate:
- 2 Flutter devs (marketplace UI + chat)
- 1 Backend dev (service APIs + messaging)
- 1 DevOps (Firebase real-time messaging setup)
- 2 weeks core marketplace (Flutter faster)
- 0.75 weeks messaging + real-time (Firebase integration simpler in Flutter)
- 0.25 weeks testing + polish
- **Total: 3 weeks**

---

## Epic 5: Full Product Integration (Weeks 17+, Ongoing)

**Goal:** All features work seamlessly together  
**Deliverable:** Production-ready mobile app  

### Activities:
- Performance optimization (reduce bundle size, improve startup)
- Security hardening (auth, data encryption, API security)
- Push notifications framework (badges, recommendations, messages)
- Analytics integration (understand farmer behavior)
- App store submission (Google Play, Apple App Store)
- Beta testing with real farmers
- Localization (Hindi, regional languages)

---

## Epic Priority & Dependencies

```
Epic 0: CI/CD Setup & Infrastructure
└─ Foundation: Workflows, testing, security scanning
   ↓
Epic 1: Crop Monitoring
└─ Foundation: Maps, offline sync, farm data
   ↓
Epic 2: AI Predictions  
└─ Depends on: Farm data from Epic 1
   ↓
Epic 3: Community & Gamification
└─ Depends on: Farmer profiles from Epic 1
   ↓
Epic 4: Marketplace
└─ Depends on: Farmer authentication (Epic 1)
   ↓
Epic 5: Full Integration & Polish
└─ Depends on: All above working
```

**Parallelization Strategy:**
- Epic 0 (CI/CD) → Complete BEFORE starting Epic 1
- Epic 2 & Epic 3 can start in parallel once Epic 1 is in beta (week 5)
- Epic 4 starts after Epics 1+2+3 are in beta (week 13)

---

## Why Flutter Over React Native?

| Factor | Flutter | React Native |
|--------|---------|---------------|
| **App Size** | 20-30MB (small) | 45-60MB (large) |
| **Release Cycle** | Fast iteration due to smaller build | Slower, larger bundles |
| **Real-time Performance** | Superior (Chaupal feed, chat) | Good but slower on older devices |
| **ML Integration** | TF Lite bindings mature & optimized | Requires native modules |
| **Offline Sync** | Excellent (Drift ORM) | Good (Realm or SQLite) |
| **Development Speed** | Hot reload + strong typing (Dart) | Hot reload + JS flexibility |
| **Team Ramp** | Dart learning curve initially | JS developers faster onboard |
| **Rural Performance** | Optimized for older devices | Can be bloated on slow devices |

**Recommendation:** Flutter wins for your use case (20-30MB size = faster downloads on 2G/3G networks, better real-time updates for community feed).

---

## Tech Stack (Flutter)

| Component | Technology | Why |
|-----------|-----------|-----|
| **Mobile Framework** | Flutter (Dart) | Cross-platform iOS/Android, compiled to native |
| **State Management** | Riverpod | Type-safe, composable, excellent for sync |
| **Offline Storage** | Drift (SQLite wrapper) | Relational + type-safe, excellent ORM |
| **Maps** | google_maps_flutter | High-quality maps, geolocation |
| **ML Model** | TensorFlow Lite Flutter | Native bindings, optimized performance |
| **Push Notifications** | Firebase Cloud Messaging | Cross-platform, excellent Flutter support |
| **Real-time Chat** | Firebase Realtime DB | WebSocket alternative, instant updates |
| **Analytics** | Firebase Analytics | Free, first-class Flutter support |
| **API Client** | Dio | Excellent interceptors, offline queueing |
| **Image Handling** | image_picker + cached_network_image | Optimized caching, compression |
| **Connectivity** | connectivity_plus | Detect online/offline, handle transitions |
| **Local Notifications** | flutter_local_notifications | Badge earned, order updates |
| **Camera** | camera | For photo uploads (marketplace, community) |

---

## Resource Plan

### Team Composition (Recommended):
- **2 Flutter Devs** (full-time, Weeks 1-16)
- **1-2 Backend Devs** (part-time Weeks 1-4, full-time Weeks 5-16)
- **1 DevOps/Infrastructure** (Weeks 9-16 for Firebase + app store)
- **1 Product Manager** (full-time, all weeks)
- **1 QA Engineer** (Weeks 4-16 for testing)

### Budget Estimate:
- Team: 6 people × 4 months = 24 person-months
- Infrastructure: Firebase, Apple Developer ($99/yr), Google Play ($25/yr)
- **Total: ~$500-700K for 4-month sprint**

---

## Success Metrics by Epic

### Epic 1 (Crop Monitoring):
- ✅ 100% farmers can view farms on app
- ✅ 80%+ use offline mode at least once
- ✅ App startup <2s
- ✅ 0 sync data loss incidents

### Epic 2 (AI Predictions):
- ✅ 60%+ of farmers request prediction at least weekly
- ✅ Avg prediction time <3s
- ✅ Offline prediction accuracy ±5% of online

### Epic 3 (Community & Gamification):
- ✅ 50%+ of farmers create at least 1 post
- ✅ Avg daily active users (DAU) in Chaupal >40%
- ✅ Badge unlock → 20% engagement boost (shown in analytics)

### Epic 4 (Marketplace):
- ✅ 30%+ of farmers browse services
- ✅ 10%+ make marketplace transaction
- ✅ Avg service request → completion <48 hours

### Epic 5 (Full Integration):
- ✅ App rating >4.2 stars (Play Store + App Store)
- ✅ 95%+ crash-free rate
- ✅ 70%+ monthly active users (MAU) from launched features

---

## Risk Mitigation

### By Epic:

**Epic 1 - Offline Sync Complexity**
- Risk: Data loss during sync
- Mitigation: Versioned sync protocol, conflict resolution testing
- Backup plan: Use proven library (WatermelonDB)

**Epic 2 - ML Model Performance**
- Risk: Predictions too slow on older devices
- Mitigation: Quantized model, local benchmarking
- Backup plan: Fall back to server-side predictions on slow devices

**Epic 3 - Moderation at Scale**
- Risk: Inappropriate posts, spam
- Mitigation: Automated keyword filter, farmer flagging, backend review
- Backup plan: Require partner approval for posts initially

**Epic 4 - Payment Trust**
- Risk: Farmers hesitant to pay before service
- Mitigation: Escrow-style payments, partner verification badges
- Backup plan: Start with request-only (no payment), add later

**Epic 5 - App Store Approval**
- Risk: Rejection due to policy violations
- Mitigation: Compliance review 2 weeks before submission
- Backup plan: Progressive web app (PWA) as fallback

---

## Next Steps

1. **Week -2:** Setup Firebase project + GitHub secrets
2. **Week -1:** Team environment setup (Flutter SDK, emulators)
3. **Week 0:** Epic 0 validation - ensure all CI/CD workflows pass
4. **Week 1:** Start Epic 1 development (farm list + offline sync)
5. **Week 5:** Start Epic 2 (AI predictions) with Epic 1 in beta
6. **Week 9:** Start Epic 3 (community) with Epic 1+2 in beta
7. **Week 13:** Start Epic 4 (marketplace) with 1+2+3 in beta
8. **Week 17:** Full integration + app store submission

---

**Next Decision Point:**
Approve these epics → Start Epic 1 detailed design → Setup development environment

