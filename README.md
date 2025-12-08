# crop-ai

Crop Identification demo — modular AI system for crop identification using satellite imagery.

## Latest Updates

### Frontend UI Implementation (December 5, 2025) ✅
- ✅ **Registration Component:** Complete user signup with validation & password strength indicator
- ✅ **Login Component:** Email/username authentication with MFA support & SSO buttons
- ✅ **MFA Verification Component:** 6-digit code input with countdown timer & backup codes
- ✅ **Auth API Service:** 15+ methods for backend integration (registration, login, MFA, devices, etc.)
- ✅ **Responsive Design:** Mobile-first approach, all devices supported
- ✅ **Internationalization:** 4 languages (English, Hindi, Marathi, Gujarati) with RTL support
- ✅ **Security Features:** Password validation, rate limiting feedback, secure token storage
- ✅ **1,800+ Lines of Code:** Production-grade UI components

See `frontend/angular/UI_IMPLEMENTATION_GUIDE.md` and `frontend/angular/UI_IMPLEMENTATION_SUMMARY.md` for details.

### Login Feature (December 5, 2025) ✅
- ✅ **Credential-Based Authentication:** Email/username + password login
- ✅ **Multi-Factor Authentication:** TOTP (Google Authenticator), SMS OTP, Email OTP
- ✅ **Device Management:** Register, trust, and manage login devices
- ✅ **Password Management:** Change password, reset via email
- ✅ **Login History:** Complete audit trail of all login attempts
- ✅ **Security Features:** Rate limiting, account lockout, brute force protection
- ✅ **18 API Endpoints:** Full CRUD operations for login management
- ✅ **Production Ready:** Comprehensive documentation and security best practices

See `LOGIN_QUICK_REFERENCE.md` and `src/crop_ai/login/LOGIN_GUIDE.md` for details.

### Frontend Landing Page (December 4, 2025)
- ✅ **Submenu Navigation:** All navigation items now smoothly scroll to relevant page sections
- ✅ **Smart Carousel:** "I Am" and "Our Offerings" menus automatically navigate to corresponding user role cards
- ✅ **Typography:** Applied Aptos (Body) font for professional appearance
- ✅ **Text Alignment:** Justified text for About Us, Vision, and Mission sections
- ✅ **Responsive Design:** Fully responsive navigation and layout
- ✅ **Multilingual Support:** 4-language support (English, Hindi, Marathi, Gujarati)

See `CHANGELOG.md` for complete session details.

## Quick start

### Frontend Development (Angular)

```bash
cd frontend/angular
npm install
npm start  # Runs on http://localhost:4200
```

The dev server binds to all interfaces (0.0.0.0:4200) for external access.

### Backend / Python

1. Create and activate a virtual environment:
```bash
python -m venv .venv
source .venv/bin/activate  # or on Windows: .venv\Scripts\activate
```

2. Install dependencies:
```bash
pip install -r requirements.txt
pip install -r requirements-dev.txt  # for linting/formatting
```

3. Run tests:
```bash
PYTHONPATH=src python -m pytest -q
```

4. Build Docker image locally:
```bash
docker build -t crop-ai:latest .
```

### CI/CD pipeline

The project uses GitHub Actions for testing, linting, formatting, Docker builds, and deployment to Azure.

- **Test job:** runs `pytest` across Python 3.10–3.12 with pip caching.
- **Lint/format checks:** runs `ruff` (linting) and `black --check` (format validation).
- **Docker build:** builds and verifies the container image.
- **Deploy job:** (optional, gated on `main` branch) pushes to Azure Container Registry and deploys to Azure Web App.

See `.github/workflows/ci.yml` for details.

### Azure deployment

To deploy to Azure, see `docs/azure-deploy.md` for setup instructions. Key steps:

1. Create Azure resources (ACR, Web App, App Service Plan).
2. Add GitHub repository secrets for Azure credentials.
3. Push to `main` to trigger the CI/CD pipeline.

### Cleanup

To safely delete Azure resource groups:

```bash
# Dry-run (no changes)
bash scripts/azure_cleanup.sh --prefix crop- --dry-run

# Backup and delete interactively
bash scripts/delete_crop_ai_rg.sh  # interactive
bash scripts/delete_crop_ai_rg.sh --yes  # non-interactive
```

See `docs/azure-cleanup.md` for details.

## Project structure

```
crop-ai/
├── src/crop_ai/          # Main package
│   ├── __init__.py
│   └── predict.py        # ModelAdapter stub and CLI
├── tests/                # Unit tests
│   └── test_predict.py
├── scripts/              # Utility scripts
│   ├── azure_cleanup.sh
│   ├── delete_crop_ai_rg.sh
│   └── convert_docx.py
├── docs/                 # Documentation
│   ├── azure-deploy.md
│   ├── azure-cleanup.md
│   └── context.md
├── .github/workflows/    # GitHub Actions
│   └── ci.yml
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
└── pyproject.toml
```

## Documentation

- `docs/context.md` — extracted project context from `DLAI Prompt.docx`.
- `docs/azure-deploy.md` — setup guide for Azure Container Registry and Web App deployment.
- `docs/azure-cleanup.md` — safe deletion of Azure resource groups.
- `.github/copilot-instructions.md` — guidance for AI coding agents.

## Next steps

- Implement a real `ModelAdapter` subclass for PyTorch or TensorFlow.
- Collect and prepare satellite imagery datasets for crop training.
- Build a demo backend (Flask/FastAPI) and frontend (HTML/JS) for predictions.
- Set up Kubernetes deployment if scaling is required.
# Pipeline run Wed Dec  3 09:40:35 UTC 2025
# Azure deployment secrets configured Wed Dec  3 10:03:47 UTC 2025
# Deployment update Wed Dec  3 10:11:18 UTC 2025
# Fresh deployment trigger Wed Dec  3 11:01:56 UTC 2025
# Test trigger
