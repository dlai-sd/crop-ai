"""
Authentication and Authorization module for crop-ai.

Provides JWT-based authentication, role-based access control (RBAC),
and password management for the crop identification API.

Features:
- JWT tokens (15-min access, 7-day refresh)
- Argon2 password hashing
- Role-based access control (RBAC) with 4 predefined roles
- 10+ granular permissions
- Token blacklisting for logout support
- Session tracking
- Comprehensive error handling and logging

Example usage:
    from fastapi import FastAPI, Depends
    from crop_ai.auth import auth_router, require_permission

    app = FastAPI()
    app.include_router(auth_router)

    @app.get("/protected")
    async def protected_endpoint(
        current_user: dict = Depends(require_permission("crops:read"))
    ):
        return {"user": current_user["email"]}
"""

from .crud import (
    assign_permission_to_role,
    create_permission,
    create_role,
    create_user,
    delete_user,
    get_permission,
    get_permission_by_name,
    get_role,
    get_role_by_name,
    get_role_permissions,
    get_user,
    get_user_by_email,
    get_user_by_username,
    get_user_permissions,
    list_permissions,
    list_roles,
    list_users,
    remove_permission_from_role,
    remove_role_from_user,
    update_user,
    assign_role_to_user,
)
from .dependencies import (
    get_current_user,
    get_db,
    require_all_permissions,
    require_any_permission,
    require_permission,
    require_role,
)
from .models import Permission, Role, Session as AuthSession, TokenBlacklist, User
from .routes import router as auth_router
from .schemas import (
    ErrorResponse,
    PermissionResponse,
    RefreshTokenRequest,
    RoleResponse,
    SessionResponse,
    TokenRequest,
    TokenResponse,
    UserCreate,
    UserResponse,
    UserUpdate,
)
from .utils import (
    add_token_to_blacklist,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
    verify_token_not_blacklisted,
)
from .init_db import init_auth_db, get_init_summary

__all__ = [
    # Models
    "User",
    "Role",
    "Permission",
    "AuthSession",
    "TokenBlacklist",
    # Schemas
    "TokenRequest",
    "TokenResponse",
    "RefreshTokenRequest",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    "RoleResponse",
    "PermissionResponse",
    "SessionResponse",
    "ErrorResponse",
    # Utils
    "hash_password",
    "verify_password",
    "create_access_token",
    "create_refresh_token",
    "decode_token",
    "verify_token_not_blacklisted",
    "add_token_to_blacklist",
    # Dependencies
    "get_current_user",
    "require_permission",
    "require_role",
    "require_any_permission",
    "require_all_permissions",
    "get_db",
    # CRUD
    "create_user",
    "get_user",
    "get_user_by_email",
    "get_user_by_username",
    "list_users",
    "update_user",
    "delete_user",
    "create_role",
    "get_role",
    "get_role_by_name",
    "list_roles",
    "create_permission",
    "get_permission",
    "get_permission_by_name",
    "list_permissions",
    "assign_role_to_user",
    "remove_role_from_user",
    "get_user_roles",
    "assign_permission_to_role",
    "remove_permission_from_role",
    "get_role_permissions",
    "get_user_permissions",
    # Routes
    "auth_router",
    # Database
    "init_auth_db",
    "get_init_summary",
]
