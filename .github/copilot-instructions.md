# GitHub Copilot Instructions — crop-ai

AI agents working on this codebase should understand the architecture, development workflows, and project-specific patterns.

## 🎯 Project Intent

**Crop AI** is a mobile-first farming platform combining satellite imagery analysis with AI predictions. The system uses modular microservices (FastAPI, Django, Flutter) supporting 95% mobile users targeting seasonal peak demand.

- **Goal:** Empower farmers with crop monitoring, AI-driven predictions, and community features
- **Timeline:** 17-week sprint (Q1 2026) across 5 epics
- **Team:** 2 Flutter developers + 1 backend/DevOps engineer
- **Status:** Phase 2 complete (registration, login, UI done); Phase 3 starting (mobile dev)

See `AGENT_STATUS_BRIEFING.md` for comprehensive context.

---

## 🏗️ Architecture Overview

### Service Topology

```
┌─────────────────────────────────────────────────────────────┐
│                 Users (Mobile 95% / Web 5%)                 │
└──────────────────────────────┬──────────────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
   ┌────▼─────┐        ┌──────▼──────┐       ┌───────▼────┐
   │ Flutter  │        │  Angular    │       │  Firebase  │
   │ Mobile   │        │  Web        │       │  Services  │
   │(port n/a)│        │(port 4200)  │       │(Auth,RTDB, │
   │          │        │             │       │ Messaging) │
   └──────────┘        └────────┬────┘       └────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  Django Gateway       │
                    │  (port 8000)          │
                    │  - Auth proxy         │
                    │  - Multi-role router  │
                    │  - Rate limiting      │
                    └───────────┬────────────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
      ┌─────▼─────┐     ┌──────▼──────┐     ┌─────▼──────┐
      │ FastAPI   │     │ Auth Module │     │ Prediction │
      │ (port     │     │ (JWT,TOTP)  │     │ Service    │
      │  5000)    │     │             │     │            │
      └────┬──────┘     └─────┬───────┘     └──────┬─────┘
           │                  │                    │
      ┌────▼──────────────────▼────────────────────▼────┐
      │        PostgreSQL Database                      │
      │ (registration, login, farm, predictions)        │
      └─────────────────────────────────────────────────┘
```

### Service Boundaries

1. **FastAPI** (`src/crop_ai/`, port 5000) — ML inference & crop prediction
2. **Django** (`frontend/api/`, port 8000) — API gateway & authentication
3. **Flutter** (`mobile/`) — Mobile app (iOS/Android, offline-first)
4. **Registration** (`src/crop_ai/registration/`) — Multi-role signup + SSO
5. **Login** (`src/crop_ai/login/`) — Auth + MFA + device management

---

## 📚 Critical Developer Workflows

### 1. **Local Development Setup**

```bash
# Backend environment
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt -r requirements-dev.txt

# Run tests (PYTHONPATH required)
PYTHONPATH=src python -m pytest -q tests/

# Run backend locally
PYTHONPATH=src python -m uvicorn crop_ai.main:app --reload --host 0.0.0.0 --port 5000

# Django gateway
cd frontend && python manage.py runserver 8000
```

### 2. **Testing & Code Quality**

- **Python:** Pytest (3.10/3.11/3.12), target 80% coverage
- **Flutter:** Unit/widget tests with `flutter test`, target 80%
- **Angular:** Jest, target 80%
- **Quality:** SonarQube, Bandit, CodeQL, Trivy (via GitHub Actions)

### 3. **Docker & Deployment**

```bash
docker build -t crop-ai:latest .
./scripts/deploy-codespace.sh  # Auto-deploys all services
```

### 4. **CI/CD Pipeline**

- `ci.yml` — Every push (tests, security, build)
- `manual-deploy.yml` — Manual deployment trigger
- `mobile-ci.yml` — Flutter CI checks
- `mobile-build.yml` — Flutter builds (APK, AAB, IPA)

### 5. **Git Workflow (Git Flow)**

```bash
git checkout epic/1-crop-monitoring
git checkout -b feature/epic1-farm-list
# Code & test locally
git add . && git commit -m "feat: add farm list"
git push -u origin feature/epic1-farm-list
# PR to epic/1-* branch, not main
```

---

## 🔧 Project-Specific Patterns

### 1. **Backend: SQLAlchemy Models**

From `src/crop_ai/registration/models.py`:
- Use `Enum` for type safety
- Add `index=True` on query columns
- Use `cascade="all, delete-orphan"` for relationships
- Always set `nullable=False` unless optional

### 2. **Backend: Pydantic Schemas**

From `src/crop_ai/registration/schemas.py`:
- Separate request/response schemas
- Role-specific schemas (Farmer, Partner, Customer)
- Use `EmailStr`, `Field()` with validators

### 3. **Backend: FastAPI Routes**

From `src/crop_ai/registration/routes.py`:
- Use `APIRouter` with prefix & tags
- Dependency injection via `Depends(get_db)`
- Proper HTTP status codes (201, 400, 409, 500)
- Async/await for I/O

### 4. **Mobile: Riverpod Providers**

```dart
// FutureProvider for async data
final farmListProvider = FutureProvider<List<Farm>>((ref) async {
  return ref.watch(apiServiceProvider).getFarms();
});

// ConsumerWidget for reading providers
class FarmListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmAsync = ref.watch(farmListProvider);
    return farmAsync.when(
      data: (farms) => FarmListView(farms: farms),
      loading: () => LoadingWidget(),
      error: (e, st) => ErrorWidget(error: e),
    );
  }
}
```

### 5. **Mobile: Drift SQLite Schema**

```dart
@DataClassName("FarmModel")
class Farms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get soilHealth => real()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

### 6. **Environment Variables (No Hardcoding)**

Backend services use env vars for all config:
- `DATABASE_URL`, `REDIS_URL`, `JWT_SECRET_KEY`
- `GOOGLE_CLIENT_ID/SECRET`, `MICROSOFT_CLIENT_ID/SECRET`
- `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`
- `TWILIO_ACCOUNT_SID`, `SMTP_SERVER`, etc.

---

## 🎯 Common Tasks

### Create Backend Endpoint

1. Define schema in `src/crop_ai/module/schemas.py`
2. Add CRUD in `src/crop_ai/module/crud.py`
3. Create route in `src/crop_ai/module/routes.py`
4. Write test in `tests/test_module.py`

### Create Flutter Screen

1. Create `mobile/lib/screens/my_screen.dart`
2. Create `mobile/lib/providers/my_provider.dart`
3. Create `mobile/test/screens/my_screen_test.dart`
4. Add to navigation in `mobile/lib/main.dart`

---

## 📋 Conventions

| Aspect | Convention |
|--------|-----------|
| **Files** | `snake_case.py` (Python), `camelCase.ts`, `snake_case.dart` |
| **Classes** | `PascalCase` (all languages) |
| **Constants** | `UPPER_SNAKE_CASE` |
| **DB Tables** | Plural (`users`, `farms`, `crops`) |
| **API Routes** | RESTful plurals (`/api/farms/{id}/weather`) |
| **Branches** | Git Flow (main → develop → epic/N-* → feature/*) |
| **Commits** | Conventional (feat:, fix:, docs:, chore:, test:) |
| **Tests** | pytest (Python), Jest (JS), flutter test (Dart) |

---

## ⚠️ Anti-Patterns to Avoid

1. **Hardcoded credentials** — Always use environment variables
2. **Blocking I/O in FastAPI** — Always `async`
3. **Direct DB in routes** — Use CRUD abstraction layer
4. **StatefulWidget** — Prefer Riverpod
5. **Sync HTTP calls** — Use async/await
6. **Commit to main** — Use feature branches + PR review
7. **Skip tests** — Target 80% coverage minimum
8. **Ignore type hints** — Use strict checking (mypy, analyzer)

---

## 📞 Key Resources

| Need | Location |
|------|----------|
| **Current Status** | `AGENT_STATUS_BRIEFING.md` |
| **Project Context** | `README.md` + `docs/context.md` |
| **Team Structure** | `TEAM_SETUP.md` |
| **Epics & Timeline** | `MOBILE_APP_EPICS.md` |
| **Git Workflow** | `BRANCHING_STRATEGY.md` |
| **CI/CD Details** | `PHASE_1_COMPLETION_REPORT.md` |
| **API Endpoints** | `LOGIN_QUICK_REFERENCE.md` |

---

**Last Updated:** December 10, 2025
