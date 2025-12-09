# Epic 2: AI Predictions - Development Guide

**Epic Status:** Starting Sprint 1  
**Branch:** `epic/2-ai-predictions`  
**Date Started:** December 9, 2025  
**Target Completion:** January 15, 2026 (6 weeks)

---

## 🎯 Epic Objective

Enable on-device machine learning for crop health monitoring and yield prediction, providing farmers with actionable insights without requiring internet connectivity.

---

## 📋 Features in Epic 2

### Feature 2.1: Crop Disease Detection
- **Objective:** Detect crop diseases from photos using TensorFlow Lite
- **Timeline:** Week 1-2 (80 story points)
- **Owner:** ML Engineer
- **Status:** 🔄 Planning

### Feature 2.2: Yield Forecasting
- **Objective:** Predict farm yield using ML regression model
- **Timeline:** Week 2-3 (70 story points)
- **Owner:** ML Engineer
- **Status:** 🔄 Planning

### Feature 2.3: Growth Stage Classification
- **Objective:** Classify crop growth stage from photos
- **Timeline:** Week 3 (60 story points)
- **Owner:** ML Engineer
- **Status:** 🔄 Planning

---

## 🏗️ Architecture Overview

### Data Flow
```
Farm Data (Epic 1)
    ↓
Weather Data (Epic 1)
    ↓
ML Models (TensorFlow Lite)
    ├── Disease Detection Model
    ├── Yield Prediction Model
    └── Growth Stage Model
    ↓
Predictions Provider (Riverpod)
    ↓
UI Screens & Widgets
```

### Project Structure
```
lib/features/ai_predictions/
├── models/
│   ├── disease_prediction.dart      # Disease detection output model
│   ├── yield_prediction.dart        # Yield forecast output model
│   └── growth_stage_prediction.dart # Growth stage output model
├── data/
│   ├── ml_service.dart              # TFLite model interface
│   ├── disease_repository.dart      # Disease data persistence
│   ├── yield_repository.dart        # Yield forecast persistence
│   └── growth_stage_repository.dart # Growth stage persistence
├── providers/
│   ├── disease_provider.dart        # Riverpod providers for disease
│   ├── yield_provider.dart          # Riverpod providers for yield
│   └── growth_stage_provider.dart   # Riverpod providers for growth
└── screens/
    ├── disease_detection_screen.dart
    ├── yield_forecast_screen.dart
    └── growth_stage_screen.dart

test/features/ai_predictions/
├── models/
│   ├── disease_prediction_test.dart
│   ├── yield_prediction_test.dart
│   └── growth_stage_prediction_test.dart
├── data/
│   ├── ml_service_test.dart
│   └── *_repository_test.dart
└── integration/
    └── ai_predictions_integration_test.dart
```

---

## 📦 Dependencies to Add

```yaml
# pubspec.yaml additions

# TensorFlow Lite
tflite_flutter: ^0.10.0
tflite_flutter_helper: ^0.10.0

# Image processing
image: ^4.0.0
image_picker: ^1.0.0  # Already exists

# ML utilities
ml_linalg: ^13.0.0    # For matrix operations if needed

# Data persistence (already exists)
drift: ^2.13.0
sqlite3_flutter_libs: ^0.5.0

# Riverpod (already exists)
flutter_riverpod: ^2.4.0
```

**Installation:**
```bash
cd mobile
flutter pub add tflite_flutter tflite_flutter_helper image ml_linalg
flutter pub get
```

---

## 🤖 ML Models Setup

### Model Storage
```
mobile/assets/models/
├── disease_detection.tflite         # ~5-10 MB
├── yield_prediction.tflite          # ~2-5 MB
└── growth_stage.tflite              # ~5-10 MB
```

### Model Specifications

#### 1. Disease Detection Model
- **Type:** Image Classification (MobileNetV2 backbone)
- **Input:** 224x224 RGB image (normalized to [-1, 1])
- **Output:** 50 disease classes + confidence scores
- **Size:** ~8 MB
- **Latency:** <500ms on mid-range device
- **Accuracy:** 85%+ on validation set
- **Source:** PlantVillage dataset or custom trained

#### 2. Yield Prediction Model
- **Type:** Regression (Fully connected layers)
- **Input:** 15 numerical features
  - Temperature (avg, min, max)
  - Rainfall
  - Soil moisture
  - Soil pH, nitrogen, phosphorus, potassium
  - Crop type (one-hot encoded)
  - Area (hectares)
  - Planting date (days since planting)
- **Output:** Yield (kg/hectare), confidence interval
- **Size:** ~2-3 MB
- **Latency:** <100ms
- **Accuracy:** 85%+ R² score
- **Source:** Historical farm data + public datasets

#### 3. Growth Stage Model
- **Type:** Image Classification
- **Input:** 224x224 RGB crop photo
- **Output:** 6 growth stages + confidence
  - Seedling (0-2 weeks)
  - Vegetative (3-8 weeks)
  - Flowering (9-12 weeks)
  - Fruit/Grain (13-18 weeks)
  - Mature (19-24 weeks)
  - Harvest ready (25+ weeks)
- **Size:** ~6-8 MB
- **Latency:** <300ms
- **Accuracy:** 90%+ on validation
- **Source:** PlantVillage or agricultural imagery datasets

---

## 🎯 Development Roadmap

### Week 1: Foundation & Disease Detection

**Sprint 1.1: Model Setup & ML Service**
- [ ] Add TFLite dependencies to pubspec.yaml
- [ ] Create MLService abstraction layer
- [ ] Implement model loading from assets
- [ ] Image preprocessing utilities
- [ ] Error handling for model inference
- [ ] Unit tests for MLService (8 tests)

**Sprint 1.2: Disease Detection Feature**
- [ ] Create DiseasePredict model
- [ ] Build DiseasePredictionRepository
- [ ] Implement Riverpod providers
- [ ] Design DiseaseDetectionScreen
- [ ] Build treatment recommendations UI
- [ ] Create DiseaseHistory widget
- [ ] Unit tests for disease models (8 tests)
- [ ] Integration test for detection flow

**Deliverables:**
- DiseaseDetectionScreen with live camera integration
- Treatment recommendation display
- Detection history with date/location
- <500ms inference time verified

---

### Week 2: Yield Forecasting & Integration

**Sprint 2.1: Yield Prediction Model**
- [ ] Create YieldPredict model
- [ ] Build feature engineering utilities
- [ ] Implement YieldPredictionRepository
- [ ] Create Riverpod yield providers
- [ ] Design YieldForecastScreen
- [ ] Build historical yield chart
- [ ] Unit tests for yield models (8 tests)

**Sprint 2.2: Integration & Analytics**
- [ ] Integrate with weather data (Feature 2)
- [ ] Integrate with farm data (Feature 1)
- [ ] Build comparison UI (predicted vs actual)
- [ ] Confidence interval display
- [ ] Regional benchmark comparison
- [ ] Export yield report functionality
- [ ] Integration tests (8 tests)

**Deliverables:**
- YieldForecastScreen with historical trends
- Confidence bounds visualization
- Regional comparison analytics
- PDF export capability

---

### Week 3: Growth Stage & Polish

**Sprint 3.1: Growth Stage Classification**
- [ ] Create GrowthStage model
- [ ] Build GrowthStageRepository
- [ ] Create Riverpod providers
- [ ] Design GrowthStageScreen
- [ ] Build stage-specific recommendations
- [ ] Timeline visualization (when to apply inputs)
- [ ] Photo progression gallery
- [ ] Unit tests (8 tests)

**Sprint 3.2: Testing & Documentation**
- [ ] Write 20+ integration tests covering all flows
- [ ] Performance benchmarks
- [ ] Model accuracy validation
- [ ] Create developer documentation
- [ ] Code review & refactoring
- [ ] Final bug fixes

**Deliverables:**
- GrowthStageScreen with timeline
- Stage-specific recommendations
- Photo history gallery
- Complete test coverage (66+ tests)

---

## 🔧 Implementation Checklist

### Phase 1: ML Service Foundation
- [ ] Add TFLite dependencies
- [ ] Create `ml_service.dart` abstraction
- [ ] Implement model asset loading
- [ ] Image preprocessing (resize, normalize)
- [ ] Error handling & logging
- [ ] Unit tests for ML service

**File:** `lib/features/ai_predictions/data/ml_service.dart`
**Status:** 🔴 Not Started
**Effort:** 20 story points

### Phase 2: Disease Detection
- [ ] Create disease models and repositories
- [ ] Build disease detection screen
- [ ] Implement camera photo capture
- [ ] Design UI for results and recommendations
- [ ] Add disease history tracking
- [ ] Write comprehensive tests

**Files:**
- `lib/features/ai_predictions/models/disease_prediction.dart`
- `lib/features/ai_predictions/data/disease_repository.dart`
- `lib/features/ai_predictions/screens/disease_detection_screen.dart`

**Status:** 🔴 Not Started
**Effort:** 40 story points

### Phase 3: Yield Forecasting
- [ ] Create yield models and repositories
- [ ] Build feature engineering utilities
- [ ] Create yield forecast screen
- [ ] Implement historical comparison
- [ ] Add regional benchmarking
- [ ] Write tests

**Files:**
- `lib/features/ai_predictions/models/yield_prediction.dart`
- `lib/features/ai_predictions/data/yield_repository.dart`
- `lib/features/ai_predictions/screens/yield_forecast_screen.dart`

**Status:** 🔴 Not Started
**Effort:** 45 story points

### Phase 4: Growth Stage Classification
- [ ] Create growth stage models and repositories
- [ ] Build growth stage screen
- [ ] Implement stage recommendations
- [ ] Create timeline visualization
- [ ] Add photo progression tracking
- [ ] Write tests

**Files:**
- `lib/features/ai_predictions/models/growth_stage_prediction.dart`
- `lib/features/ai_predictions/data/growth_stage_repository.dart`
- `lib/features/ai_predictions/screens/growth_stage_screen.dart`

**Status:** 🔴 Not Started
**Effort:** 40 story points

### Phase 5: Integration & Polish
- [ ] Integrate all 3 models with Epic 1 data
- [ ] Update routing with new screens
- [ ] Add recommendations to home screen
- [ ] Write integration tests (20+ tests)
- [ ] Performance optimization
- [ ] Code review and bug fixes

**Status:** 🔴 Not Started
**Effort:** 30 story points

---

## 📐 Data Models

### DiseasePredict
```dart
class DiseasePrediction {
  final String diseaseName;
  final double confidence;
  final String severity;          // Low, Medium, High, Critical
  final List<String> treatments;   // Recommended actions
  final DateTime detectionTime;
  final String? farmId;
  final String? photoPath;
  
  // Serialization methods
}
```

### YieldPredict
```dart
class YieldPrediction {
  final double estimatedYield;      // kg/hectare
  final double lowerBound;          // 95% CI lower
  final double upperBound;          // 95% CI upper
  final double confidence;
  final List<String> riskFactors;   // What could reduce yield
  final List<String> opportunities; // What could increase yield
  final DateTime predictionTime;
  final String? farmId;
  
  // Serialization methods
}
```

### GrowthStagePrediction
```dart
class GrowthStagePrediction {
  final GrowthStage currentStage;
  final double daysInStage;
  final double daysToNextStage;
  final List<String> recommendations;
  final Map<String, dynamic> stageMetrics;
  final DateTime predictionTime;
  final String? farmId;
  
  // Serialization methods
}

enum GrowthStage {
  seedling,     // 0-2 weeks
  vegetative,   // 3-8 weeks
  flowering,    // 9-12 weeks
  fruitGrain,   // 13-18 weeks
  mature,       // 19-24 weeks
  harvestReady  // 25+ weeks
}
```

---

## 🧪 Testing Strategy

### Unit Tests (40+ tests)
- **ML Service Tests:** Model loading, preprocessing, inference
- **Model Tests:** Serialization, validation
- **Repository Tests:** CRUD operations, caching
- **Utility Tests:** Feature engineering, calculations

### Integration Tests (20+ tests)
- Farm → Disease Detection flow
- Weather + Farm → Yield Prediction flow
- Multi-prediction scenarios
- Error handling & edge cases
- Performance benchmarks

### Test Coverage Target
- Business Logic: 90%+
- UI Logic: 60%+
- Overall: 70%+

---

## 🚀 Deployment Checklist

Before merging to main:
- [ ] All 60+ tests passing (100% pass rate)
- [ ] No linting warnings/errors
- [ ] Performance benchmarks met (<500ms for inference)
- [ ] Models size within budget (<25 MB total)
- [ ] Offline functionality verified
- [ ] Error handling for all edge cases
- [ ] Documentation complete
- [ ] Code review passed

---

## 📚 Resources & References

### TensorFlow Lite
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [TFLite Model Optimization](https://www.tensorflow.org/lite/performance/model_optimization)
- [TFLite iOS/Android Setup](https://www.tensorflow.org/lite/guide/android)

### ML Datasets
- [PlantVillage Dataset](https://plantvillage.psu.edu/)
- [Kaggle Crop Diseases](https://www.kaggle.com/search?q=crop+disease)
- [FAO Agricultural Data](http://www.fao.org/faostat/)

### Image Processing
- [Flutter Image Package](https://pub.dev/packages/image)
- [Image Preprocessing Best Practices](https://www.tensorflow.org/lite/guide/python_interpreter)

---

## 🔗 Related Epics

- **Epic 1:** Farm Monitoring (dependencies: farm data, weather)
- **Epic 3:** Firebase Integration (will sync predictions)
- **Epic 4:** Analytics Dashboard (will visualize predictions)
- **Epic 5:** Notifications (will alert based on predictions)

---

## 👥 Team & Responsibilities

| Role | Responsibility | Timeline |
|------|-----------------|----------|
| ML Engineer | Model integration, optimization, testing | Weeks 1-3 |
| Backend Engineer | Repository layer, caching, sync prep | Weeks 1-2 |
| Frontend Engineer | Screens, UI/UX, visualization | Weeks 1-3 |
| QA Engineer | Test automation, performance validation | Weeks 1-3 |

---

## 📊 Success Metrics

### Technical Metrics
- [ ] Inference time: <500ms for disease, <100ms for yield, <300ms for growth
- [ ] Model accuracy: >85% for disease, >85% R² for yield, >90% for growth
- [ ] Test coverage: >70%
- [ ] Zero crashes in production

### User Metrics
- [ ] 10,000+ disease detections in first month
- [ ] 50%+ adoption of yield forecast feature
- [ ] 80%+ user satisfaction with recommendations
- [ ] <100ms UI response time perceived by users

---

## 📅 Timeline

| Week | Phase | Deliverable |
|------|-------|------------|
| 1-2 | Disease Detection | Fully functional disease detection with UI |
| 2-3 | Yield Forecasting | Yield predictions with historical analysis |
| 3 | Growth Stage | Growth stage classification with timeline |
| 3-4 | Testing & Polish | 60+ tests, documentation, bug fixes |
| 4 | Integration | Merge to develop, prepare for main |

---

**Document Version:** 1.0  
**Status:** APPROVED  
**Created:** December 9, 2025  
**Owner:** Engineering Lead
