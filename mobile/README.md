# Mobile Infrastructure Documentation

## Architecture

**DLAI Crop Mobile** follows an infrastructure-first, offline-first design:

```
Mobile App (Flutter)
├── Login Screen (SSO providers)
├── Farm List Screen
├── Conversation Screen
└── Settings

State Management (Riverpod)
├── Auth Provider (JWT token management)
├── Farm Provider (cached farm data)
├── Conversation Provider (messaging)
├── Network Provider (connectivity detection)
└── Sync Provider (offline queue)

Local Database (Drift + SQLite)
├── Users table (cached profiles)
├── Farms table (farm metadata)
├── Conversations table
├── Messages table
└── SyncQueue (offline operations)

Security
├── flutter_secure_storage (encrypted JWT)
├── Token-based auth (Backend JWT)
├── HTTPS only (production)
└── Certificate pinning (optional)

Backend Integration
├── API Service (FastAPI on port 5000)
├── Django Gateway (port 8000)
├── Firebase (push notifications)
└── PostgreSQL (master data)
```

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | 2.6.1 | State management |
| drift | 2.19.5 | Local SQLite database |
| flutter_secure_storage | 9.2.2 | Encrypted token storage |
| dio | 5.5.0 | HTTP client with interceptors |
| firebase_messaging | 15.1.0 | Push notifications |
| intl | 0.19.0 | i18n (8 Indian languages) |
| go_router | 14.1.2 | Navigation |

## Build & Deployment

### Local Build (Codespace)

```bash
cd mobile
flutter pub get
flutter build apk --release --split-per-abi
```

### CI/CD Pipeline

**Triggers:**
- Push to main/develop (runs lint, test, build APK)
- Manual trigger (builds APK + AAB, uploads to Play Store)

**Jobs:**
1. **Lint** - dartanalyzer + format check
2. **Test** - flutter test with coverage
3. **Build APK** - Release build, split per ABI
4. **Distribute** - Upload to Play Store internal testing

### App Store Setup (Phase 2)

When ready to launch:
1. Create Google Play Developer account
2. Create App Store Connect account (Apple)
3. Register bundle IDs
4. Set up signing certificates
5. Create app listings
6. Run manual deploy workflow

## Development Workflow

### Adding a New Feature

1. Create provider in `lib/providers/app_providers.dart`
2. Create screen in `lib/screens/`
3. Add database models to `lib/database/app_database.dart`
4. Write tests in `test/`
5. Run `flutter analyze` and `flutter test`
6. Commit and push

### Local Testing

```bash
# Format code
dart format lib

# Analyze
flutter analyze

# Test
flutter test

# Build APK
flutter build apk --release
```

## Languages Supported

- English
- Hindi (हिन्दी)
- Marathi (मराठी)
- Gujarati (ગુજરાતી)
- Tamil (தமிழ்)
- Telugu (తెలుగు)
- Kannada (ಕನ್ನಡ)
- Bengali (বাংলা)

**To add a language:** Create `.arb` files in `assets/locales/`

## Offline-First Strategy

### What Works Offline
- ✅ View cached farms
- ✅ View cached conversations
- ✅ View farm details
- ✅ View message history

### What Requires Network
- ❌ Fetch new data (automatically syncs when online)
- ❌ Send messages
- ❌ Upload photos
- ⏳ These queue locally and sync on reconnect

### Sync Queue

When user goes offline:
1. Failed operations stored in `SyncQueue` table
2. App shows "offline" indicator
3. User continues using cached data
4. When online detected, auto-sync triggers
5. User can manually tap "Sync" FAB

## Security Best Practices

✅ **Implemented:**
- JWT stored in flutter_secure_storage (encrypted)
- No hardcoded credentials
- HTTPS enforced (production)
- Token expiry validation
- Auth header on all API calls
- 401 logout flow

⏳ **TODO (Phase 2):**
- Certificate pinning
- App attestation (Android SafetyNet)
- Biometric unlock
- Encrypted message content

## Performance Considerations

- **Database**: Indexed on frequently queried columns
- **API Calls**: Dio with connection pooling
- **Images**: Local caching with CachedNetworkImage
- **Memory**: Lazy loading conversations (last 50)
- **Battery**: 30s polling interval (configurable)

## Known Limitations

1. **iOS Not Supported Yet** - Android only (Phase 2)
2. **No Real OAuth Integration** - Placeholder UI (inject credentials later)
3. **No Firebase Setup** - Placeholder configuration (update later)
4. **No Photo Upload** - Phase 2 feature
5. **No Video Support** - Phase 3 feature

## Environment Variables

**Required for production:**

```bash
# Backend
BACKEND_URL=https://your-backend.com
BACKEND_API_URL=http://localhost:5000
DJANGO_GATEWAY_URL=http://localhost:8000

# Firebase
FIREBASE_PROJECT_ID=crop-ai-xxxxx
FIREBASE_API_KEY=xxxxxxxxx
FIREBASE_MESSAGING_SENDER_ID=xxxxx

# OAuth
GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
GOOGLE_REDIRECT_URI=com.dlai.crop://oauth/google

# App
APP_VERSION=1.0.0
APP_BUILD_NUMBER=1
```

## Testing

### Unit Tests
```bash
flutter test test/
```

### Coverage
```bash
flutter test --coverage
```

### Widget Tests
```bash
flutter test --verbose
```

## Troubleshooting

### Build Fails
1. `flutter clean`
2. `flutter pub get`
3. `flutter pub upgrade`
4. Rebuild

### APK Won't Install
- Ensure `minSdkVersion: 21` in build.gradle
- Check app ID matches (com.dlai.crop)
- Uninstall previous version first

### Database Errors
- Run code generation: `dart run build_runner build`
- Clear build: `flutter clean`

## Next Steps (Phase 2)

- [ ] Add actual Google OAuth integration
- [ ] Add Apple Sign-In
- [ ] Implement Firebase Cloud Messaging
- [ ] Add photo upload with compression
- [ ] Add iOS support
- [ ] App Store/Play Store launch
- [ ] Analytics integration
- [ ] Crash reporting (Sentry)
- [ ] Performance monitoring
- [ ] Beta testing program

## Resources

- Flutter: https://flutter.dev
- Riverpod: https://riverpod.dev
- Drift: https://drift.simonbinder.eu
- Firebase: https://firebase.google.com
- Material Design 3: https://material.io/design
