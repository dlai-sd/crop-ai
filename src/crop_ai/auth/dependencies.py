"""
Dependency injection and decorators for protected routes.
"""
import logging
from typing import List

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session

from .models import User
from .utils import decode_token

logger = logging.getLogger(__name__)

security = HTTPBearer()


def get_db() -> Session:
    """
    Dependency to get database session.
    
    This should be implemented in your main database module.
    For now, this is a placeholder that should be replaced with
    actual database session dependency.
    """
    raise NotImplementedError("Database dependency not configured. Implement in your app.")


async def get_current_user(
    credentials=Depends(security),
    db: Session = Depends(get_db),
) -> dict:
    """
    Get current authenticated user from JWT token.

    Args:
        credentials: HTTP bearer credentials
        db: Database session

    Returns:
        Decoded token payload with user info

    Raises:
        HTTPException: If token is invalid or expired
    """
    token = credentials.credentials
    
    try:
        payload = decode_token(token, token_type="access")
    except Exception as e:
        logger.warning(f"Token validation failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid or expired token: {str(e)}",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_id = int(payload.get("sub"))
    email = payload.get("email")
    
    if user_id is None or email is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token claims",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify user still exists and is active
    try:
        user = db.query(User).filter(User.id == user_id, User.is_active).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive",
                headers={"WWW-Authenticate": "Bearer"},
            )
    except Exception as e:
        logger.error(f"Error querying user: {e}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Failed to validate user",
        )
    
    # Add user info to payload
    payload["user_id"] = user_id
    
    logger.debug(f"Current user authenticated: {email}")
    return payload


async def require_permission(
    required_permission: str,
) -> callable:
    """
    Create a dependency that requires a specific permission.
    
    Usage:
        @router.get("/admin")
        async def admin_endpoint(
            current_user: dict = Depends(require_permission("admin:access"))
        ):
            return {"message": "Admin only"}
    
    Args:
        required_permission: Required permission name (e.g., "crops:create")
        
    Returns:
        Dependency function
    """
    async def check_permission(
        current_user: dict = Depends(get_current_user),
    ) -> dict:
        """Check if user has required permission."""
        user_permissions = current_user.get("permissions", [])
        
        if required_permission not in user_permissions:
            logger.warning(
                f"User {current_user.get('user_id')} denied access: "
                f"missing permission '{required_permission}'"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission '{required_permission}' required",
            )
        
        logger.debug(
            f"User {current_user.get('user_id')} granted access "
            f"(permission: {required_permission})"
        )
        return current_user
    
    return check_permission


async def require_role(
    required_role: str,
) -> callable:
    """
    Create a dependency that requires a specific role.
    
    Usage:
        @router.get("/admin")
        async def admin_endpoint(current_user: dict = Depends(require_role("ADMIN"))):
            return {"message": "Admin only"}
    
    Args:
        required_role: Required role name (e.g., "ADMIN")
        
    Returns:
        Dependency function
    """
    async def check_role(
        current_user: dict = Depends(get_current_user),
    ) -> dict:
        """Check if user has required role."""
        user_roles = current_user.get("roles", [])
        
        if required_role not in user_roles:
            logger.warning(
                f"User {current_user.get('user_id')} denied access: "
                f"missing role '{required_role}'"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role '{required_role}' required",
            )
        
        logger.debug(
            f"User {current_user.get('user_id')} granted access "
            f"(role: {required_role})"
        )
        return current_user
    
    return check_role


def require_any_permission(
    permissions: List[str],
) -> callable:
    """
    Create a dependency that requires any of the specified permissions.
    
    Args:
        permissions: List of permission names
        
    Returns:
        Dependency function
    """
    async def check_any_permission(
        current_user: dict = Depends(get_current_user),
    ) -> dict:
        """Check if user has any of the required permissions."""
        user_permissions = set(current_user.get("permissions", []))
        required_permissions = set(permissions)
        
        if not user_permissions & required_permissions:
            logger.warning(
                f"User {current_user.get('user_id')} denied access: "
                f"missing any of {permissions}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"One of these permissions required: {', '.join(permissions)}",
            )
        
        logger.debug(
            f"User {current_user.get('user_id')} granted access "
            f"(permissions: {user_permissions & required_permissions})"
        )
        return current_user
    
    return check_any_permission


def require_all_permissions(
    permissions: List[str],
) -> callable:
    """
    Create a dependency that requires all of the specified permissions.
    
    Args:
        permissions: List of permission names
        
    Returns:
        Dependency function
    """
    async def check_all_permissions(
        current_user: dict = Depends(get_current_user),
    ) -> dict:
        """Check if user has all required permissions."""
        user_permissions = set(current_user.get("permissions", []))
        required_permissions = set(permissions)
        
        if not required_permissions.issubset(user_permissions):
            missing = required_permissions - user_permissions
            logger.warning(
                f"User {current_user.get('user_id')} denied access: "
                f"missing permissions {missing}"
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"All these permissions required: {', '.join(permissions)}",
            )
        
        logger.debug(
            f"User {current_user.get('user_id')} granted access "
            f"(all permissions: {permissions})"
        )
        return current_user
    
    return check_all_permissions
