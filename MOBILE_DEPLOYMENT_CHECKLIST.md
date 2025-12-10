# DLAI Crop Mobile - Deployment Checklist

## ✅ Infrastructure-First: COMPLETE

Your mobile infrastructure is 100% ready. This checklist guides you through deployment.

---

## Phase 1: Pre-Deployment (Today - 1 hour)

### Google OAuth Setup
- [ ] Go to https://console.cloud.google.com
- [ ] Create project: "DLAI Crop"
- [ ] Enable "Google Sign-In" API
- [ ] Create OAuth 2.0 credentials (Android)
- [ ] Package name: `com.dlai.crop`
- [ ] Get SHA-1 from keystore: `keytool -list -v -keystore android/keystore.jks`
- [ ] Save `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`

### Firebase Setup
- [ ] Go to https://console.firebase.google.com
- [ ] Create project: "DLAI Crop"
- [ ] Add Android app
- [ ] Package: `com.dlai.crop`
- [ ] Download `google-services.json` → `mobile/android/app/`
- [ ] Save `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_MESSAGING_SENDER_ID`

### GitHub Secrets (CI/CD)
- [ ] Go to GitHub repo → Settings → Secrets
- [ ] Add `GOOGLE_CLIENT_ID`
- [ ] Add `GOOGLE_CLIENT_SECRET`
- [ ] Add `FIREBASE_PROJECT_ID`
- [ ] Add `FIREBASE_API_KEY`

---

## Phase 2: Local Testing (2 hours)

### Code Generation
```bash
cd /workspaces/crop-ai/mobile

# Generate Drift database code
dart run build_runner build

# Generate Riverpod providers
dart run build_runner build --delete-conflicting-outputs
```
- [ ] All code generation successful
- [ ] No build errors
- [ ] `lib/database/app_database.g.dart` exists
- [ ] `lib/providers/app_providers.g.dart` exists

### Update Backend URL
- [ ] Edit `lib/providers/app_providers.dart`
- [ ] Change `baseUrl` to your backend:
  ```dart
  baseUrl: 'http://your-backend-url:8000'
  ```

### Test Code Quality
```bash
# Analyze
flutter analyze

# Format
dart format lib/

# Tests
flutter test
```
- [ ] No analysis issues
- [ ] Code properly formatted
- [ ] All tests pass

### Build APK
```bash
# Clean
flutter clean

# Build
flutter build apk --release --split-per-abi

# Verify
ls -lh build/app/outputs/flutter-apk/
```
- [ ] APK built successfully
- [ ] File size ~50-80MB
- [ ] No build warnings (except expected Flutter ones)

---

## Phase 3: GitHub Actions Testing (30 min)

### Push to GitHub (Triggers CI)
```bash
git add .
git commit -m "chore: update backend config and secrets"
git push origin main
```

### Monitor CI/CD
- [ ] Go to GitHub repo → Actions
- [ ] Watch `Mobile CI` workflow
- [ ] Lint step passes
- [ ] Test step passes (if written)
- [ ] Build APK step passes
- [ ] APK uploaded as artifact

### Download & Test APK
- [ ] Download APK from workflow artifacts
- [ ] Transfer to Android phone
- [ ] Install: `adb install app-release.apk`
- [ ] Run app
- [ ] Test login screen (SSO placeholder)
- [ ] Test farm list screen
- [ ] Verify app doesn't crash

---

## Phase 4: Real Backend Testing (1 hour)

### Connect to Your API
- [ ] Backend running on port 5000 (FastAPI)
- [ ] Django Gateway on port 8000
- [ ] Both services healthy
- [ ] CORS configured for mobile requests

### Test API Calls
- [ ] Login endpoint returns JWT ✅
- [ ] Farms endpoint returns list ✅
- [ ] Conversations endpoint works ✅
- [ ] Health check passes ✅

### Implement Real OAuth (Optional)
- [ ] Install Google Sign-In plugin: `google_sign_in: ^6.2.1`
- [ ] Implement `loginWithSSO()` in login_screen.dart
- [ ] Test actual Google login flow
- [ ] Verify JWT received from backend

### Test Offline Sync
- [ ] Load farm data
- [ ] Turn off network (flight mode)
- [ ] Verify cached data shows
- [ ] Turn network back on
- [ ] Verify sync indicator appears & disappears

---

## Phase 5: Play Store Setup (When Ready - 2 hours)

### Create Developer Accounts
- [ ] Google Play Developer Account ($25)
- [ ] Save billing info
- [ ] Agree to terms

### Create Android Signing Key
```bash
# Generate keystore
keytool -genkey -v -keystore android/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias dlai-crop \
  -keypass your-key-password \
  -storepass your-store-password
```
- [ ] Keystore created
- [ ] Save passwords securely
- [ ] Add to GitHub secrets:
  - `ANDROID_KEYSTORE_BASE64` (base64 of .jks file)
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`

### Create App in Play Console
- [ ] Go to https://play.google.com/console
- [ ] Create new app
- [ ] App name: "DLAI Crop"
- [ ] Package name: `com.dlai.crop`
- [ ] Category: Agriculture/Lifestyle
- [ ] Content rating: Fill questionnaire
- [ ] Privacy policy: Create one (required)

### Build Signed APK
```bash
# Configure signing in android/key.properties
cd mobile
flutter build appbundle --release \
  -P com.android.tools.build.gradle:enableProfiler=false
```
- [ ] Signed APK built
- [ ] File: `build/app/outputs/bundle/release/app-release.aab`

### Upload to Internal Testing
- [ ] Go to Play Console → Internal testing
- [ ] Upload AAB file
- [ ] Fill app details:
  - [ ] Screenshots (minimum 2)
  - [ ] Description
  - [ ] Changelog: "Initial alpha release"
  - [ ] Content rating
  - [ ] Permissions justification
- [ ] Create tester group
- [ ] Add tester email addresses
- [ ] Share internal testing link with team

### Test on Real Devices
- [ ] Download app from Play Store internal link
- [ ] Install on various Android devices
- [ ] Test on:
  - [ ] Android 12 (Samsung)
  - [ ] Android 13 (Pixel)
  - [ ] Android 14 (Latest)
- [ ] Verify all features work
- [ ] Check screen rotation
- [ ] Test offline functionality

---

## Phase 6: Public Release (Optional - When Confident)

### Prepare for Review
- [ ] Write comprehensive app description
- [ ] Add 5+ high-quality screenshots
- [ ] Create promotional graphic
- [ ] Fill all store listing fields
- [ ] Set pricing (Free)
- [ ] Choose distribution countries (India first)

### Submit for Review
- [ ] Go to Play Console → Production track
- [ ] Upload signed APK/AAB
- [ ] Review all details
- [ ] Click "Submit for review"
- [ ] Wait for Google approval (~1-2 days)

### Post-Launch
- [ ] Monitor crash reports
- [ ] Read user reviews
- [ ] Fix bugs in Phase 2 updates
- [ ] Plan new features

---

## Quick Reference

| Step | Time | When Ready? |
|------|------|------------|
| Credentials (Google + Firebase) | 30 min | ✅ Now |
| Local testing & build | 1.5 hours | ✅ Now |
| CI/CD verification | 30 min | ✅ Now |
| Backend integration | 1 hour | ✅ If backend ready |
| Play Store setup | 2 hours | ⏳ When launching |
| Internal testing | 1 hour | ⏳ When launching |
| Public release | 2-3 days | ⏳ When confident |

**Total time to internal testing:** 4-5 hours

---

## Success Criteria

✅ **MVP Success:**
- [ ] App builds without errors
- [ ] Launches on Android device
- [ ] Login screen shows
- [ ] Farm list loads (connected to backend)
- [ ] Offline indicator works
- [ ] No crashes after 5 min of usage

✅ **Play Store Success:**
- [ ] APK uploaded to internal testing
- [ ] Tester can download & install
- [ ] App runs without crashes
- [ ] All screens accessible

✅ **Public Release Success:**
- [ ] Approved by Google (1-2 days)
- [ ] Available in Play Store
- [ ] Positive reviews coming in
- [ ] No critical bugs reported

---

## Troubleshooting Quick Guide

**Issue:** `flutter: not found`
```bash
# Solution: Add to PATH
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor
```

**Issue:** `Gradle build fails`
```bash
flutter clean
rm -rf build android/.gradle
flutter pub get
flutter build apk --release
```

**Issue:** `Code generation failed`
```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

**Issue:** `APK won't install`
- Uninstall previous version first
- Check package name matches (com.dlai.crop)
- Verify minSdkVersion=21

**Issue:** `Backend connection fails`
- Check `baseUrl` in lib/providers/app_providers.dart
- Verify backend is running
- Check CORS headers
- Look at network tab in Chrome DevTools

---

## Files to Keep Handy

1. `mobile/README.md` - Architecture overview
2. `MOBILE_SETUP_GUIDE.md` - Detailed setup
3. `MOBILE_INFRASTRUCTURE_COMPLETE.md` - This file
4. `.github/workflows/mobile-ci.yml` - CI/CD workflow
5. `mobile/lib/providers/app_providers.dart` - Config file

---

## Next Actions

### Immediately:
1. [ ] Set up Google OAuth credentials (30 min)
2. [ ] Set up Firebase project (15 min)
3. [ ] Add GitHub secrets (5 min)
4. [ ] Run `flutter build apk --release` locally (5 min)
5. [ ] Test APK on device (15 min)

### When Backend Ready:
1. [ ] Update backend URL
2. [ ] Test login flow
3. [ ] Test farm data loading
4. [ ] Test offline sync

### When Launching:
1. [ ] Create Play Store account
2. [ ] Create app listing
3. [ ] Upload to internal testing
4. [ ] Share with testers
5. [ ] Gather feedback & fix

---

## Support

- **Documentation:** See `mobile/README.md`
- **API Integration:** See `lib/services/api_service.dart`
- **State Management:** See `lib/providers/app_providers.dart`
- **Database:** See `lib/database/app_database.dart`

---

**Status:** Ready to Deploy ✨  
**Infrastructure-First:** Complete ✅  
**Next Step:** Add credentials & build locally  
**Estimated Time to Play Store:** 2-3 hours  

Good luck! 🚀
