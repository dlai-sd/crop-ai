# Mobile App Development Setup Guide

**Last Updated:** December 9, 2025  
**Status:** ✅ Infrastructure Ready for Development  
**Development Start:** Week 1 (Epic 1: Crop Monitoring)

---

## Quick Start (15 minutes)

```bash
# 1. Navigate to mobile app folder
cd /workspaces/crop-ai/mobile

# 2. Install dependencies
flutter pub get

# 3. Run linting
flutter analyze

# 4. Run all tests
flutter test

# 5. Build for testing
flutter build apk --debug    # Android debug APK
flutter build ios --debug    # iOS debug build
```

---

## Project Overview

**Location:** `/workspaces/crop-ai/mobile/`

**Tech Stack:**
- Framework: Flutter (Dart)
- Platform: iOS 15+, Android 13+
- State Management: Riverpod
- Offline Storage: Drift + SQLite
- Real-time: Firebase
- ML: TensorFlow Lite

**Team Size:** 2 Flutter devs + 1 Backend dev (part-time) + 1 DevOps

---

## CI/CD Pipeline Overview

### 1. `mobile-ci.yml` - Runs on Every Commit
**When:** Push to main/develop branches
**What It Does:**
- ✅ Code analysis (`flutter analyze`)
- ✅ Format checking (`dart format`)
- ✅ Unit tests with coverage (target: 80%)
- ✅ Widget tests for critical screens
- ✅ Security scanning (dependency audit, secret detection)
- ✅ SonarQube code quality analysis
- ✅ Coverage reports to Codecov

**Success Criteria:**
- All jobs pass (green checkmarks)
- Coverage ≥ 80%
- No security vulnerabilities (critical/high)
- No lint errors

### 2. `mobile-build.yml` - Builds Artifacts
**When:** Main branch after CI passes
**What It Produces:**
- Android APK (testing)
- Android AAB (Play Store)
- iOS IPA (TestFlight)

**Artifacts:** Uploaded to GitHub Actions for download

---

## Environment Setup (First Time Only)

### Prerequisites
- macOS or Linux
- 15GB disk space minimum
- 8GB RAM recommended

### 1. Install Flutter SDK

```bash
# Download Flutter
git clone https://github.com/flutter/flutter.git --branch stable

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$PATH:~/flutter/bin"

# Verify installation
flutter doctor

# Resolve issues (follow flutter doctor output)
flutter doctor --android-licenses
```

### 2. Install Android Studio (for Android development)

```bash
# macOS
brew install android-studio

# Linux
# Download from https://developer.android.com/studio

# Setup SDK
# Open Android Studio → SDK Manager → Install:
#   - Android SDK 33, 34
#   - Android SDK Build Tools 34.0.0
#   - Android SDK Platform-Tools
```

### 3. Setup iOS Development (macOS only)

```bash
# Install Xcode
xcode-select --install

# Install CocoaPods
sudo gem install cocoapods

# Accept Xcode license
sudo xcodebuild -license accept
```

### 4. Install VS Code Extensions

```
Flutter, Dart, Riverpod Snippets, Pubspec Assist
```

---

## Development Workflow

### Day 1: Setup
1. Clone repo
2. Run `flutter doctor`
3. Setup IDE (VS Code or Android Studio)
4. Create emulator/simulator
5. Run `flutter pub get` in mobile folder

### Daily Development
```bash
# Start dev server (hot reload)
cd mobile
flutter run

# Run tests after changes
flutter test

# Check linting
flutter analyze

# Format code
dart format .
```

### Before Committing
```bash
# 1. Format
dart format .

# 2. Lint
flutter analyze

# 3. Test
flutter test

# 4. Check coverage
flutter test --coverage

# 5. Commit
git add .
git commit -m "feature: description"
git push origin branch-name
```

---

## Code Quality Standards

### Linting Rules (60+ rules enforced)
See `mobile/analysis_options.yaml` for complete list.

**Examples:**
- ✅ Always declare return types
- ✅ Avoid null checks in constructors
- ✅ Prefer const constructors
- ✅ Use final fields
- ❌ Avoid printing
- ❌ Avoid returning null

### Test Coverage Targets
```
Models:        100% (data structures)
Services:      90%  (API, storage, sync)
Providers:     85%  (state management)
Utilities:     90%  (helpers)
Screens:       60%  (UI is hard to test)
```

### Test Structure (Arrange-Act-Assert)
```dart
test('farm list loads from API', () {
  // Arrange: setup data
  final mockFarms = [Farm(...), Farm(...)];
  when(mockApi.getFarms()).thenAnswer((_) async => mockFarms);
  
  // Act: perform action
  final result = await farmProvider.fetchFarms();
  
  // Assert: verify result
  expect(result, equals(mockFarms));
});
```

---

## Folder Structure

```
mobile/
├── lib/
│   ├── screens/              # Screen widgets (one per feature)
│   │   ├── farm_list_screen.dart
│   │   ├── farm_details_screen.dart
│   │   └── ...
│   ├── widgets/              # Reusable components
│   │   ├── farm_card.dart
│   │   ├── risk_card.dart
│   │   └── ...
│   ├── services/             # Business logic
│   │   ├── api_service.dart
│   │   ├── storage_service.dart
│   │   └── ...
│   ├── providers/            # State management (Riverpod)
│   │   ├── farm_provider.dart
│   │   └── ...
│   ├── models/               # Data models
│   │   ├── farm.dart
│   │   ├── prediction.dart
│   │   └── ...
│   ├── utils/                # Utilities
│   ├── theme/                # Colors, typography, theme
│   ├── main.dart             # App entry point
│   └── app.dart              # Main app widget
│
├── test/
│   ├── unit/                 # Unit tests
│   ├── widget/               # Widget tests
│   └── fixtures/             # Mock data
│
├── integration_test/         # End-to-end tests
│
├── ios/                      # iOS platform code
├── android/                  # Android platform code
│
├── pubspec.yaml              # Dependencies
├── analysis_options.yaml     # Linting config
└── README.md                 # This file
```

---

## Common Commands

```bash
# Get dependencies
flutter pub get
flutter pub upgrade

# Run app
flutter run                         # Debug on connected device
flutter run -d chrome              # Web browser
flutter run --profile              # Profiling mode

# Testing
flutter test                        # All tests
flutter test test/unit/            # Specific folder
flutter test --tags widget         # Tagged tests
flutter test --coverage            # With coverage

# Analysis
flutter analyze                     # Lint check
dart format .                       # Auto-format
dart fix --apply                   # Auto-fix issues

# Building
flutter build apk --release        # Android release APK
flutter build appbundle --release  # Android Play Store AAB
flutter build ios --release        # iOS release build
flutter build ipa --release        # iOS TestFlight build

# Debugging
flutter logs                        # Real-time logs
flutter devtools                   # DevTools UI
flutter run --verbose              # Verbose output
```

---

## GitHub Secrets Setup

Ask DevOps/Tech Lead to configure these in GitHub:

```
ANDROID_SERVICE_ACCOUNT_JSON    # Play Store API credentials
APPSTORE_ISSUER_ID              # Apple Developer credentials
APPSTORE_API_KEY_ID             # Apple Developer credentials
APPSTORE_API_PRIVATE_KEY        # Apple Developer credentials
SONAR_TOKEN                      # SonarQube token
```

---

## Firebase Setup (Shared Backend)

1. **Firebase Authentication**
   - Enable email/password + phone auth
   - Configure allowed domains

2. **Firebase Realtime Database**
   - Setup `/chaupal` (community feed)
   - Setup `/messages` (messaging)
   - Configure security rules

3. **Firebase Cloud Messaging**
   - Generate server key
   - Configure APNs certificate (iOS)

4. **Firebase Analytics**
   - Track user behavior
   - Monitor crash rates

---

## Release Process

### Step 1: Increment Version
Edit `pubspec.yaml`:
```yaml
version: 1.0.0+100    # Major.Minor.Patch+Build
```

### Step 2: Commit & Tag
```bash
git add pubspec.yaml
git commit -m "chore: bump version to 1.0.0"
git tag v1.0.0
git push && git push --tags
```

### Step 3: CI/CD Builds Artifacts
GitHub Actions automatically builds:
- Android: APK + AAB
- iOS: IPA

### Step 4: Manual Deployment (Trigger Workflow)
```
GitHub → Actions → Manual Deploy Workflow
→ Select version & environment (testflight / play-store-beta / production)
→ Workflow uploads to app stores
```

---

## Troubleshooting

### "flutter: command not found"
```bash
echo 'export PATH="$PATH:~/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### "Android SDK not found"
```bash
flutter config --android-sdk /path/to/android-sdk
```

### "Pod install fails"
```bash
cd ios
rm -rf Pods Podfile.lock
flutter clean
flutter pub get
cd ..
flutter run
```

### "Coverage below 80%"
```bash
# Check coverage report
cd mobile
flutter test --coverage
open coverage/index.html    # macOS
firefox coverage/index.html # Linux
```

### "SonarQube analysis fails"
- Check SONAR_TOKEN is configured in GitHub
- Verify branch is main or develop
- Check coverage report exists

---

## Useful Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Dart Docs:** https://dart.dev/guides
- **Riverpod Docs:** https://riverpod.dev
- **Firebase Flutter:** https://firebase.flutter.dev
- **SonarQube Dashboard:** https://sonarcloud.io/organizations/dlai-sd

---

## Quick Reference: CI/CD Checks Before Committing

```bash
#!/bin/bash
# Run this script before git push

cd mobile

echo "🔍 Running linting..."
flutter analyze || { echo "❌ Linting failed"; exit 1; }

echo "📝 Checking formatting..."
dart format --set-exit-if-changed . || { echo "❌ Formatting needed"; exit 1; }

echo "✅ Running tests..."
flutter test || { echo "❌ Tests failed"; exit 1; }

echo "📊 Checking coverage..."
flutter test --coverage > /dev/null 2>&1
COVERAGE=$(grep -oP 'LF:\K\d+' coverage/lcov.info | head -1)
if [ $(( COVERAGE * 100 / LINES )) -lt 80 ]; then
  echo "⚠️  Coverage below 80%"
fi

echo "✨ All checks passed! Ready to commit."
```

---

## Getting Help

**Slack Channel:** #mobile-dev-team  
**Tech Lead:** (assign name)  
**DevOps Lead:** (assign name)

**Common Issues:**
- Ask in #mobile-dev-team first
- Check GitHub Issues for similar problems
- Contact Tech Lead if stuck

---

## Next Steps

1. ✅ Clone repo & install Flutter SDK
2. ✅ Run `flutter doctor` and resolve issues
3. ✅ Create Android emulator / iOS simulator
4. ✅ Run `flutter pub get` in mobile folder
5. ✅ Run `flutter test` to verify setup
6. 🎯 Start Epic 1 (Crop Monitoring) development

---

**Welcome to the mobile dev team! 🚀**

