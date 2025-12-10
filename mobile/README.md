# Mobile App Project Structure

```
mobile/
├─ lib/                          # Dart application source code
│  ├─ screens/                   # Screen/page widgets
│  ├─ widgets/                   # Reusable widget components
│  ├─ services/                  # Business logic (API, storage, sync)
│  ├─ providers/                 # Riverpod state management
│  ├─ models/                    # Data models
│  ├─ utils/                     # Utilities and helpers
│  ├─ constants/                 # App constants
│  ├─ theme/                     # UI theme, colors, typography
│  ├─ main.dart                  # App entry point
│  └─ app.dart                   # Main app widget
│
├─ test/                         # Unit & Widget tests
│  ├─ unit/                      # Unit tests for services/providers
│  ├─ widget/                    # Widget tests for screens
│  └─ fixtures/                  # Test data and mocks
│
├─ integration_test/             # Integration tests
│  ├─ farm_monitoring_test.dart
│  ├─ predictions_test.dart
│  ├─ community_test.dart
│  └─ marketplace_test.dart
│
├─ ios/                          # iOS-specific code
│  ├─ Runner/                    # iOS app configuration
│  ├─ Runner.xcworkspace/        # Xcode workspace
│  └─ Podfile                    # iOS dependencies
│
├─ android/                      # Android-specific code
│  ├─ app/                       # Android app module
│  ├─ gradle/                    # Gradle build configuration
│  └─ build.gradle               # Top-level Gradle config
│
├─ web/                          # Web build (optional)
├─ windows/                      # Windows build (optional)
├─ macos/                        # macOS build (optional)
│
├─ assets/
│  ├─ images/                    # PNG, SVG images
│  ├─ models/                    # ML models (TF Lite)
│  ├─ translations/              # Localization files
│  └─ fonts/                     # Custom fonts
│
├─ build/                        # Build output (git-ignored)
├─ .dart_tool/                   # Dart tool cache (git-ignored)
│
├─ pubspec.yaml                  # Flutter dependencies & metadata
├─ pubspec.lock                  # Locked dependency versions
├─ analysis_options.yaml         # Linting & analyzer configuration
├─ .gitignore                    # Git ignore rules
│
└─ README.md                     # Project documentation
```

## Key Directories

### `lib/screens/`
Screen-level widgets for each feature:
- `farm_list_screen.dart`
- `farm_details_screen.dart`
- `prediction_screen.dart`
- `chaupal_feed_screen.dart`
- etc.

### `lib/widgets/`
Reusable UI components:
- `farm_card.dart`
- `risk_card.dart`
- `badge_card.dart`
- `offline_notice.dart`
- etc.

### `lib/services/`
Business logic & API integration:
- `api_service.dart` - HTTP requests to backend
- `storage_service.dart` - SQLite offline storage
- `sync_service.dart` - Online/offline sync
- `location_service.dart` - GPS & geolocation
- etc.

### `lib/providers/`
Riverpod state management:
- `farm_provider.dart` - Farm data state
- `connectivity_provider.dart` - Online/offline state
- `gamification_provider.dart` - Badge/level state
- etc.

### `lib/models/`
Data models & serialization:
- `farm_model.dart`
- `prediction_model.dart`
- `user_model.dart`
- etc.

### `test/`
Testing suite:
- Unit tests for services (target: 90%)
- Widget tests for critical screens (target: 60%)
- Integration tests for user flows

### `integration_test/`
End-to-end user journey tests
# Mobile App Build - Fresh Run
