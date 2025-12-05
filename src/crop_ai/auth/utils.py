"""
JWT and password utilities for authentication.
"""
import os
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any, List
from uuid import uuid4
import jwt
from passlib.context import CryptContext
import logging

logger = logging.getLogger(__name__)

# Configuration
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY", "your-refresh-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Password context with Argon2
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")


def hash_password(password: str) -> str:
    """
    Hash password using Argon2.
    
    Args:
        password: Plain text password
        
    Returns:
        Hashed password
    """
    try:
        hashed = pwd_context.hash(password)
        logger.debug("Password hashed successfully")
        return hashed
    except Exception as e:
        logger.error(f"Error hashing password: {e}")
        raise


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Verify plain password against hashed password.
    
    Args:
        plain_password: Plain text password
        hashed_password: Hashed password
        
    Returns:
        True if password matches, False otherwise
    """
    try:
        is_valid = pwd_context.verify(plain_password, hashed_password)
        return is_valid
    except Exception as e:
        logger.error(f"Error verifying password: {e}")
        return False


def create_access_token(
    user_id: int,
    email: str,
    username: str,
    roles: List[str],
    permissions: List[str],
    expires_delta: Optional[timedelta] = None,
) -> str:
    """
    Create JWT access token.
    
    Args:
        user_id: User ID
        email: User email
        username: Username
        roles: List of role names
        permissions: List of permission names
        expires_delta: Custom expiry duration
        
    Returns:
        JWT token string
    """
    if expires_delta is None:
        expires_delta = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Remove duplicates from permissions
    permissions = list(set(permissions))
    
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode = {
        "sub": str(user_id),
        "email": email,
        "username": username,
        "roles": roles,
        "permissions": permissions,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "jti": uuid4().hex,  # JWT ID for blacklist support
        "type": "access",
    }
    
    try:
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        logger.debug(f"Access token created for user {user_id}")
        return encoded_jwt
    except Exception as e:
        logger.error(f"Error creating access token: {e}")
        raise


def create_refresh_token(user_id: int) -> str:
    """
    Create JWT refresh token.
    
    Args:
        user_id: User ID
        
    Returns:
        JWT refresh token string
    """
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode = {
        "sub": str(user_id),
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "type": "refresh",
        "jti": uuid4().hex,
    }
    
    try:
        encoded_jwt = jwt.encode(to_encode, REFRESH_SECRET_KEY, algorithm=ALGORITHM)
        logger.debug(f"Refresh token created for user {user_id}")
        return encoded_jwt
    except Exception as e:
        logger.error(f"Error creating refresh token: {e}")
        raise


def decode_token(token: str, token_type: str = "access") -> Dict[str, Any]:
    """
    Decode and validate JWT token.
    
    Args:
        token: JWT token string
        token_type: Token type ('access' or 'refresh')
        
    Returns:
        Decoded token payload
        
    Raises:
        jwt.ExpiredSignatureError: Token has expired
        jwt.InvalidTokenError: Token is invalid
    """
    secret_key = REFRESH_SECRET_KEY if token_type == "refresh" else SECRET_KEY
    
    try:
        payload = jwt.decode(token, secret_key, algorithms=[ALGORITHM])
        
        # Verify token type
        if payload.get("type") != token_type:
            raise jwt.InvalidTokenError("Invalid token type")
        
        logger.debug(f"Token decoded successfully (type: {token_type})")
        return payload
        
    except jwt.ExpiredSignatureError as e:
        logger.warning(f"Token expired: {e}")
        raise
    except jwt.InvalidTokenError as e:
        logger.warning(f"Invalid token: {e}")
        raise
    except Exception as e:
        logger.error(f"Error decoding token: {e}")
        raise jwt.InvalidTokenError(f"Token validation failed: {e}")


def verify_token_not_blacklisted(jti: str, blacklist_cache: Optional[set] = None) -> bool:
    """
    Check if token is in blacklist (for logout support).
    
    Args:
        jti: JWT ID from token
        blacklist_cache: Optional in-memory cache of blacklisted JTIs
        
    Returns:
        True if token is not blacklisted, False if it is
    """
    if blacklist_cache is None:
        blacklist_cache = set()
    
    is_blacklisted = jti in blacklist_cache
    
    if is_blacklisted:
        logger.warning(f"Token JTI {jti} is blacklisted")
    
    return not is_blacklisted


def add_token_to_blacklist(jti: str, expires_at: datetime, blacklist_cache: Optional[set] = None):
    """
    Add token to blacklist (for logout support).
    
    Args:
        jti: JWT ID from token
        expires_at: Token expiration time
        blacklist_cache: Optional in-memory cache of blacklisted JTIs
    """
    if blacklist_cache is None:
        blacklist_cache = set()
    
    blacklist_cache.add(jti)
    logger.info(f"Token JTI {jti} added to blacklist")
