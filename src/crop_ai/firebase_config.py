"""
Firebase Admin SDK Configuration for Crop AI Backend
Generated: December 10, 2025

This module initializes Firebase Admin SDK for:
- Authentication token verification
- Realtime Database access
- Cloud Storage for farm images
- Cloud Messaging for push notifications
"""

import os
import json
from pathlib import Path
import firebase_admin
from firebase_admin import credentials
from firebase_admin import auth as firebase_auth
from firebase_admin import db as firebase_db
from firebase_admin import storage as firebase_storage
from firebase_admin import messaging as firebase_messaging

# ============================================================================
# FIREBASE CREDENTIALS SETUP
# ============================================================================

def init_firebase():
    """Initialize Firebase Admin SDK with credentials from environment or file."""
    
    # Check if Firebase is already initialized
    if firebase_admin._apps:
        return
    
    # Try to load credentials from multiple sources
    cred = None
    
    # 1. Try environment variable: FIREBASE_CREDENTIALS_JSON
    firebase_creds_json = os.getenv('FIREBASE_CREDENTIALS_JSON')
    if firebase_creds_json:
        try:
            cred_dict = json.loads(firebase_creds_json)
            cred = credentials.Certificate(cred_dict)
            print("✅ Firebase: Loaded credentials from FIREBASE_CREDENTIALS_JSON env var")
        except json.JSONDecodeError as e:
            print(f"❌ Firebase: Failed to parse FIREBASE_CREDENTIALS_JSON: {e}")
    
    # 2. Try local service account file (development only)
    if not cred:
        service_account_path = Path(__file__).parent / "firebase-service-account.json"
        if service_account_path.exists():
            try:
                cred = credentials.Certificate(str(service_account_path))
                print(f"✅ Firebase: Loaded credentials from {service_account_path}")
            except Exception as e:
                print(f"⚠️  Firebase: Failed to load service account file: {e}")
    
    # 3. Try default credentials (Google Cloud environment)
    if not cred:
        try:
            cred = credentials.ApplicationDefault()
            print("✅ Firebase: Loaded credentials from Google Cloud Application Default")
        except Exception as e:
            print(f"⚠️  Firebase: Failed to load application default credentials: {e}")
    
    # Initialize Firebase with credentials
    if cred:
        database_url = os.getenv('FIREBASE_DATABASE_URL')
        if database_url:
            firebase_admin.initialize_app(cred, {
                'databaseURL': database_url
            })
            print(f"✅ Firebase Admin SDK initialized with database: {database_url}")
        else:
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialized (no database URL)")
    else:
        print("❌ Firebase: No credentials found. Set FIREBASE_CREDENTIALS_JSON or firebase-service-account.json")
        raise RuntimeError("Firebase credentials not configured")


# ============================================================================
# FIREBASE SERVICE INSTANCES
# ============================================================================

def get_auth_service():
    """Get Firebase Authentication service."""
    return firebase_auth


def get_database_service():
    """Get Firebase Realtime Database service."""
    return firebase_db.reference()


def get_storage_service():
    """Get Firebase Storage service."""
    bucket_name = os.getenv('FIREBASE_STORAGE_BUCKET')
    if bucket_name:
        return firebase_storage.bucket(bucket_name)
    return None


def get_messaging_service():
    """Get Firebase Cloud Messaging service."""
    return firebase_messaging


# ============================================================================
# FIREBASE UTILITIES
# ============================================================================

def verify_firebase_token(token: str) -> dict:
    """
    Verify Firebase ID token from mobile/web client.
    
    Args:
        token: Firebase ID token from client
        
    Returns:
        Decoded token claims containing user info
        
    Raises:
        firebase_admin.auth.InvalidIdTokenError: If token is invalid
    """
    try:
        decoded_token = firebase_auth.verify_id_token(token)
        return decoded_token
    except firebase_admin.auth.InvalidIdTokenError as e:
        print(f"Invalid Firebase token: {e}")
        raise


def get_firebase_user(uid: str) -> dict:
    """
    Get Firebase user details by UID.
    
    Args:
        uid: Firebase user UID
        
    Returns:
        Firebase user record
    """
    try:
        user = firebase_auth.get_user(uid)
        return {
            'uid': user.uid,
            'email': user.email,
            'display_name': user.display_name,
            'phone_number': user.phone_number,
            'custom_claims': user.custom_claims,
        }
    except firebase_admin.auth.UserNotFoundError:
        return None


# ============================================================================
# DATABASE OPERATIONS (Realtime Database)
# ============================================================================

def save_farm_sync(user_id: str, farm_id: str, sync_data: dict):
    """
    Save offline farm changes to Firebase Realtime Database for sync.
    
    Args:
        user_id: Firebase user UID
        farm_id: Farm ID
        sync_data: Changes to sync {timestamp, changes}
    """
    ref = firebase_db.reference()
    ref.child(f'users/{user_id}/farm_syncs/{farm_id}').set(sync_data)


def get_farm_weather(farm_id: str) -> dict:
    """
    Fetch live weather data from Firebase Realtime Database.
    
    Args:
        farm_id: Farm ID
        
    Returns:
        Weather forecast data
    """
    ref = firebase_db.reference()
    snapshot = ref.child(f'weather/{farm_id}').get()
    return snapshot.val() if snapshot.exists() else None


# ============================================================================
# CLOUD MESSAGING (Push Notifications)
# ============================================================================

def send_push_notification(user_id: str, title: str, body: str, data: dict = None):
    """
    Send push notification to farmer's device via Firebase Cloud Messaging.
    
    Args:
        user_id: Firebase user UID
        title: Notification title
        body: Notification body
        data: Custom data payload
    """
    try:
        message = firebase_messaging.Message(
            notification=firebase_messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=user_id,  # Should be device FCM token in production
        )
        response = firebase_messaging.send(message)
        print(f"✅ Notification sent: {response}")
        return response
    except Exception as e:
        print(f"❌ Failed to send notification: {e}")


# ============================================================================
# INITIALIZATION
# ============================================================================

# Initialize Firebase when module is imported
try:
    init_firebase()
except RuntimeError as e:
    print(f"Firebase initialization error: {e}")
    # Continue with app - some endpoints may work without Firebase
