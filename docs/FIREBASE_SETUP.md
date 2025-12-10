# Firebase Setup Guide for Crop AI

**Date:** December 10, 2025  
**Status:** ⏳ Ready for Manual Configuration  
**Requires:** Firebase Console access + GitHub Secrets access

---

## Quick Setup (5-10 minutes)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project** or **Create project**
3. **Project Name:** `crop-ai` (or `crop-ai-dev`, `crop-ai-staging`)
4. **Analytics:** Enable Google Analytics (optional but recommended)
5. Click **Create Project**

⏱️ Firebase will create the project (takes 1-2 minutes)

---

### Step 2: Enable Required Services

After project is created, enable these services:

#### A. Authentication
1. In Firebase Console, go to **Authentication** (left menu)
2. Click **Get Started**
3. Enable these providers:
   - ✅ **Email/Password** (for app login)
   - ✅ **Google** (for SSO)
   - ✅ **Microsoft** (for SSO)
   - ✅ **Facebook** (for SSO) — optional, only if using
4. For each provider, add OAuth credentials from respective platforms

#### B. Realtime Database
1. Go to **Realtime Database** in left menu
2. Click **Create Database**
3. Choose **Location:** Closest to your region (e.g., `us-central1`)
4. Choose **Security Rules:** Start in **test mode** (we'll update rules later)
5. Click **Create**

⚠️ **Important:** After setup, go to **Rules** tab and paste the contents of `firebase-rules.json` from this repo.

#### C. Cloud Messaging
1. Go to **Cloud Messaging** in left menu
2. You'll see a **Web API Key** generated automatically
3. No additional setup needed (we'll use this for push notifications)

#### D. Cloud Storage (optional, for farm images)
1. Go to **Storage** in left menu
2. Click **Get Started**
3. Choose location (same as database)
4. Security rules are already configured for authenticated users

---

### Step 3: Download Service Account Credentials

**For Backend (Python FastAPI):**

1. Go to **Project Settings** (gear icon, top right)
2. Click **Service Accounts** tab
3. Click **Generate New Private Key**
4. A JSON file downloads — save it securely
5. Content looks like:
```json
{
  "type": "service_account",
  "project_id": "crop-ai-xxxxx",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "firebase-adminsdk-...@crop-ai-xxxxx.iam.gserviceaccount.com",
  ...
}
```

**Never commit this file to Git.** Store it only in GitHub Secrets.

---

### Step 4: Add Credentials to GitHub Secrets

1. Go to your GitHub repo: https://github.com/dlai-sd/crop-ai
2. Settings → Secrets and variables → Actions → **New repository secret**
3. Create these 4 secrets:

#### Secret 1: Firebase Service Account (for backend)
- **Name:** `FIREBASE_CREDENTIALS_JSON`
- **Value:** Copy entire JSON from service account key (Step 3)
- Click **Add secret**

#### Secret 2: Firebase Database URL
- **Name:** `FIREBASE_DATABASE_URL`
- **Value:** `https://YOUR_PROJECT_ID.firebaseio.com`
- (Find in Firebase Console > Realtime Database > Data tab, top left)
- Click **Add secret**

#### Secret 3: Firebase Project ID
- **Name:** `FIREBASE_PROJECT_ID`
- **Value:** `crop-ai-xxxxx` (your project ID)
- Click **Add secret**

#### Secret 4: Firebase Storage Bucket
- **Name:** `FIREBASE_STORAGE_BUCKET`
- **Value:** `crop-ai-xxxxx.appspot.com`
- Click **Add secret**

---

### Step 5: Test Connection (Local Development)

```bash
cd /workspaces/crop-ai

# Copy template and add your credentials
cp .env.firebase.template .env.firebase

# Edit .env.firebase and add your Firebase project values
nano .env.firebase

# Test Python Firebase connection
python -c "
import os
os.environ.update({
    'FIREBASE_DATABASE_URL': 'YOUR_DATABASE_URL_HERE',
    'FIREBASE_PROJECT_ID': 'YOUR_PROJECT_ID_HERE'
})
from src.crop_ai.firebase_config import init_firebase
init_firebase()
print('✅ Firebase connection successful!')
"
```

---

## Configuration Files

### For Backend (Python)

**File:** `src/crop_ai/firebase_config.py` ✅ Created  
**Purpose:** Initialize Firebase Admin SDK, verify tokens, sync data  
**Usage:**
```python
from src.crop_ai.firebase_config import init_firebase, get_auth_service, verify_firebase_token

# Initialize on app startup
init_firebase()

# Use in your routes
@app.post("/api/auth/verify")
async def verify_token(token: str):
    claims = verify_firebase_token(token)
    return claims
```

### For Frontend (Web - Angular)

**File:** `frontend/firebase-config.js` ✅ Created  
**Purpose:** Initialize Firebase for web UI  
**Usage:**
```typescript
import { auth, database, messaging } from '../firebase-config';
import { signInWithEmailAndPassword } from 'firebase/auth';

// Sign in user
const userCred = await signInWithEmailAndPassword(auth, email, password);
const idToken = await userCred.user.getIdToken();

// Send token to backend for verification
const response = await fetch('/api/auth/verify', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${idToken}` }
});
```

### For Mobile (Flutter)

**File:** `mobile/pubspec.yaml` — add dependencies  
**Purpose:** Firebase integration for offline-first mobile  

Add to `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  firebase_database: ^11.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
```

Then in Dart:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

### Security Rules

**File:** `firebase-rules.json` ✅ Created  
**Location:** Firebase Console → Realtime Database → Rules tab  
**Action:** Copy entire content and paste into Rules editor, then Publish

**What it does:**
- Users can only read/write their own data
- Public weather data is read-only for authenticated users
- Analytics are append-only
- All other access denied by default

---

## Verification Checklist

After setup, verify everything works:

```bash
# 1. Check environment variables
cat .env.firebase | grep FIREBASE

# 2. Test Python Firebase connection
cd /workspaces/crop-ai
PYTHONPATH=src python -c "
from src.crop_ai.firebase_config import init_firebase, get_auth_service
try:
    init_firebase()
    print('✅ Python Firebase initialized')
except Exception as e:
    print(f'❌ Error: {e}')
"

# 3. Verify GitHub Secrets are set
gh secret list

# 4. Check CI/CD can access secrets
# (Run a test workflow - should pass if secrets configured)
gh workflow view ci.yml --web
```

---

## Next Steps

### For Backend Team
1. ✅ Implement `/api/auth/verify` endpoint to validate Firebase tokens
2. ✅ Create `/api/farmer/farms` endpoint (uses Firebase to fetch farms)
3. ✅ Add Firebase sync on login (store device token)

### For Mobile Team
1. ✅ Add Firebase dependencies to `pubspec.yaml`
2. ✅ Create `lib/services/firebase_service.dart`
3. ✅ Implement offline sync using Firebase Realtime Database

### For DevOps
1. ✅ Create Firebase Firestore backups (automated)
2. ✅ Monitor Firebase usage and costs
3. ✅ Set up alerting for failed authentication

---

## Troubleshooting

### "Firebase credentials not found"
```bash
# Set environment variable with full JSON
export FIREBASE_CREDENTIALS_JSON='{"type":"service_account",...}'

# Or create local file
echo '{"type":"service_account",...}' > firebase-service-account.json
```

### "Database URL is required"
```bash
# Add to environment
export FIREBASE_DATABASE_URL=https://crop-ai-xxxxx.firebaseio.com
```

### "Authentication failed"
1. Check service account has permissions (in Google Cloud Console)
2. Verify private key is valid (no copy/paste errors)
3. Regenerate service account key if needed

### "CORS error from web"
1. In Firebase Console, go to **Settings** → **Authorized domains**
2. Add your domain (localhost:4200 for local dev)
3. Add production domain (crop-ai.yourdomain.com)

---

## Resources

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Admin SDK (Python)](https://firebase.google.com/docs/database/admin/start)
- [Firebase Web SDK (JavaScript)](https://firebase.google.com/docs/web/setup)
- [Firebase Realtime Database Rules](https://firebase.google.com/docs/database/security)
- [Firebase Authentication](https://firebase.google.com/docs/auth)

---

**Status:** 📋 Ready for manual setup  
**Time to complete:** 10-15 minutes  
**Last Updated:** December 10, 2025  
**Next:** After setup, run Priority B (Farm API endpoints)
