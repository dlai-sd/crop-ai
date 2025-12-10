# Mobile App Setup & Build Guide

## ✅ Infrastructure Complete

All infrastructure is in place and pushed to GitHub. This guide walks through:
1. Local development setup
2. Building APK locally
3. Deploying to Play Store

---

## Phase 1: Local Development (Current)

### Prerequisites

- Flutter 3.24.0 (installed via Dockerfile or local)
- Dart 3.4.0 (comes with Flutter)
- Android SDK (API 30-34)
- Java 17

### Setup Development Environment

```bash
# 1. Navigate to mobile directory
cd /workspaces/crop-ai/mobile

# 2. Get dependencies
flutter pub get

# 3. Code generation (Drift database)
dart run build_runner build

# 4. Code generation (Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 5. Verify setup
flutter doctor -v
```

### Run Tests Locally

```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Check coverage
flutter test --coverage
```

### Build APK Locally

```bash
# Debug build (faster, for testing)
flutter build apk --debug

# Release build (for production)
flutter build apk --release --split-per-abi

# Verify APK
ls -lh build/app/outputs/flutter-apk/
```

---

## Phase 2: Backend Integration

### Connect to Your Backend

Edit `lib/providers/app_providers.dart`:

```dart
final apiServiceProvider = Provider<ApiService>((ref) {
  final httpClient = ref.watch(authHttpClientProvider);
  return ApiService(
    httpClient: httpClient,
    baseUrl: 'http://your-backend.com:8000',  // Change this
  );
});
```

### Add Google OAuth Credentials

**Step 1: Create Google Cloud Project**
- Go to https://console.cloud.google.com
- Create new project: "DLAI Crop"
- Enable Google Sign-In API

**Step 2: Create OAuth Credentials**
- Go to Credentials → Create OAuth 2.0 Client ID
- Application type: **Android**
- Package name: `com.dlai.crop`
- SHA-1 fingerprint: Get from your keystore
- Create credentials

**Step 3: Update Environment Variables**

```bash
# In GitHub secrets or local .env:
GOOGLE_CLIENT_ID=xxxxx-xxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=xxxxx
```

### Add Firebase

**Step 1: Create Firebase Project**
- Go to https://console.firebase.google.com
- Create project: "DLAI Crop"
- Add Android app
- Package name: `com.dlai.crop`
- Download `google-services.json`

**Step 2: Add to Android**
```bash
cp google-services.json mobile/android/app/
```

**Step 3: Update Configuration**
- Firebase API Key
- Project ID
- Messaging Sender ID

---

## Phase 3: APK Build & Distribution

### Manual APK Build (No CI/CD)

```bash
cd mobile

# Clean previous builds
flutter clean

# Get fresh dependencies
flutter pub get

# Build APK
flutter build apk --release --split-per-abi --target-platform android-arm64

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Automated Build via GitHub Actions

**Option A: Trigger CI/CD Pipeline**

```bash
# Push to main automatically triggers:
git add .
git commit -m "feature: new feature"
git push origin main

# GitHub Actions will:
# 1. Run lint & tests
# 2. Build APK
# 3. Upload APK as artifact
```

**Option B: Manual Workflow Trigger**

```bash
# In GitHub web UI:
# 1. Go to Actions → Mobile Build & Distribute
# 2. Click "Run workflow"
# 3. Select "Upload to Play Store internal testing"
# 4. Wait for completion
```

---

## Phase 4: Play Store Setup (When Ready)

### Prerequisites

1. **Google Play Developer Account**
   - Cost: $25 (one-time)
   - Go to https://play.google.com/console

2. **App Signing Key**
   - Generate or use existing keystore
   - Store securely in GitHub secrets

3. **Service Account Credentials**
   - Create in Google Cloud Console
   - Download JSON key
   - Store in GitHub secrets: `PLAY_STORE_SERVICE_ACCOUNT`

### Setup Steps

```bash
# 1. Create keystore (one-time)
keytool -genkey -v -keystore android/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias dlai-crop

# 2. Store in GitHub secrets
# ANDROID_KEYSTORE_BASE64 = base64 of keystore.jks
# ANDROID_KEYSTORE_PASSWORD = keystore password
# ANDROID_KEY_ALIAS = dlai-crop
# ANDROID_KEY_PASSWORD = key password

# 3. Create App in Play Console
# - App name: DLAI Crop
# - Package name: com.dlai.crop
# - Category: Agriculture/Lifestyle

# 4. Create signed APK
flutter build apk --release --split-per-abi \
  -P com.android.tools.build.gradle:enableProfiler=false

# 5. Upload via Play Console or fastlane
```

### Automated Play Store Upload

Once setup, the workflow handles everything:

```bash
# Manual trigger in GitHub Actions
# → Builds APK/AAB
# → Signs with keystore
# → Uploads to Play Store internal testing
# → Creates GitHub release
```

---

## Troubleshooting

### Issue: "Flutter not found"
```bash
# Solution: Install Flutter in Codespace
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz | tar -x
export PATH="$PATH:$PWD/flutter/bin"
flutter doctor
```

### Issue: "Gradle build fails"
```bash
# Solution: Clean and rebuild
flutter clean
rm -rf build/
rm -rf android/.gradle/
flutter pub get
flutter build apk --release
```

### Issue: "Android SDK not found"
```bash
# Solution: Install in Dockerfile
# The Dockerfile.mobile handles this automatically
docker build -f Dockerfile.mobile -t dlai-crop:latest .
```

### Issue: "Code generation failed"
```bash
# Solution: Run build_runner again
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

---

## Current State Summary

✅ **Complete:**
- Flutter project structure
- Riverpod state management
- Drift database models
- API service layer
- Auth system (JWT secure storage)
- Material 3 UI theme
- Login screen (SSO ready)
- Farm list screen
- GitHub Actions CI/CD
- Android configuration
- Documentation

⏳ **Ready for:**
- Connect to your backend
- Add Google OAuth credentials
- Add Firebase credentials
- Build and test locally
- Deploy to Play Store

❌ **Not Yet:**
- iOS support (Phase 2)
- Real OAuth integration (placeholder UI)
- Firebase setup (configuration ready)
- Photo uploads (Phase 2)
- Video support (Phase 3)

---

## Quick Start Commands

```bash
# Get started
cd /workspaces/crop-ai/mobile
flutter pub get
dart run build_runner build

# Run locally (if emulator available)
flutter run

# Build APK
flutter build apk --release --split-per-abi

# Push to GitHub (triggers CI/CD)
git add . && git commit -m "..." && git push origin main

# Check CI/CD status
# → Go to GitHub repo → Actions tab
```

---

## Architecture Review

```
DLAI Crop Mobile App
├── Authentication
│   ├── SSO (Google, Microsoft, Facebook)
│   ├── JWT token storage (encrypted)
│   └── 401 logout flow
│
├── Data Management
│   ├── Drift SQLite (offline-first)
│   ├── Riverpod providers (state)
│   └── API service (backend integration)
│
├── UI
│   ├── Login screen (SSO + credentials)
│   ├── Farm list (with offline indicator)
│   └── Material Design 3 theme
│
└── Infrastructure
    ├── GitHub Actions CI/CD
    ├── Android build configuration
    └── Play Store integration ready
```

---

## Next Phase Checklist

**When ready to launch to Play Store:**

- [ ] Create Google Play Developer account
- [ ] Generate Android signing key
- [ ] Setup Google OAuth credentials
- [ ] Setup Firebase project
- [ ] Create app listing in Play Console
- [ ] Add app screenshots & description
- [ ] Update backend URL in code
- [ ] Test locally with actual backend
- [ ] Build signed APK/AAB
- [ ] Upload to internal testing track
- [ ] Test on real Android devices
- [ ] Submit for review (if public)

---

**Infrastructure built:** December 10, 2025
**Ready for deployment:** When credentials added
**Estimated time to Play Store:** 2-3 hours after credential setup
