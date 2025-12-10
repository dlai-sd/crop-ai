# CI/CD Pipeline Optimization Analysis

**Date:** December 10, 2025  
**Current Status:** 2 workflows identified with optimization opportunities

---

## Current Pipeline Issues

### 1. **Duplicate Flutter Setup (3 times)**
- `mobile-ci.yml` lint job: `flutter pub get`
- `mobile-ci.yml` test job: `flutter pub get`
- `mobile-ci.yml` build_apk job: `flutter pub get`
- `mobile-build.yml` build_and_distribute: `flutter pub get`

**Impact:** Each job re-downloads 1.5GB+ of Flutter SDK and dependencies
**Cost:** ~15-20 minutes of redundant setup per workflow run

### 2. **No Dependency Caching**
- pubspec.lock not cached between jobs
- Flutter pub cache rebuilt every time
- Gradle cache not persisted

**Impact:** Each `flutter pub get` takes 2-3 minutes instead of 10-30 seconds
**Cost:** ~6-9 minutes wasted per complete CI run

### 3. **Duplicate Build Steps**
- mobile-ci.yml builds APK (PR trigger, main branch only)
- mobile-build.yml builds APK + AAB (manual trigger)

**Impact:** Same artifact built twice if both workflows run
**Cost:** 5-10 minutes of duplicate compilation

### 4. **No Docker Image Reuse**
- Each workflow spins up fresh Ubuntu environment
- No Docker layer caching
- Dockerfile.mobile not used in CI/CD

**Impact:** No image reuse between runs
**Cost:** 2-3 minutes per workflow setup

### 5. **Sequential Job Dependencies**
- `lint` → `test` → `build_apk` (serial execution)

**Impact:** Even though jobs could run partially parallel, deps force sequential
**Cost:** Total time = sum of all jobs (currently ~25-30 min)

---

## Optimization Opportunities

### Quick Wins (Low Effort, High Impact)

#### A. **Add GitHub Actions Caching**
```yaml
- name: Cache Flutter SDK
  uses: actions/cache@v3
  with:
    path: |
      ~/.pub-cache
      build
    key: flutter-${{ hashFiles('mobile/pubspec.lock') }}
    restore-keys: flutter-
```
**Expected Savings:** 3-5 minutes per job
**Effort:** 5 minutes

#### B. **Use Matrix Strategy for Multi-Platform**
Instead of building per-ABI sequentially, build in parallel:
```yaml
strategy:
  matrix:
    abi: [arm64, arm32, x86_64]
```
**Expected Savings:** 2-3 minutes (parallel builds)
**Effort:** 10 minutes

#### C. **Consolidate Workflows**
Merge mobile-ci.yml and mobile-build.yml:
- One workflow handles both PR testing and release builds
- Reuse job outputs via artifacts
**Expected Savings:** Eliminates duplicate setup and builds
**Effort:** 20 minutes

---

### Medium Effort, High Impact

#### D. **Docker Image with Cached Layers**
- Pre-build Docker image with Flutter, Dart, Android SDK
- Push to GitHub Container Registry (ghcr.io)
- Reuse across all workflows

```dockerfile
# Instead of downloading Flutter each time:
FROM ghcr.io/dlai-sd/crop-ai:flutter-3.24
```

**Expected Savings:** 5-10 minutes per workflow (no SDK download)
**Effort:** 45 minutes setup
**One-time cost:** ~15 min to build base image
**Ongoing savings:** ~10 min per workflow

#### E. **Multi-Stage Docker Build Pipeline**
- Stage 1: Dependencies (slow, cached)
- Stage 2: Code analysis (medium speed)
- Stage 3: Build APK (fast, depends on stage 1)
- Stage 4: Upload artifacts (immediate)

**Expected Savings:** 5-8 minutes (better parallelization)
**Effort:** 30 minutes

---

### Strategic Improvements

#### F. **Separate CI from Distribution**
- **CI Workflow (mobile-ci.yml):** Lint, Test, Build debug APK
  - Runs on PR and push
  - ~10 minutes
  
- **Distribution Workflow (mobile-build.yml):** Build release AAB, upload to Play Store
  - Manual trigger only
  - Reuses artifacts from CI
  - ~5 minutes

**Expected Savings:** Prevents unnecessary release builds
**Effort:** Already partially implemented

---

## Current Timeline Breakdown

```
Total: ~25-30 minutes per complete run

lint job:        5 min (setup 2min + analysis 3min)
test job:        8 min (setup 2min + tests 4min + upload 2min)
build_apk job:   12 min (setup 2min + build 8min + upload 2min)
                 ─────
                 25 min total (serial)
```

### Optimized Timeline (with caching + consolidation)

```
With A+B+C (Quick wins):
Total: ~12-15 minutes

- Setup (cached):          1 min (instead of 2)
- Lint:                    2 min
- Test (parallel):         4 min (instead of 4)
- Build multi-ABI (parallel): 3 min (instead of 8)
- Upload:                  1 min
                          ─────
                          11 min total

With D+E (Docker optimization):
Total: ~8-10 minutes
- Docker pull (cached image):  1 min
- Lint:                        2 min
- Test:                        3 min
- Build (multi-stage):         2 min
- Upload:                      1 min
                              ─────
                              9 min total
```

---

## Recommendations (Priority Order)

### Phase 1: Immediate (Before Next Run)
1. ✅ **Add pub cache** - 5 min effort, 3 min savings per job
2. ✅ **Consolidate workflows** - 20 min effort, eliminate duplicate builds
3. ✅ **Add matrix builds** - 10 min effort, 2 min savings

**Total Effort:** 35 min  
**Total Savings:** 5-8 min per run (20% reduction)

### Phase 2: Medium-term (Next Sprint)
4. ⏳ **Build base Docker image** - 45 min effort, 5-10 min savings per run
5. ⏳ **Multi-stage Docker pipeline** - 30 min effort, additional 3-5 min savings
6. ⏳ **Artifact reuse** - 20 min effort, prevent redundant builds

**Total Effort:** 95 min  
**Total Savings:** 10-15 min per run (40% reduction)

### Phase 3: Long-term
7. 📋 **Custom GitHub Actions** - Create reusable action for Flutter setup
8. 📋 **Scheduled cleanup** - Remove old artifacts, optimize storage
9. 📋 **Performance dashboard** - Track build times over time

---

## Specific Config Changes Needed

### For Caching:
```yaml
# Add to each job after checkout
- name: Cache pub dependencies
  uses: actions/cache@v3
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('mobile/pubspec.lock') }}
```

### For Docker Registry:
```yaml
# Create ghcr.io/dlai-sd/crop-ai:flutter-3.24
# Build once, reuse everywhere
- name: Build Docker image
  run: docker build -f Dockerfile.mobile -t ghcr.io/dlai-sd/crop-ai:flutter-3.24 .
```

### For Artifact Reuse:
```yaml
build_apk:
  needs: test
  if: needs.test.outputs.test_passed == 'true'
  # Reuse test results without rebuilding
```

---

## Risk Assessment

| Optimization | Risk | Mitigation |
|--------------|------|-----------|
| Caching | Stale cache | Manual clear, auto-expire in 7 days |
| Consolidation | Job failure affects both | Isolate with `if` conditions |
| Docker image | Image drift | Pin to specific SHA, auto-rebuild weekly |
| Parallel builds | Resource contention | GitHub Actions handles auto-scaling |

---

## Summary

**Current State:**
- 2 workflows with duplicate setup
- No caching of dependencies
- ~25-30 minutes per build
- Dockerfile not used in CI/CD

**Quick Wins Available:**
- Add pub caching: -3 min per job
- Consolidate workflows: -5 min (eliminate dupes)
- Parallel builds: -2 min
- **Total: -10 min (40% faster with 35 min effort)**

**Strategic Path:**
- Phase 1: Quick wins (35 min effort → 40% faster)
- Phase 2: Docker optimization (95 min effort → 60% faster)
- Phase 3: Advanced automation

**Recommendation:** Implement Phase 1 caching + consolidation first (fastest ROI). Docker optimization can wait until pipeline is established and stable.
