"""
Initialize authentication database with default roles and permissions.
"""
import logging
from typing import List, Tuple

from sqlalchemy.orm import Session

from .crud import (
    assign_permission_to_role,
    assign_role_to_user,
    create_permission,
    create_role,
    create_user,
    get_permission_by_name,
    get_role_by_name,
)
from .models import Permission, Role, User

logger = logging.getLogger(__name__)


# Define roles and their permissions
ROLES_PERMISSIONS = {
    "ADMIN": [
        "users:create",
        "users:read",
        "users:update",
        "users:delete",
        "roles:create",
        "roles:read",
        "roles:update",
        "roles:delete",
        "permissions:create",
        "permissions:read",
        "permissions:update",
        "permissions:delete",
        "crops:create",
        "crops:read",
        "crops:update",
        "crops:delete",
        "analyses:create",
        "analyses:read",
        "analyses:update",
        "analyses:delete",
        "reports:create",
        "reports:read",
        "reports:update",
        "reports:delete",
    ],
    "MANAGER": [
        "users:read",
        "users:update",
        "crops:create",
        "crops:read",
        "crops:update",
        "analyses:create",
        "analyses:read",
        "analyses:update",
        "analyses:delete",
        "reports:create",
        "reports:read",
        "reports:update",
    ],
    "ANALYST": [
        "crops:read",
        "analyses:create",
        "analyses:read",
        "analyses:update",
        "reports:create",
        "reports:read",
    ],
    "VIEWER": [
        "crops:read",
        "analyses:read",
        "reports:read",
    ],
}

# Default admin user credentials
DEFAULT_ADMIN = {
    "email": "admin@cropai.dev",
    "username": "admin",
    "password": "admin123!",  # CHANGE IN PRODUCTION!
}


def get_all_permissions() -> List[Tuple[str, str]]:
    """
    Get all permission definitions.
    
    Returns:
        List of (name, description) tuples
    """
    return [
        # User management
        ("users:create", "Create new users"),
        ("users:read", "Read user information"),
        ("users:update", "Update user information"),
        ("users:delete", "Delete users"),
        
        # Role management
        ("roles:create", "Create new roles"),
        ("roles:read", "Read role information"),
        ("roles:update", "Update roles"),
        ("roles:delete", "Delete roles"),
        
        # Permission management
        ("permissions:create", "Create new permissions"),
        ("permissions:read", "Read permission information"),
        ("permissions:update", "Update permissions"),
        ("permissions:delete", "Delete permissions"),
        
        # Crop management
        ("crops:create", "Create crop records"),
        ("crops:read", "Read crop information"),
        ("crops:update", "Update crop information"),
        ("crops:delete", "Delete crop records"),
        
        # Analysis management
        ("analyses:create", "Create analyses"),
        ("analyses:read", "Read analysis results"),
        ("analyses:update", "Update analyses"),
        ("analyses:delete", "Delete analyses"),
        
        # Report generation
        ("reports:create", "Generate reports"),
        ("reports:read", "Read reports"),
        ("reports:update", "Update reports"),
        ("reports:delete", "Delete reports"),
    ]


def init_permissions(db: Session) -> dict:
    """
    Create all permissions in the database.
    
    Args:
        db: Database session
        
    Returns:
        Dictionary mapping permission names to Permission objects
    """
    logger.info("Initializing permissions...")
    
    permissions = {}
    
    for perm_name, perm_desc in get_all_permissions():
        # Check if permission already exists
        existing = get_permission_by_name(db, perm_name)
        
        if existing:
            logger.debug(f"Permission already exists: {perm_name}")
            permissions[perm_name] = existing
        else:
            try:
                perm = create_permission(db, perm_name, perm_desc)
                permissions[perm_name] = perm
            except ValueError as e:
                logger.warning(f"Could not create permission {perm_name}: {e}")
    
    logger.info(f"Initialized {len(permissions)} permissions")
    return permissions


def init_roles(db: Session, permissions: dict) -> dict:
    """
    Create all roles and assign permissions.
    
    Args:
        db: Database session
        permissions: Dictionary of Permission objects
        
    Returns:
        Dictionary mapping role names to Role objects
    """
    logger.info("Initializing roles...")
    
    roles = {}
    
    for role_name, role_permissions in ROLES_PERMISSIONS.items():
        # Check if role already exists
        existing = get_role_by_name(db, role_name)
        
        if existing:
            logger.debug(f"Role already exists: {role_name}")
            role = existing
        else:
            try:
                role = create_role(db, role_name, f"{role_name} role")
            except ValueError as e:
                logger.warning(f"Could not create role {role_name}: {e}")
                continue
        
        # Assign permissions to role
        for perm_name in role_permissions:
            if perm_name in permissions:
                try:
                    # Check if permission already assigned
                    if permissions[perm_name] not in role.permissions:
                        assign_permission_to_role(db, role.id, permissions[perm_name].id)
                except Exception as e:
                    logger.warning(f"Could not assign {perm_name} to {role_name}: {e}")
        
        roles[role_name] = role
    
    logger.info(f"Initialized {len(roles)} roles")
    return roles


def init_admin_user(db: Session, roles: dict) -> bool:
    """
    Create default admin user if it doesn't exist.
    
    Args:
        db: Database session
        roles: Dictionary of Role objects
        
    Returns:
        True if admin user created/exists, False if error
    """
    logger.info("Initializing admin user...")
    
    # Check if admin user already exists
    from .crud import get_user_by_email
    
    existing_admin = get_user_by_email(db, DEFAULT_ADMIN["email"])
    
    if existing_admin:
        logger.debug("Admin user already exists")
        return True
    
    try:
        admin_user = create_user(
            db,
            email=DEFAULT_ADMIN["email"],
            username=DEFAULT_ADMIN["username"],
            password=DEFAULT_ADMIN["password"],
            is_active=True,
        )
        
        # Assign ADMIN role
        if "ADMIN" in roles:
            assign_role_to_user(db, admin_user.id, roles["ADMIN"].id)
            logger.info(f"Admin user created: {DEFAULT_ADMIN['email']}")
            logger.warning("!!! CHANGE DEFAULT ADMIN PASSWORD IN PRODUCTION !!!")
        
        return True
        
    except Exception as e:
        logger.error(f"Could not create admin user: {e}")
        return False


def init_auth_db(db: Session, create_admin: bool = False) -> bool:
    """
    Initialize authentication database with roles and permissions.
    
    This function should be called during application startup to ensure
    all required roles and permissions exist.
    
    Args:
        db: Database session
        create_admin: If True, also create default admin user
        
    Returns:
        True if successful, False otherwise
    """
    logger.info("Starting authentication database initialization...")
    
    try:
        # Initialize permissions
        permissions = init_permissions(db)
        
        # Initialize roles
        roles = init_roles(db, permissions)
        
        # Initialize admin user (optional)
        if create_admin:
            init_admin_user(db, roles)
        
        logger.info("Authentication database initialization completed successfully")
        return True
        
    except Exception as e:
        logger.error(f"Error during authentication database initialization: {e}")
        return False


def get_init_summary(db: Session) -> dict:
    """
    Get summary of initialized auth data.
    
    Args:
        db: Database session
        
    Returns:
        Dictionary with counts and info
    """
    from sqlalchemy import func
    
    roles_count = db.query(func.count(Role.id)).scalar() or 0
    permissions_count = db.query(func.count(Permission.id)).scalar() or 0
    users_count = db.query(func.count(User.id)).scalar() or 0
    
    return {
        "roles": roles_count,
        "permissions": permissions_count,
        "users": users_count,
        "roles_list": [role.name for role in db.query(Role).all()],
        "permissions_list": [perm.name for perm in db.query(Permission).all()],
    }
