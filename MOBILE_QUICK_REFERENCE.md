# Mobile App - Quick Reference Card

**Print or bookmark this page**

---

## Essential Commands

### Setup
```bash
cd /workspaces/crop-ai/mobile
flutter pub get
```

### Code Generation (Critical)
```bash
dart run build_runner build
# If conflicts:
dart run build_runner build --delete-conflicting-outputs
```

### Analysis & Testing
```bash
flutter analyze              # Check for code issues
flutter test                 # Run unit tests
flutter test -v              # Verbose test output
```

### Build
```bash
flutter build apk --release  # Production APK
flutter build apk --debug    # Debug APK (faster)
flutter build apk --profile  # Performance testing
```

### Clean Build
```bash
flutter clean
flutter pub get
dart run build_runner build
```

### Debug
```bash
flutter run                  # Run on connected device
flutter run -v               # Verbose output
flutter run --release        # Release mode
```

---

## File Locations

| What | Where |
|------|-------|
| Entry Point | `mobile/lib/main.dart` |
| Providers | `mobile/lib/providers/app_providers.dart` |
| API Service | `mobile/lib/services/api_service.dart` |
| Database | `mobile/lib/database/app_database.dart` |
| Login Screen | `mobile/lib/screens/login_screen.dart` |
| Farm List | `mobile/lib/screens/farm_list_screen.dart` |
| Theme | `mobile/lib/theme/app_theme.dart` |
| Android Config | `mobile/android/app/build.gradle` |
| Manifest | `mobile/android/app/src/main/AndroidManifest.xml` |
| Dependencies | `mobile/pubspec.yaml` |

---

## Common Fixes

### Problem: Build fails with "gradle"
```bash
# Solution:
flutter clean
flutter pub get
flutter build apk --release
```

### Problem: Import error "can't find module"
```bash
# Solution:
flutter pub get
flutter pub upgrade
```

### Problem: "dartdoc" or "build_runner" error
```bash
# Solution:
dart run build_runner build --delete-conflicting-outputs
```

### Problem: "No connected devices"
```bash
# Solution:
# 1. Connect Android device via USB
# 2. Enable Developer Mode
# 3. Run: flutter devices
# 4. Run: flutter run
```

### Problem: App crashes on startup
```bash
# Solution:
flutter run -v    # See detailed error
# Check:
# - Is database initialized?
# - Are permissions in manifest?
# - Did code generation complete?
```

---

## Key Files to Remember

🔴 **Don't Delete These:**
- `pubspec.yaml` - Dependencies
- `android/app/build.gradle` - Android config
- `lib/main.dart` - Entry point
- `lib/providers/app_providers.dart` - State management
- `lib/database/app_database.dart` - Database models

🟡 **Can Modify:**
- `lib/screens/` - UI screens
- `lib/theme/app_theme.dart` - Colors, fonts
- `lib/services/` - API, auth

🟢 **Auto-generated (Don't Edit):**
- `lib/database/app_database.g.dart` - Drift ORM
- `lib/providers/app_providers.g.dart` - Riverpod codegen
- `android/` - Gradle builds
- `.dart_tool/` - Build cache

---

## Architecture Quick View

```
User Interface
    ↓
Riverpod Providers (State Management)
    ↓
API Service + Auth HTTP Client (HTTP)
    ↓
Token Storage (JWT Encryption)
    ↓
Backend (Django/FastAPI)
    ↓
PostgreSQL Database

Local Storage:
    ↓
Drift Database (SQLite)
    ↓
Offline-first Sync Queue
```

---

## Testing Checklist

Before committing code, run:

```bash
# 1. Code generation
dart run build_runner build

# 2. Static analysis
flutter analyze

# 3. Unit tests
flutter test

# 4. Build APK
flutter build apk --release

# 5. Check file size
ls -lh build/app/outputs/flutter-app.apk
```

---

## Environment Info

- **Dart:** 3.4.0+
- **Flutter:** 3.24.0+
- **Android Min SDK:** 21 (Android 5.0)
- **Android Target SDK:** 34 (Android 14)
- **Java:** 17+
- **Kotlin:** 1.7+

---

## Documentation Files

| Document | Lines | Purpose |
|----------|-------|---------|
| `mobile/README.md` | ~150 | Architecture overview |
| `MOBILE_SETUP_GUIDE.md` | ~400 | Setup & deployment guide |
| `MOBILE_BUILD_VALIDATION.md` | ~227 | Build validation report |
| `MOBILE_NEXT_ITERATION.md` | ~299 | Iteration checklist |
| `SESSION_BUILD_SUMMARY.md` | ~315 | Session summary |
| `MOBILE_DEPLOYMENT_CHECKLIST.md` | ~250 | Phase-by-phase checklist |

---

## Useful Links

- **Flutter Docs:** https://flutter.dev
- **Riverpod Docs:** https://riverpod.dev
- **Drift Docs:** https://drift.simonbinder.eu
- **Material 3:** https://m3.material.io
- **Android Docs:** https://developer.android.com
- **Dart Docs:** https://dart.dev

---

## Git Workflow

```bash
# Start new feature
git checkout -b feature/name

# Make changes
# Test locally

# Commit
git add .
git commit -m "type: description"

# Push
git push origin feature/name

# Create PR on GitHub
```

**Conventional commits:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `test:` Tests
- `chore:` Maintenance
- `refactor:` Code restructuring

---

## Expected File Sizes

| File | Size | Notes |
|------|------|-------|
| Source Code | ~500 KB | All Dart files |
| pubspec.yaml | ~2 KB | Dependencies |
| APK (debug) | ~80-120 MB | Unoptimized |
| APK (release) | ~30-50 MB | With optimization |
| Database (empty) | ~256 KB | SQLite template |

---

## Status Check

```bash
# Quick health check:
cd /workspaces/crop-ai/mobile

# 1. Dependencies OK?
flutter pub get

# 2. Code generation OK?
dart run build_runner build

# 3. Analysis OK?
flutter analyze

# 4. Tests pass?
flutter test

# 5. Build OK?
flutter build apk --release

echo "All checks passed!" ✅
```

---

## Support Checklist

Before asking for help:
- ✅ Flutter installed? `flutter --version`
- ✅ Dependencies resolved? `flutter pub get`
- ✅ Code generated? Look for `*.g.dart` files
- ✅ Analysis passes? `flutter analyze`
- ✅ Git status clean? `git status`
- ✅ Tried clean build? `flutter clean && flutter pub get`

---

**Last Updated:** December 10, 2025  
**Status:** ✅ Ready for Development  
**Next Phase:** Code Generation
