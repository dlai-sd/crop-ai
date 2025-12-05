"""
SSO provider handling for OAuth 2.0 authentication.

Supports:
- Google OAuth
- Microsoft OAuth
- Facebook OAuth
"""
import os
import httpx
import secrets
import json
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from urllib.parse import urlencode
from pydantic import BaseModel, EmailStr


# ============================================================================
# SSO Configuration Models
# ============================================================================

class SSOConfig(BaseModel):
    """SSO provider configuration."""
    client_id: str
    client_secret: str
    redirect_uri: str
    scope: list[str]
    authorization_url: str
    token_url: str
    userinfo_url: str


# ============================================================================
# SSO User Information Models
# ============================================================================

class SSOUserInfo(BaseModel):
    """Normalized user information from SSO provider."""
    provider: str
    provider_user_id: str
    email: Optional[EmailStr] = None
    name: Optional[str] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None
    profile_picture_url: Optional[str] = None
    email_verified: bool = False


class SSOTokenResponse(BaseModel):
    """OAuth token response."""
    access_token: str
    refresh_token: Optional[str] = None
    expires_in: int
    token_type: str
    id_token: Optional[str] = None  # OIDC
    scope: Optional[str] = None


# ============================================================================
# Google OAuth Provider
# ============================================================================

class GoogleOAuthProvider:
    """Google OAuth 2.0 provider."""
    
    PROVIDER_NAME = "google"
    AUTHORIZATION_URL = "https://accounts.google.com/o/oauth2/v2/auth"
    TOKEN_URL = "https://oauth2.googleapis.com/token"
    USERINFO_URL = "https://www.googleapis.com/oauth2/v1/userinfo"
    
    def __init__(self, client_id: str, client_secret: str, redirect_uri: str):
        """Initialize Google OAuth provider."""
        self.client_id = client_id
        self.client_secret = client_secret
        self.redirect_uri = redirect_uri
        self.config = SSOConfig(
            client_id=client_id,
            client_secret=client_secret,
            redirect_uri=redirect_uri,
            scope=["openid", "email", "profile"],
            authorization_url=self.AUTHORIZATION_URL,
            token_url=self.TOKEN_URL,
            userinfo_url=self.USERINFO_URL,
        )
    
    def get_authorization_url(self, state: str) -> str:
        """Get authorization URL for user redirect."""
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "response_type": "code",
            "scope": " ".join(self.config.scope),
            "state": state,
            "access_type": "offline",
            "prompt": "consent",
        }
        return f"{self.AUTHORIZATION_URL}?{urlencode(params)}"
    
    async def exchange_code_for_token(self, code: str) -> SSOTokenResponse:
        """Exchange authorization code for access token."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": self.redirect_uri,
                    "grant_type": "authorization_code",
                },
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            return SSOTokenResponse(
                access_token=data["access_token"],
                refresh_token=data.get("refresh_token"),
                expires_in=data.get("expires_in", 3600),
                token_type=data.get("token_type", "Bearer"),
                id_token=data.get("id_token"),
            )
    
    async def get_user_info(self, access_token: str) -> SSOUserInfo:
        """Get user information from Google."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.USERINFO_URL,
                headers={"Authorization": f"Bearer {access_token}"},
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            
            return SSOUserInfo(
                provider=self.PROVIDER_NAME,
                provider_user_id=data["id"],
                email=data.get("email"),
                name=data.get("name"),
                given_name=data.get("given_name"),
                family_name=data.get("family_name"),
                profile_picture_url=data.get("picture"),
                email_verified=data.get("verified_email", False),
            )


# ============================================================================
# Microsoft OAuth Provider
# ============================================================================

class MicrosoftOAuthProvider:
    """Microsoft OAuth 2.0 provider."""
    
    PROVIDER_NAME = "microsoft"
    AUTHORIZATION_URL = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
    TOKEN_URL = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
    USERINFO_URL = "https://graph.microsoft.com/v1.0/me"
    PHOTO_URL = "https://graph.microsoft.com/v1.0/me/photo/$value"
    
    def __init__(self, client_id: str, client_secret: str, redirect_uri: str):
        """Initialize Microsoft OAuth provider."""
        self.client_id = client_id
        self.client_secret = client_secret
        self.redirect_uri = redirect_uri
        self.config = SSOConfig(
            client_id=client_id,
            client_secret=client_secret,
            redirect_uri=redirect_uri,
            scope=["openid", "email", "profile", "https://graph.microsoft.com/.default"],
            authorization_url=self.AUTHORIZATION_URL,
            token_url=self.TOKEN_URL,
            userinfo_url=self.USERINFO_URL,
        )
    
    def get_authorization_url(self, state: str) -> str:
        """Get authorization URL for user redirect."""
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "response_type": "code",
            "scope": "openid email profile https://graph.microsoft.com/.default",
            "state": state,
            "response_mode": "query",
        }
        return f"{self.AUTHORIZATION_URL}?{urlencode(params)}"
    
    async def exchange_code_for_token(self, code: str) -> SSOTokenResponse:
        """Exchange authorization code for access token."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": self.redirect_uri,
                    "grant_type": "authorization_code",
                    "scope": "https://graph.microsoft.com/.default",
                },
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            return SSOTokenResponse(
                access_token=data["access_token"],
                refresh_token=data.get("refresh_token"),
                expires_in=data.get("expires_in", 3600),
                token_type=data.get("token_type", "Bearer"),
                id_token=data.get("id_token"),
            )
    
    async def get_user_info(self, access_token: str) -> SSOUserInfo:
        """Get user information from Microsoft."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.USERINFO_URL,
                headers={"Authorization": f"Bearer {access_token}"},
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            
            # Try to get profile photo
            photo_url = None
            try:
                photo_response = await client.get(
                    self.PHOTO_URL,
                    headers={"Authorization": f"Bearer {access_token}"},
                    timeout=10,
                )
                if photo_response.status_code == 200:
                    # For demonstration; in production, store in blob storage
                    photo_url = f"data:image/jpeg;base64,{photo_response.content.hex()[:50]}..."
            except Exception:
                pass  # Photo retrieval is optional
            
            return SSOUserInfo(
                provider=self.PROVIDER_NAME,
                provider_user_id=data["id"],
                email=data.get("userPrincipalName") or data.get("mail"),
                name=data.get("displayName"),
                given_name=data.get("givenName"),
                family_name=data.get("surname"),
                profile_picture_url=photo_url,
                email_verified=True,
            )


# ============================================================================
# Facebook OAuth Provider
# ============================================================================

class FacebookOAuthProvider:
    """Facebook OAuth 2.0 provider."""
    
    PROVIDER_NAME = "facebook"
    AUTHORIZATION_URL = "https://www.facebook.com/v18.0/dialog/oauth"
    TOKEN_URL = "https://graph.facebook.com/v18.0/oauth/access_token"
    USERINFO_URL = "https://graph.facebook.com/me"
    
    def __init__(self, client_id: str, client_secret: str, redirect_uri: str):
        """Initialize Facebook OAuth provider."""
        self.client_id = client_id
        self.client_secret = client_secret
        self.redirect_uri = redirect_uri
        self.config = SSOConfig(
            client_id=client_id,
            client_secret=client_secret,
            redirect_uri=redirect_uri,
            scope=["email", "public_profile"],
            authorization_url=self.AUTHORIZATION_URL,
            token_url=self.TOKEN_URL,
            userinfo_url=self.USERINFO_URL,
        )
    
    def get_authorization_url(self, state: str) -> str:
        """Get authorization URL for user redirect."""
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "scope": ",".join(self.config.scope),
            "state": state,
            "response_type": "code",
            "auth_type": "reauthenticate",
        }
        return f"{self.AUTHORIZATION_URL}?{urlencode(params)}"
    
    async def exchange_code_for_token(self, code: str) -> SSOTokenResponse:
        """Exchange authorization code for access token."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.TOKEN_URL,
                data={
                    "code": code,
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "redirect_uri": self.redirect_uri,
                },
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            return SSOTokenResponse(
                access_token=data["access_token"],
                expires_in=data.get("expires_in", 5184000),  # 60 days default
                token_type="Bearer",
            )
    
    async def get_user_info(self, access_token: str) -> SSOUserInfo:
        """Get user information from Facebook."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                self.USERINFO_URL,
                params={
                    "fields": "id,name,email,picture.type(large)",
                    "access_token": access_token,
                },
                timeout=10,
            )
            response.raise_for_status()
            data = response.json()
            
            picture_url = None
            if "picture" in data and "data" in data["picture"]:
                picture_url = data["picture"]["data"].get("url")
            
            return SSOUserInfo(
                provider=self.PROVIDER_NAME,
                provider_user_id=data["id"],
                email=data.get("email"),
                name=data.get("name"),
                profile_picture_url=picture_url,
                email_verified=False,  # Facebook doesn't guarantee email verification
            )


# ============================================================================
# SSO Manager
# ============================================================================

class SSOProviderManager:
    """Manages multiple SSO providers."""
    
    def __init__(self):
        """Initialize SSO provider manager."""
        self.providers: Dict[str, Any] = {}
        self._state_store: Dict[str, Dict[str, Any]] = {}  # In-memory; use Redis in production
    
    def register_provider(self, provider_name: str, provider_instance):
        """Register an SSO provider."""
        self.providers[provider_name.lower()] = provider_instance
    
    def get_provider(self, provider_name: str):
        """Get an SSO provider by name."""
        provider = self.providers.get(provider_name.lower())
        if not provider:
            raise ValueError(f"Unknown SSO provider: {provider_name}")
        return provider
    
    def generate_state(self, provider_name: str, registration_id: str) -> str:
        """Generate and store OAuth state."""
        state = secrets.token_urlsafe(32)
        self._state_store[state] = {
            "provider": provider_name,
            "registration_id": registration_id,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(minutes=10),
        }
        return state
    
    def validate_state(self, state: str) -> Optional[Dict[str, Any]]:
        """Validate and retrieve OAuth state."""
        state_data = self._state_store.get(state)
        if not state_data:
            return None
        
        # Check expiration
        if datetime.utcnow() > state_data["expires_at"]:
            del self._state_store[state]
            return None
        
        # Clean up used state
        del self._state_store[state]
        return state_data
    
    def get_authorization_url(
        self,
        provider_name: str,
        registration_id: str,
    ) -> tuple[str, str]:  # (url, state)
        """Get authorization URL for SSO provider."""
        provider = self.get_provider(provider_name)
        state = self.generate_state(provider_name, registration_id)
        url = provider.get_authorization_url(state)
        return url, state
    
    async def handle_callback(
        self,
        provider_name: str,
        code: str,
        state: str,
    ) -> tuple[SSOUserInfo, SSOTokenResponse]:
        """Handle SSO callback and get user information."""
        # Validate state
        state_data = self.validate_state(state)
        if not state_data:
            raise ValueError("Invalid or expired state")
        
        if state_data["provider"].lower() != provider_name.lower():
            raise ValueError("State provider mismatch")
        
        # Get provider
        provider = self.get_provider(provider_name)
        
        # Exchange code for token
        token_response = await provider.exchange_code_for_token(code)
        
        # Get user information
        user_info = await provider.get_user_info(token_response.access_token)
        
        return user_info, token_response


# ============================================================================
# Factory Functions
# ============================================================================

def create_sso_manager() -> SSOProviderManager:
    """Create and configure SSO manager with providers from environment."""
    manager = SSOProviderManager()
    
    # Google OAuth
    google_client_id = os.getenv("GOOGLE_CLIENT_ID")
    google_client_secret = os.getenv("GOOGLE_CLIENT_SECRET")
    google_redirect_uri = os.getenv("GOOGLE_REDIRECT_URI", "http://localhost:8000/auth/sso/google/callback")
    
    if google_client_id and google_client_secret:
        manager.register_provider(
            "google",
            GoogleOAuthProvider(google_client_id, google_client_secret, google_redirect_uri),
        )
    
    # Microsoft OAuth
    microsoft_client_id = os.getenv("MICROSOFT_CLIENT_ID")
    microsoft_client_secret = os.getenv("MICROSOFT_CLIENT_SECRET")
    microsoft_redirect_uri = os.getenv("MICROSOFT_REDIRECT_URI", "http://localhost:8000/auth/sso/microsoft/callback")
    
    if microsoft_client_id and microsoft_client_secret:
        manager.register_provider(
            "microsoft",
            MicrosoftOAuthProvider(microsoft_client_id, microsoft_client_secret, microsoft_redirect_uri),
        )
    
    # Facebook OAuth
    facebook_client_id = os.getenv("FACEBOOK_CLIENT_ID")
    facebook_client_secret = os.getenv("FACEBOOK_CLIENT_SECRET")
    facebook_redirect_uri = os.getenv("FACEBOOK_REDIRECT_URI", "http://localhost:8000/auth/sso/facebook/callback")
    
    if facebook_client_id and facebook_client_secret:
        manager.register_provider(
            "facebook",
            FacebookOAuthProvider(facebook_client_id, facebook_client_secret, facebook_redirect_uri),
        )
    
    return manager


# ============================================================================
# Singleton Instance
# ============================================================================

sso_manager: Optional[SSOProviderManager] = None


def get_sso_manager() -> SSOProviderManager:
    """Get or create SSO manager singleton."""
    global sso_manager
    if sso_manager is None:
        sso_manager = create_sso_manager()
    return sso_manager
