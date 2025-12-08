"""
Authentication routes: login, refresh, logout, and profile endpoints.
"""
import logging
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from .dependencies import get_current_user, get_db
from .models import User
from .schemas import (
    ErrorResponse,
    RefreshTokenRequest,
    TokenRequest,
    TokenResponse,
    UserResponse,
)
from .utils import (
    add_token_to_blacklist,
    create_access_token,
    create_refresh_token,
    decode_token,
    verify_password,
    verify_token_not_blacklisted,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=TokenResponse, responses={400: {"model": ErrorResponse}})
async def login(
    request: TokenRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """
    User login endpoint.
    
    Returns access and refresh tokens on successful authentication.
    
    Args:
        request: Login credentials (email, password)
        db: Database session
        
    Returns:
        TokenResponse with access_token and refresh_token
        
    Raises:
        HTTPException: If credentials are invalid
    """
    try:
        # Find user by email
        user = db.query(User).filter(User.email == request.email).first()
        
        if not user:
            logger.warning(f"Login attempt with non-existent email: {request.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        
        # Verify password
        if not verify_password(request.password, user.password_hash):
            logger.warning(f"Login attempt with wrong password for user: {request.email}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        
        if not user.is_active:
            logger.warning(f"Login attempt by inactive user: {request.email}")
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is inactive",
            )
        
        # Get user roles
        user_roles = [role.name for role in user.roles]
        
        # Get user permissions
        user_permissions = set()
        for role in user.roles:
            for permission in role.permissions:
                user_permissions.add(permission.name)
        
        # Create tokens
        access_token = create_access_token(
            user_id=user.id,
            email=user.email,
            username=user.username,
            roles=user_roles,
            permissions=list(user_permissions),
        )
        
        refresh_token = create_refresh_token(user_id=user.id)
        
        # Update last login
        user.last_login = datetime.utcnow()
        db.commit()
        
        logger.info(f"User logged in successfully: {user.email}")
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=900,  # 15 minutes in seconds
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    responses={401: {"model": ErrorResponse}},
)
async def refresh_token(
    request: RefreshTokenRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    """
    Refresh access token using a refresh token.
    
    Args:
        request: Refresh token request
        db: Database session
        
    Returns:
        TokenResponse with new access_token
        
    Raises:
        HTTPException: If refresh token is invalid
    """
    try:
        # Decode refresh token
        payload = decode_token(request.refresh_token, token_type="refresh")
        
        user_id = int(payload.get("sub"))
        
        # Verify token is not blacklisted
        token_jti = payload.get("jti")
        if not verify_token_not_blacklisted(token_jti):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has been revoked",
            )
        
        # Get user
        user = db.query(User).filter(User.id == user_id, User.is_active).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive",
            )
        
        # Get user roles and permissions
        user_roles = [role.name for role in user.roles]
        
        user_permissions = set()
        for role in user.roles:
            for permission in role.permissions:
                user_permissions.add(permission.name)
        
        # Create new access token
        access_token = create_access_token(
            user_id=user.id,
            email=user.email,
            username=user.username,
            roles=user_roles,
            permissions=list(user_permissions),
        )
        
        logger.info(f"Token refreshed for user: {user.email}")
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=request.refresh_token,  # Keep same refresh token
            token_type="bearer",
            expires_in=900,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token refresh error: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
        )


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    responses={401: {"model": ErrorResponse}},
)
async def logout(
    current_user: dict = Depends(get_current_user),
) -> None:
    """
    User logout endpoint.
    
    Invalidates the current access token by adding it to blacklist.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        No content (204)
    """
    try:
        # Get token JTI from current_user (should be added during token creation)
        # This is optional and depends on token blacklist implementation
        token_jti = current_user.get("jti")
        
        if token_jti:
            # Add to blacklist
            expires_at = datetime.utcnow() + timedelta(days=7)
            add_token_to_blacklist(token_jti, expires_at)
        
        logger.info(f"User logged out: {current_user.get('email')}")
        
    except Exception as e:
        logger.error(f"Logout error: {e}")
        # Don't raise - logout should always succeed


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserResponse:
    """
    Get current authenticated user's profile information.
    
    Args:
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        UserResponse with user details
    """
    try:
        user_id = current_user.get("user_id")
        
        user = db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        
        logger.debug(f"Retrieved profile for user: {user.email}")
        
        return UserResponse.from_orm(user)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get user profile error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error",
        )


@router.post("/verify", responses={401: {"model": ErrorResponse}})
async def verify_token_endpoint(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Verify that the provided token is valid.
    
    Useful for client-side token validation.
    
    Args:
        current_user: Current authenticated user
        
    Returns:
        User info from token
    """
    return {
        "valid": True,
        "user_id": current_user.get("user_id"),
        "email": current_user.get("email"),
        "username": current_user.get("username"),
        "roles": current_user.get("roles", []),
        "permissions": current_user.get("permissions", []),
    }
