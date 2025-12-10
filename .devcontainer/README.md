# Development & Quick Reference Guide

## 🚀 Quick Start (Post-Devcontainer Init)

### Start Services
```bash
# Backend FastAPI (port 5000)
cd src && python -m uvicorn crop_ai.main:app --reload --host 0.0.0.0 --port 5000

# Django Gateway (port 8000)
cd frontend && python manage.py runserver 0.0.0.0:8000

# Angular Web (port 4200)
cd frontend/angular && npm start

# Flutter Mobile (emulator or device)
cd mobile && flutter run
```

### Run Tests
```bash
# Python backend tests
PYTHONPATH=src python -m pytest tests/ -q

# Flutter mobile tests
cd mobile && flutter test

# Code coverage
PYTHONPATH=src python -m pytest tests/ --cov=src/crop_ai --cov-report=html
```

### Code Quality
```bash
# Python linting & formatting
black src/ tests/
isort src/ tests/
bandit -r src/

# Flutter analysis
cd mobile && flutter analyze

# Type checking
PYTHONPATH=src mypy src/ --strict
```

---

## 📦 Available Commands

### Firebase Management
```bash
firebase login
firebase list
firebase deploy
firebase functions:log
```

### Development Utilities
```bash
# View running services
docker ps

# Check port usage
lsof -i :5000
lsof -i :8000

# Monitor logs
tail -f /tmp/crop-ai.log

# Database access
sqlite3 predictions.db
psql -h localhost -U postgres -d crop_ai_dev
```

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/epic1-farm-details

# Commit with conventional message
git commit -m "feat: add farm details screen"

# Push to remote
git push -u origin feature/epic1-farm-details

# Create PR (or use GitHub CLI)
gh pr create --base main
```

---

## 🔧 Environment Variables

### Required (create `.env` file):
```bash
# Firebase
FIREBASE_API_KEY=xxx
FIREBASE_PROJECT_ID=crop-ai-dev
FIREBASE_DATABASE_URL=https://crop-ai-dev.firebaseio.com

# Database
DATABASE_URL=sqlite:///./predictions.db
DATABASE_ASYNC_URL=sqlite+aiosqlite:///./predictions.db

# JWT
JWT_SECRET_KEY=your-secret-key-here
JWT_ALGORITHM=HS256

# OAuth (optional)
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx
```

---

## 📁 Project Structure

```
crop-ai/
├── .devcontainer/          # Codespace config
├── src/crop_ai/           # FastAPI backend
│   ├── registration/       # User signup & auth
│   ├── login/             # Login & MFA
│   ├── farm/              # Farm management (Priority B)
│   └── main.py            # App entry point
├── frontend/              # Django Gateway & Angular
│   ├── api/               # Django REST endpoints
│   ├── angular/           # Angular Web UI
│   └── manage.py
├── mobile/                # Flutter mobile app (Priority D)
│   ├── lib/
│   │   ├── screens/       # UI screens
│   │   ├── providers/     # Riverpod state
│   │   ├── widgets/       # Reusable components
│   │   └── main.dart
│   └── test/
├── tests/                 # Python unit tests
└── docs/                  # Documentation
```

---

## 🧪 Testing Checklist

### Before Commit
- [ ] Run: `PYTHONPATH=src pytest tests/ -q`
- [ ] Run: `cd mobile && flutter test`
- [ ] Run: `cd mobile && flutter analyze`
- [ ] Run: `black src/ tests/ && isort src/ tests/`

### Before PR
- [ ] All tests passing
- [ ] Code coverage > 80%
- [ ] No lint warnings
- [ ] Commit message follows conventional format
- [ ] Updated relevant documentation

---

## 🐛 Troubleshooting

### Flutter Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade

# Check doctor
flutter doctor -v

# Clear cache
rm -rf /tmp/flutter
```

### Python Issues
```bash
# Reinstall dependencies
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt -r requirements-dev.txt

# Clear cache
find . -type d -name __pycache__ -exec rm -r {} +
find . -type f -name "*.pyc" -delete
```

### Firebase Issues
```bash
firebase login
firebase projects:list
firebase database:get / -P crop-ai-dev
```

---

## 📚 Documentation

- **PRIORITY_TASKS_COMPLETION.md** - Latest work summary
- **AGENT_STATUS_BRIEFING.md** - Current project status
- **docs/FIREBASE_SETUP.md** - Firebase configuration
- **README.md** - Project overview
- **BRANCHING_STRATEGY.md** - Git workflow

---

## 🚢 Deployment

### Local Docker
```bash
docker build -t crop-ai:latest .
docker run -p 5000:5000 -p 8000:8000 crop-ai:latest
```

### Production (Azure)
```bash
# Via GitHub Actions
git push origin main  # Triggers ci.yml

# Manual deploy
./scripts/deploy-codespace.sh
```

---

## 💡 Tips & Best Practices

1. **Keep Codespace Fresh**
   - Run `.devcontainer/init.sh` periodically
   - Update dependencies: `pip list --outdated`

2. **Productivity**
   - Use VS Code command palette (Ctrl+Shift+P)
   - Install recommended extensions
   - Set up keybindings for test/format commands

3. **Debugging**
   - Python: Use Pylance inline errors
   - Flutter: Use `flutter run -v` for verbose output
   - Network: Check `localhost:5000/docs` for API docs

4. **Performance**
   - Exclude `__pycache__`, `node_modules`, `build/` from search
   - Use `.gitignore` to avoid committing build artifacts
   - Run tests in parallel when possible

---

**Last Updated:** December 10, 2025
**Status:** Ready for Q1 2026 Launch
