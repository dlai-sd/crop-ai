# Mobile App Development: Epics & Delivery Plan

**Approved Strategy:** Separate UI, Share Business Logic  
**Platform:** React Native (cross-platform iOS/Android)  
**Target OS:** Android 13+, iOS 15+  
**Start Date:** Q1 2026  

---

## Overview: Mobile App Delivery Roadmap

**Each Epic = Shippable Mobile App Feature**  
Each epic delivers a **fully functional mobile experience** that farmers can use, not just components.

```
Farmer Timeline:
Week 1-4:    Epic 1 → First mobile app (Crop monitoring)
Week 5-8:    Epic 2 → AI predictions (functional)
Week 9-12:   Epic 3 → Community (gamification added)
Week 13-16:  Epic 4 → Full product (all features)
```

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
React Native Project Structure:
mobile/
├─ src/
│  ├─ screens/
│  │  ├─ FarmListScreen.tsx      # Shows all farms (with offline cache)
│  │  ├─ FarmDetailsScreen.tsx   # One farm details + weather
│  │  ├─ MapScreen.tsx           # Map view of all farms
│  │  └─ SyncScreen.tsx          # Offline indicator + sync status
│  ├─ services/
│  │  ├─ api.ts                  # Calls backend APIs
│  │  ├─ storage.ts              # SQLite offline storage
│  │  ├─ sync.ts                 # Handles online/offline toggle
│  │  └─ location.ts             # GPS for farm pinning
│  ├─ components/
│  │  ├─ FarmCard.tsx            # Reusable farm display
│  │  ├─ WeatherCard.tsx         # Weather forecast display
│  │  ├─ SyncStatus.tsx          # Offline/online indicator
│  │  └─ OfflineNotice.tsx       # Alert when offline
│  ├─ hooks/
│  │  ├─ useSync.ts              # Manage sync lifecycle
│  │  ├─ useOffline.ts           # Detect online/offline
│  │  └─ useFarmData.ts          # Fetch + cache farm data
│  └─ App.tsx                    # Navigation setup (bottom tabs)
├─ app.json                      # Expo config
└─ package.json
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
- 2 React Native devs
- 2 weeks core feature
- 2 weeks testing + refinement
- **Total: 4 weeks**

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
React Native Extension:
mobile/src/
├─ screens/
│  ├─ PredictionScreen.tsx       # Show current prediction + risks
│  ├─ PredictionHistoryScreen.tsx # Past predictions timeline
│  └─ RecommendationScreen.tsx   # Action items from AI
├─ services/
│  ├─ prediction.ts              # Call /predict API
│  ├─ mlModel.ts                 # Load cached ML model (TF Lite)
│  └─ recommendations.ts         # Parse recommendations
├─ components/
│  ├─ RiskCard.tsx               # Color-coded risk (red/yellow/green)
│  ├─ YieldChart.tsx             # Predicted yield visualization
│  ├─ RecommendationItem.tsx     # Single action item
│  └─ ShareButton.tsx            # Share prediction UI
└─ hooks/
   ├─ usePrediction.ts           # Fetch prediction + errors
   ├─ useMLModel.ts              # Load + cache local ML model
   └─ useRecommendations.ts      # Parse AI output
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
- 2 React Native devs (ML integration)
- 1 Backend dev (expand prediction APIs)
- 2 weeks core feature
- 1.5 weeks ML model + mobile optimization
- 0.5 weeks testing
- **Total: 4 weeks**

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
React Native Extension:
mobile/src/
├─ screens/
│  ├─ ChaupalFeedScreen.tsx      # Community feed (scrollable)
│  ├─ CreatePostScreen.tsx       # Text + photo composer
│  ├─ PersonaScreen.tsx          # Profile + badges + level
│  ├─ LeaderboardScreen.tsx      # Top farmers by region
│  └─ PostDetailScreen.tsx       # Single post + comments
├─ services/
│  ├─ community.ts               # Feed + posts API calls
│  ├─ gamification.ts            # Badge calculation + progress
│  ├─ engagement.ts              # Like/comment interactions
│  └─ offline.ts                 # Queue posts/comments when offline
├─ components/
│  ├─ PostCard.tsx               # Single post display (text + image)
│  ├─ BadgeCard.tsx              # Badge with unlock condition
│  ├─ LevelProgress.tsx          # Level bar + next milestone
│  ├─ LeaderboardRow.tsx         # Farmer entry in leaderboard
│  ├─ CommentThread.tsx          # Comments on post
│  └─ LikeButton.tsx             # Like/unlike interaction
└─ hooks/
   ├─ useChaupalFeed.ts          # Pagination + caching
   ├─ useGamification.ts         # Badge tracking
   ├─ useLevelProgress.ts        # Calculate progress to next level
   └─ useEngagement.ts           # Handle likes, comments, shares
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
- 2 React Native devs (UI + engagement)
- 1 Backend dev (API + gamification)
- 1 Product manager (engagement mechanics)
- 2 weeks core features
- 1 week backend + badge logic
- 0.5 weeks testing + polish
- **Total: 3.5 weeks**

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
React Native Extension:
mobile/src/
├─ screens/
│  ├─ MarketplaceScreen.tsx      # Browse services
│  ├─ ServiceDetailScreen.tsx    # Service + partner info + reviews
│  ├─ RequestQuoteScreen.tsx     # Form to request service
│  ├─ MyRequestsScreen.tsx       # Order history + status
│  ├─ ChatScreen.tsx             # Conversation with partner
│  ├─ NearbyServicesScreen.tsx   # Map of nearby services
│  └─ ReviewScreen.tsx           # Rate + review after transaction
├─ services/
│  ├─ marketplace.ts             # Browse + request APIs
│  ├─ messaging.ts               # Chat + notifications
│  ├─ location.ts                # Geo queries for nearby services
│  └─ reviews.ts                 # Rating + review
├─ components/
│  ├─ ServiceCard.tsx            # Service listing (name, price, rating)
│  ├─ PartnerProfile.tsx         # Partner info + reviews
│  ├─ RatingBar.tsx              # 5-star rating display
│  ├─ ChatBubble.tsx             # Message in conversation
│  ├─ MapMarker.tsx              # Service on map
│  └─ ReviewForm.tsx             # Text + rating form
└─ hooks/
   ├─ useMarketplaceSearch.ts    # Browse + filter
   ├─ useMessaging.ts            # Chat state
   ├─ useNearby.ts               # Geo queries
   └─ useReviews.ts              # Rating system
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
- 2 React Native devs (marketplace UI + chat)
- 1 Backend dev (service APIs + messaging)
- 1 DevOps (real-time messaging setup)
- 2.5 weeks core marketplace
- 1 week messaging + real-time
- 0.5 weeks testing + polish
- **Total: 4 weeks**

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

**Can parallelize:** Epic 2 & Epic 3 (start in weeks 5-9 with overlap)

---

## Tech Stack Summary

| Component | Technology | Why |
|-----------|-----------|-----|
| **Mobile Framework** | React Native | Cross-platform iOS/Android, JS ecosystem |
| **State Management** | Redux or Zustand | Manage sync state, offline queue |
| **Offline Storage** | SQLite (via WatermelonDB) | Relational queries, performance |
| **Maps** | Expo MapView | Pre-integrated, simple API |
| **ML Model** | TensorFlow Lite | Lightweight, on-device predictions |
| **Push Notifications** | Firebase Cloud Messaging | Cross-platform, backend-triggered |
| **Real-time Chat** | Firebase Realtime DB or Pusher | WebSocket alternative |
| **Analytics** | Firebase Analytics | Free, integrated with FCM |
| **API Client** | Axios + custom retry | Handle offline queueing |

---

## Resource Plan

### Team Composition (Recommended):
- **2 React Native Devs** (full-time, Weeks 1-16)
- **1-2 Backend Devs** (part-time Weeks 1-4, full-time Weeks 5-16)
- **1 DevOps/Infrastructure** (Weeks 9-16 for real-time + app store)
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

1. **Week 0 (This Week):** Finalize Epic 1 detailed requirements
2. **Week 0:** Set up React Native project, GitHub workflows for mobile CI/CD
3. **Week 1:** Start Epic 1 development (farm list + offline sync)
4. **Week 5:** Start Epic 2 (AI predictions) with Epic 1 in beta
5. **Week 9:** Start Epic 3 (community) with Epic 1+2 in beta
6. **Week 13:** Start Epic 4 (marketplace) with 1+2+3 in beta
7. **Week 17:** Full integration + app store submission

---

**Next Decision Point:**
Approve these epics → Start Epic 1 detailed design → Setup development environment

