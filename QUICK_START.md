# ⚡ QUICK START - Phase 2 (Next 30 minutes)

**Your Next Steps in 4 Commands**

---

## Step 1: Install Flutter (if needed)

```bash
# Check if Flutter is installed
flutter --version

# If not installed:
# Visit: https://flutter.dev/docs/get-started/install
# Then verify:
flutter doctor
```

**Expected Output:**
```
Flutter 3.x.x • channel stable
Dart 3.x.x
```

---

## Step 2: Generate Code

```bash
cd /workspaces/crop-ai/mobile
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

**Expected Output:**
```
Building under null-safety mode.
Building package executable...
Running build...
[17/17] Completed successfully.
```

**This generates:**
- `app_database.g.dart` (1000+ LOC)
- `.freezed.dart` files for models
- `.g.dart` files for Riverpod

---

## Step 3: Run Unit Tests (30 seconds)

```bash
flutter test tests/unit/
```

**Expected Output:**
```
✓ firebase_connection_monitor_test.dart
✓ offline_cache_service_test.dart
20+ tests passed
```

---

## Step 4: Run Integration Tests (2 minutes)

```bash
flutter test tests/integration/
```

**Expected Output:**
```
✓ firebase_sync_integration_test.dart
15+ scenarios completed
All tests passed
```

---

## ✅ Phase 2 Complete!

If all tests pass, you're ready for **Phase 3: Firebase Setup**

---

## 🆘 Troubleshooting Quick Fixes

### Issue: `flutter: command not found`
```bash
# Add Flutter to PATH
export PATH="$PATH:$HOME/flutter/bin"
flutter doctor
```

### Issue: Build errors
```bash
# Clean and retry
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue: Test failures
```bash
# Run with verbose output
flutter test tests/unit/ -v

# Run specific test
flutter test tests/unit/firebase_connection_monitor_test.dart
```

### Issue: Permission denied
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

---

## 📖 Full Documentation

- **Phase 2+ Roadmap:** `NEXT_STEPS.md`
- **Production Checklist:** `PRODUCTION_CHECKLIST.md`
- **Deployment Guide:** `PRODUCTION_DEPLOYMENT.md`
- **Phase 1 Dashboard:** `PHASE_1_COMPLETE.md`

---

## ⏱️ Timeline

| Step | Duration | Status |
|------|----------|--------|
| Install Flutter | 5 min | ⏳ |
| Code generation | 2 min | ⏳ |
| Unit tests | 30 sec | ⏳ |
| Integration tests | 2 min | ⏳ |
| **Total** | **~10 min** | ⏳ |

---

## 🎯 Success Criteria

✅ Flutter installed  
✅ Code generates without errors  
✅ All 20+ unit tests pass  
✅ All 15+ integration tests pass  
✅ Zero compiler warnings  

---

## 🚀 Ready?

Run this:
```bash
cd /workspaces/crop-ai/mobile && flutter pub get
```

Then:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Let me know when Phase 2 is complete! 🎉
