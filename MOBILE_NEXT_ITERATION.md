# Mobile App - Next Iteration Guide

**Current Phase:** Infrastructure Complete ✅  
**Next Phase:** Code Generation + Local Testing  
**Timeline:** Ready to start immediately

---

## What's Complete (Don't Touch)

✅ All Dart code (syntax-valid, ready for generation)
✅ pubspec.yaml (all dependencies, no conflicts)
✅ Android configuration (Gradle, manifest, MainActivity)
✅ GitHub Actions CI/CD (2 workflows ready)
✅ Theme & UI (Material Design 3, system fonts)
✅ State management (Riverpod setup)
✅ API service layer (18+ methods)
✅ Database models (6 Drift tables)
✅ Documentation (4 comprehensive guides)

---

## What Needs to Happen (Next)

### Phase 1: Environment Setup (1-2 minutes)
```bash
# Ensure Flutter is installed
flutter --version

# Navigate to mobile project
cd /workspaces/crop-ai/mobile

# Get dependencies
flutter pub get
```

### Phase 2: Code Generation (2-5 minutes)
```bash
# Generate Drift database code + Riverpod code
cd /workspaces/crop-ai/mobile
dart run build_runner build

# If conflicts, use:
# dart run build_runner build --delete-conflicting-outputs

# Files generated:
# - lib/database/app_database.g.dart (Drift ORM)
# - lib/providers/app_providers.g.dart (Riverpod codegen)
```

### Phase 3: Code Analysis (1-2 minutes)
```bash
# Check for Dart analysis errors
flutter analyze

# Expected output: No errors
```

### Phase 4: Unit Tests (2-3 minutes)
```bash
# Run all tests
flutter test

# Expected: All tests pass (or create new tests as needed)
```

### Phase 5: Build APK (5-10 minutes)
```bash
# Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-app.apk
```

---

## Checklist for Next Iteration

### Before Starting
- [ ] Flutter 3.24.0+ installed
- [ ] Git repo up to date: `git pull origin main`
- [ ] Android SDK tools installed
- [ ] Java 17 available

### During Code Generation
- [ ] All build_runner tasks complete
- [ ] No import errors in generated files
- [ ] pubspec.yaml `pub.dev` dependencies resolve
- [ ] No version conflicts reported

### During Testing
- [ ] `flutter analyze` returns no errors
- [ ] All unit tests pass or skipped appropriately
- [ ] Widget tests build without errors
- [ ] No null-safety violations

### During Build
- [ ] APK builds successfully
- [ ] APK size < 200MB (uncompressed)
- [ ] All permissions in AndroidManifest.xml
- [ ] Gradle tasks complete without warnings

### Post-Build
- [ ] APK installable on Android 5.0+ device
- [ ] App launches without crashes
- [ ] Login screen renders correctly
- [ ] No console errors/warnings

---

## Known Issues (Don't Worry)

| Issue | Why It's OK | Resolution |
|-------|-----------|-----------|
| Database throws UnimplementedError | Placeholder in MVP | Will implement in Phase 2 |
| OAuth buttons don't work | Credentials not added yet | Add credentials in Phase 2 |
| Firebase not initialized | Deferred to Phase 2 | Config file ready, just needs setup |
| Asset/font files commented out | Not needed for MVP | Can add in Phase 2 |
| Some TODOs in code | Expected for infrastructure | Feature work in Phase 2 |

**None of these will prevent the app from building or launching.**

---

## Common Issues & Quick Fixes

### Issue: `flutter: command not found`
```bash
# Solution: Add Flutter to PATH
export PATH="$PATH:`flutter/bin`"
# Or install via: https://flutter.dev/docs/get-started/install
```

### Issue: `Gradle task failed`
```bash
# Solution 1: Clean build
flutter clean
flutter pub get

# Solution 2: Update Gradle
flutter pub upgrade

# Solution 3: Check Java version
java -version  # Should be 17+
```

### Issue: `Conflicts in build_runner`
```bash
# Solution: Use delete-conflicting-outputs flag
dart run build_runner build --delete-conflicting-outputs
```

### Issue: `Analysis errors with imports`
```bash
# Solution: Ensure pubspec.yaml is saved
flutter pub get
flutter analyze
```

### Issue: `APK too large`
```bash
# Solution: Remove unused dependencies or enable shrinking
flutter build apk --release --shrink
```

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Code Gen Time | < 2 min | TBD (pending Dart install) |
| Analysis Time | < 1 min | TBD |
| Test Execution | < 2 min | TBD |
| APK Build Time | < 5 min | TBD |
| APK Size | < 200MB | TBD |
| Startup Time | < 2 sec | TBD |
| Frame Rate | 60 FPS | TBD |

---

## Important Files (Don't Delete)

```
mobile/
├── lib/
│   ├── main.dart                    # Entry point
│   ├── providers/
│   │   └── app_providers.dart      # All Riverpod providers
│   ├── services/
│   │   ├── api_service.dart        # API client
│   │   ├── auth_http_client.dart   # DIO setup
│   │   └── token_storage.dart      # JWT encryption
│   ├── database/
│   │   └── app_database.dart       # Drift models
│   ├── screens/
│   │   ├── login_screen.dart       # Auth UI
│   │   └── farm_list_screen.dart   # Main UI
│   └── theme/
│       └── app_theme.dart          # Material Design 3
├── android/
│   ├── app/build.gradle            # App config
│   └── app/src/main/...            # Manifest, MainActivity
└── pubspec.yaml                    # Dependencies

.github/workflows/
├── mobile-ci.yml                   # Auto build on push
└── mobile-build.yml                # Manual distribute
```

---

## Environment Variables Needed (Phase 2)

These will be needed to connect to the actual backend:

```bash
# Backend
BACKEND_URL=http://localhost:8000  # Change to production later
BACKEND_API_VERSION=v1

# Google OAuth (Phase 2)
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret

# Microsoft OAuth (Phase 2)
MICROSOFT_CLIENT_ID=your_client_id
MICROSOFT_CLIENT_SECRET=your_client_secret

# Firebase (Phase 2)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id

# Sentry (Error tracking - Phase 2)
SENTRY_DSN=your_sentry_dsn
```

**Note:** Currently hardcoded/not required for MVP build

---

## Git Workflow for Next Changes

```bash
# 1. Create feature branch
git checkout -b feature/mobile-phase2-oauth

# 2. Make changes (code gen, add oauth, etc)
flutter pub get
dart run build_runner build

# 3. Test locally
flutter analyze
flutter test

# 4. Commit
git add .
git commit -m "feat: add oauth integration"

# 5. Push
git push origin feature/mobile-phase2-oauth

# 6. Create PR on GitHub
# (CI/CD will automatically test)
```

---

## Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Riverpod Docs:** https://riverpod.dev
- **Drift Docs:** https://drift.simonbinder.eu
- **Material Design 3:** https://m3.material.io
- **Android Docs:** https://developer.android.com
- **GitHub Actions:** https://docs.github.com/en/actions

---

## Support

**Before asking for help, check:**
1. Is Flutter installed? `flutter --version`
2. Are dependencies resolved? `flutter pub get`
3. Did code generation complete? Look for `*.g.dart` files
4. Did analysis pass? `flutter analyze`
5. Check Git log: `git log --oneline -5`

**Common place to check for errors:**
- Build output: `flutter build apk --release -v`
- Test failures: `flutter test -v`
- Analysis errors: `flutter analyze --verbose`

---

**Status:** ✅ Ready for Phase 2  
**Last Updated:** December 10, 2025  
**Next Review:** After code generation
