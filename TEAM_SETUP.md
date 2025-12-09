# Team Setup & Development Kickoff Guide

**Date:** December 9, 2025  
**Project:** Crop AI - Mobile-First Farming Platform  
**Target Users:** 95% mobile (Android & iOS 15+), 5% web  

---

## Project Overview

| Aspect | Details |
|---|---|
| **Goal** | Empower farmers with AI-driven crop monitoring, predictions, and community engagement |
| **Timeline** | 17 weeks (includes 2-week Epic 0 infrastructure setup) |
| **Team Size** | 2 Flutter developers + 1 backend/DevOps |
| **Release Target** | App stores + web portal (Week 17) |
| **Architecture** | Separate mobile UI + Shared backend logic |

---

## Team Roles & Responsibilities

### Flutter Development Team (2 Developers)

**Developer 1 - Frontend Lead**
- **Epics:** Epic 1 (Crop Monitoring) + coordination
- **Responsibilities:**
  - Farm list & detail screens UI
  - Weather integration widget
  - Offline data sync
  - Widget test coverage (critical UI paths)
  - Code review for other mobile features
  - Mobile UX/performance optimization

**Developer 2 - Backend Integration Lead**
- **Epics:** Epic 2 (AI Predictions) + Firebase
- **Responsibilities:**
  - Firebase integration (Auth, Realtime DB, Cloud Messaging)
  - API endpoint integration with backend
  - Data transformation layer (Dio + Riverpod)
  - Unit test coverage (business logic)
  - Offline storage schema (Drift + SQLite)

**Shared Responsibilities (Both):**
- CI/CD pipeline maintenance
- Security scanning & dependency updates
- Performance monitoring
- Team code reviews

### Backend/DevOps Engineer (1 Engineer)

**Responsibilities:**
- Maintain FastAPI backend
- Firebase project setup & configuration
- GitHub Actions workflow tuning
- App store preparation (certificates, signing)
- Production deployment & monitoring
- Documentation & runbooks

---

## Week-by-Week Timeline

```
┌─────────────────────────────────────────────────────────────┐
│                     SPRINT 0: SETUP                         │
│  Week -2 to 0 (2 weeks) - Epic 0: CI/CD Infrastructure      │
├─────────────────────────────────────────────────────────────┤
│ ✅ Project structure created                                 │
│ ✅ GitHub Actions workflows created                          │
│ ⏳ Firebase project setup                                    │
│ ⏳ GitHub secrets configuration                              │
│ ⏳ Team environment setup                                    │
│ ⏳ Validate CI/CD workflows                                  │
│                                                              │
│ Deliverables: Production-ready mobile CI/CD pipeline         │
│ Team: 1 DevOps + 2 Flutter devs (part-time setup)           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              SPRINT 1-4: CORE FEATURES                       │
│  Week 1 to 4 (4 weeks) - Epic 1: Crop Monitoring            │
├─────────────────────────────────────────────────────────────┤
│ Dev 1: Farm list, detail screens, search/filter             │
│ Dev 2: Offline sync, weather widget, data binding           │
│ Farmers can start using app after this epic                 │
│                                                              │
│ Deliverables: MVP - farmers see their farms                 │
│ Status: Push to App Store beta                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│           SPRINT 5-8: AI INTELLIGENCE                        │
│  Week 5 to 8 (4 weeks) - Epic 2: AI Predictions             │
├─────────────────────────────────────────────────────────────┤
│ Dev 2 leads: TensorFlow Lite model integration              │
│ Dev 1: AI result display & recommendations UI               │
│ Real-time predictions on farm data                          │
│                                                              │
│ Deliverables: AI predictions functional                     │
│ Status: Push to App Store beta v2                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│        SPRINT 9-12: ENGAGEMENT & COMMUNITY                   │
│  Week 9 to 12 (4 weeks) - Epic 3: Gamification              │
├─────────────────────────────────────────────────────────────┤
│ Dev 1 leads: Leaderboard, achievements, rewards             │
│ Dev 2: Community messaging & real-time sync                 │
│ User engagement mechanics active                            │
│                                                              │
│ Deliverables: Gamification system live                      │
│ Status: Push to App Store beta v3                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│         SPRINT 13-16: MARKETPLACE & COMMERCE                 │
│  Week 13 to 16 (4 weeks) - Epic 4: Marketplace              │
├─────────────────────────────────────────────────────────────┤
│ Dev 2 leads: Payment integration, product listings          │
│ Dev 1: Transaction UI, order tracking                       │
│ Marketplace operational                                     │
│                                                              │
│ Deliverables: Marketplace transactions flowing              │
│ Status: Push to App Store production release                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              SPRINT 17: FINAL POLISH                         │
│  Week 17 (1 week) - Epic 5: Full Integration                │
├─────────────────────────────────────────────────────────────┤
│ Polish UI/UX, final testing, performance tuning             │
│ Release to production (App Store + Play Store)              │
│                                                              │
│ Deliverables: Production mobile app live                    │
│ Status: Users downloading from official stores              │
└─────────────────────────────────────────────────────────────┘
```

---

## Getting Started (Week -2)

### Step 1: Environment Setup (Day 1)

**All Team Members:**
```bash
# Clone repository
git clone https://github.com/dlai-sd/crop-ai.git
cd crop-ai

# Verify git branches
git branch -a

# Read critical documentation
cat BRANCHING_STRATEGY.md
cat MOBILE_SETUP_GUIDE.md
cat MOBILE_APP_EPICS.md
```

**Flutter Developers Only:**
```bash
# Install Flutter SDK
curl https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_v3.16.0-stable.tar.xz -o flutter.tar.xz
tar xf flutter.tar.xz
export PATH="$PATH:$PWD/flutter/bin"
flutter --version

# Verify setup
flutter doctor

# Get dependencies for mobile project
cd mobile
flutter pub get
```

**DevOps Engineer:**
```bash
# Setup Firebase CLI
npm install -g firebase-tools
firebase login

# Test GitHub CLI
gh auth login
gh repo view dlai-sd/crop-ai
```

### Step 2: Firebase Project Setup (Day 2-3)

**Backend/DevOps Engineer:**

1. **Create Firebase Project:**
   ```bash
   firebase projects:create crop-ai-prod --display-name "Crop AI Platform"
   ```

2. **Configure Authentication:**
   - Go to Firebase Console > Authentication
   - Enable: Email/Password, Google Sign-In, Phone Authentication
   - Download service account JSON

3. **Setup Realtime Database:**
   - Create database in `us-central1`
   - Set security rules for farmer data isolation
   - Initialize with seed data structure

4. **Enable Cloud Messaging:**
   - Get server key
   - Configure notification topics (farm-updates, marketplace)

5. **Generate Credentials:**
   ```bash
   # Copy service account JSON
   cp firebase-service-account.json ../.firebase/
   
   # Export for GitHub Actions
   cat firebase-service-account.json | base64 > fb_service_account.b64
   ```

### Step 3: GitHub Secrets Configuration (Day 3)

**Backend/DevOps Engineer:**

Set these secrets in GitHub:
- **ANDROID_SERVICE_ACCOUNT_JSON** (Play Store deployment key)
- **APPSTORE_ISSUER_ID** (iOS deployment)
- **API_KEY_ID** (iOS deployment)
- **API_PRIVATE_KEY** (iOS deployment)
- **SONAR_TOKEN** (SonarQube analysis)
- **FIREBASE_SERVICE_ACCOUNT** (CI/CD Firebase access)

```bash
# Example for GitHub CLI
gh secret set FIREBASE_SERVICE_ACCOUNT < firebase-service-account.json
```

### Step 4: Team Development Setup (Day 4)

**Flutter Developer 1 (Frontend Lead):**
```bash
# Create feature branch from Epic 1
git checkout epic/1-crop-monitoring
git checkout -b feature/epic1-farm-list
flutter pub get

# Run tests to verify setup
flutter test

# Start development
code lib/screens/farm_list_screen.dart
```

**Flutter Developer 2 (Backend Integration Lead):**
```bash
# Create feature branch from Epic 2
git checkout epic/2-ai-predictions
git checkout -b feature/epic2-firebase-integration
flutter pub get

# Setup Firebase locally
firebase init
firebase setup:emulators

# Run emulators
firebase emulators:start
```

**Backend Engineer:**
```bash
# Prepare staging environment
# Deploy staging API endpoint
# Setup monitoring & logging

# Create deployment playbook
cat > docs/DEPLOYMENT_GUIDE.md << 'EOF'
# Deployment Guide
...
EOF
```

### Step 5: Validate CI/CD Pipeline (Day 5)

**All Team Members:**

1. **Test Feature Branch:**
   ```bash
   git checkout -b test/ci-validation
   echo "// test" >> lib/main.dart
   git add . && git commit -m "test: validate CI/CD pipeline"
   git push -u origin test/ci-validation
   ```

2. **Create PR and Verify:**
   - Go to GitHub > Pull Requests > New
   - Verify CI checks pass (flutter analyze, tests, security scan)
   - Check SonarQube results
   - Check coverage reporting

3. **Validate Artifact Build:**
   - Trigger workflow manually: `workflow_dispatch`
   - Verify APK/AAB/IPA builds complete
   - Download artifacts from GitHub Actions

4. **Cleanup:**
   ```bash
   git checkout develop
   git branch -D test/ci-validation
   git push origin --delete test/ci-validation
   ```

---

## Code Style & Standards

### Dart/Flutter Standards

**Naming Conventions:**
```dart
// Classes: PascalCase
class FarmListScreen extends StatelessWidget {}

// Functions/Methods: camelCase
void fetchFarmData() {}
String formatWeatherData(dynamic data) {}

// Constants: camelCase with const
const int defaultTimeout = 30;

// Private: Leading underscore
class _FarmListState extends State {}
String _formatData(String raw) {}
```

**File Structure:**
```
lib/
├── screens/              # UI screens
│   ├── farm_list_screen.dart
│   └── farm_detail_screen.dart
├── widgets/              # Reusable widgets
│   ├── farm_card.dart
│   └── weather_widget.dart
├── providers/            # Riverpod providers (state management)
│   ├── farm_provider.dart
│   └── weather_provider.dart
├── services/             # Business logic
│   ├── api_service.dart
│   ├── firebase_service.dart
│   └── storage_service.dart
├── models/               # Data models
│   ├── farm.dart
│   └── weather.dart
├── utils/                # Utilities
│   ├── constants.dart
│   └── logger.dart
└── main.dart
```

**Test Structure:**
```
test/
├── unit/
│   ├── providers/
│   ├── services/
│   └── models/
├── widget/
│   ├── screens/
│   └── widgets/
└── fixtures/
    ├── mock_data.dart
    └── test_helpers.dart
```

### Commit Message Format

**Conventional Commits:**
```
<type>(<scope>): <subject>

<body>

<footer>

Types: feat, fix, test, docs, style, refactor, perf, chore
Scope: epic1, epic2, etc. (e.g., epic1, firebase, ui)
Subject: Imperative, lowercase, no period
```

**Examples:**
```bash
# Feature
git commit -m "feat(epic1): add farm list search functionality"

# Bugfix
git commit -m "fix(epic1): correct farm location sorting"

# Test
git commit -m "test(epic1): add unit tests for farm filtering"

# Docs
git commit -m "docs: update setup guide"

# With body/footer
git commit -m "feat(epic2): integrate Firebase Realtime Database

- Setup database schema
- Implement offline sync queue
- Add retry logic for failed writes

Closes #42"
```

---

## Daily Development Workflow

### Morning Check-in
1. **Update branches:**
   ```bash
   git checkout develop && git pull
   git checkout epic/1-crop-monitoring && git pull
   git checkout <your-feature-branch> && git rebase epic/1-crop-monitoring
   ```

2. **Run tests locally:**
   ```bash
   flutter test --coverage
   ```

3. **Review CI/CD:**
   - Check GitHub Actions for previous day's builds
   - Review any failed tests or security issues

### During Day
1. **Commit frequently** (at least every 2 hours)
   ```bash
   git add lib/screens/farm_list_screen.dart
   git commit -m "feat(epic1): add farm search filter"
   git push origin feature/epic1-farm-list
   ```

2. **Keep branch synced:**
   ```bash
   # If changes made to epic branch
   git rebase epic/1-crop-monitoring
   git push origin feature/epic1-farm-list --force-with-lease
   ```

3. **Run tests before commit:**
   ```bash
   flutter analyze    # Linting
   flutter test       # Unit tests
   flutter test -t widget  # Widget tests
   ```

### Evening Standup
1. **Document progress** (GitHub issues or Slack)
2. **Push all changes:**
   ```bash
   git push origin feature/epic1-farm-list
   ```
3. **Note blockers** for next day
4. **Sync with partner dev**

### End of Week
1. **Create Pull Request to epic branch**
   ```bash
   # Go to GitHub > New PR
   # Base: epic/1-crop-monitoring
   # Compare: feature/epic1-farm-list
   ```

2. **Code review with partner**
   - Run locally on their machine
   - Check test coverage
   - Verify CI passes

3. **Merge when approved**
   - Squash and merge (cleaner history)
   - Delete feature branch

---

## Running Tests & Checks Locally

```bash
# Full test suite
flutter test --coverage

# Specific test file
flutter test test/unit/providers/farm_provider_test.dart

# Widget tests only
flutter test -t widget

# With output
flutter test --verbose

# Run with coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View report

# Linting
flutter analyze

# Format code
dart format lib/
dart format --fix lib/

# Check dependencies for vulnerabilities
flutter pub audit
```

---

## Code Review Checklist

**Before Submitting PR:**
- [ ] Code follows style guide (naming, formatting)
- [ ] Tests added/updated (80% coverage minimum)
- [ ] All tests pass locally
- [ ] `flutter analyze` passes (no warnings)
- [ ] `dart format` applied
- [ ] Commit messages are descriptive
- [ ] No debug prints in code
- [ ] No commented-out code
- [ ] Documentation updated if needed

**During Code Review:**
- [ ] Functionality matches requirements
- [ ] Tests are comprehensive
- [ ] Edge cases handled
- [ ] Error handling present
- [ ] Performance acceptable
- [ ] Security best practices followed
- [ ] Code is maintainable

---

## Communication & Escalation

### Daily Standups
- **Time:** 9:00 AM daily
- **Duration:** 15 minutes
- **Format:** What you did, what you'll do, blockers

### Weekly Sync
- **Time:** Friday 4:00 PM
- **Duration:** 30 minutes
- **Topics:** Sprint progress, blockers, next sprint planning

### Escalation Path
1. **Blocker on own task:** Slack partner dev
2. **Blocker affecting team:** Slack dev lead
3. **Critical production issue:** Call dev lead immediately

### Communication Channels
- **Slack #mobile-dev:** Daily questions & quick updates
- **Slack #mobile-blockers:** Critical issues only
- **GitHub Issues:** Feature planning & tracking
- **GitHub PRs:** Code review & discussion
- **Email:** Formal communication only

---

## Resources & Documentation

**Essential Docs:**
- `README.md` - Project overview
- `BRANCHING_STRATEGY.md` - Git workflow
- `MOBILE_SETUP_GUIDE.md` - Environment setup
- `MOBILE_APP_EPICS.md` - Feature roadmap
- `MOBILE_CICD_SETUP.md` - CI/CD details

**Flutter Learning:**
- [Flutter Official Docs](https://flutter.dev/docs)
- [Riverpod Documentation](https://riverpod.dev)
- [Drift ORM Docs](https://drift.simonbinder.eu)
- [Firebase Flutter Docs](https://firebase.flutter.dev)

**External Services:**
- Firebase Console: https://console.firebase.google.com
- GitHub: https://github.com/dlai-sd/crop-ai
- SonarQube: [Your SonarQube server]

---

## Troubleshooting

### Flutter Setup Issues
```bash
# Clean build
flutter clean
rm pubspec.lock
flutter pub get

# Update SDK
flutter upgrade

# Diagnose issues
flutter doctor -v
```

### Build Failures
```bash
# Clear build cache
flutter clean
cd ios && pod deintegrate && cd ..

# Rebuild
flutter pub get
flutter build apk
```

### Test Failures
```bash
# Run single test with verbose output
flutter test test/unit/models_test.dart -v

# Debug specific test
flutter test --start-paused test/unit/models_test.dart
```

---

## Success Metrics

### Code Quality
- ✅ Test coverage: ≥ 80%
- ✅ 0 linting warnings
- ✅ 0 critical security issues
- ✅ SonarQube quality gate passes

### Development Velocity
- ✅ PR review time: < 24 hours
- ✅ Feature branch lifetime: < 1 week
- ✅ CI pass rate: > 95%
- ✅ Deployment frequency: 2x per week

### User Impact
- ✅ App performance: < 2s load time
- ✅ Crash rate: < 0.1%
- ✅ User retention after Epic 1: > 70%
- ✅ App store rating: > 4.5 stars

---

**Last Updated:** December 9, 2025  
**Next Review:** After Epic 0 completion (Week 0)
