"""
CRUD (Create, Read, Update, Delete) operations for authentication models.
"""
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
import logging

from .models import User, Role, Permission
from .utils import hash_password

logger = logging.getLogger(__name__)


# ============================================================================
# User Operations
# ============================================================================

def create_user(
    db: Session,
    email: str,
    username: str,
    password: str,
    is_active: bool = True,
) -> User:
    """
    Create a new user.
    
    Args:
        db: Database session
        email: User email (unique)
        username: Username (unique)
        password: Plain text password (will be hashed)
        is_active: Whether user is active
        
    Returns:
        Created User object
        
    Raises:
        ValueError: If email or username already exists
    """
    try:
        # Check if user already exists
        existing_user = db.query(User).filter(
            (User.email == email) | (User.username == username)
        ).first()
        
        if existing_user:
            raise ValueError(f"User with email '{email}' or username '{username}' already exists")
        
        # Hash password
        password_hash = hash_password(password)
        
        # Create user
        user = User(
            email=email,
            username=username,
            password_hash=password_hash,
            is_active=is_active,
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        logger.info(f"User created: {email}")
        return user
        
    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating user: {e}")
        raise ValueError("Email or username already exists")
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating user: {e}")
        raise


def get_user(db: Session, user_id: int) -> Optional[User]:
    """
    Get user by ID.
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        User object or None if not found
    """
    return db.query(User).filter(User.id == user_id).first()


def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """
    Get user by email.
    
    Args:
        db: Database session
        email: User email
        
    Returns:
        User object or None if not found
    """
    return db.query(User).filter(User.email == email).first()


def get_user_by_username(db: Session, username: str) -> Optional[User]:
    """
    Get user by username.
    
    Args:
        db: Database session
        username: Username
        
    Returns:
        User object or None if not found
    """
    return db.query(User).filter(User.username == username).first()


def list_users(
    db: Session,
    skip: int = 0,
    limit: int = 100,
    active_only: bool = False,
) -> List[User]:
    """
    List users with pagination.
    
    Args:
        db: Database session
        skip: Number of users to skip
        limit: Maximum number of users to return
        active_only: If True, only return active users
        
    Returns:
        List of User objects
    """
    query = db.query(User)
    
    if active_only:
        query = query.filter(User.is_active == True)
    
    return query.offset(skip).limit(limit).all()


def update_user(
    db: Session,
    user_id: int,
    email: Optional[str] = None,
    username: Optional[str] = None,
    is_active: Optional[bool] = None,
) -> Optional[User]:
    """
    Update user information.
    
    Args:
        db: Database session
        user_id: User ID
        email: New email (optional)
        username: New username (optional)
        is_active: New active status (optional)
        
    Returns:
        Updated User object or None if not found
    """
    user = get_user(db, user_id)
    
    if not user:
        return None
    
    try:
        if email is not None:
            user.email = email
        if username is not None:
            user.username = username
        if is_active is not None:
            user.is_active = is_active
        
        db.commit()
        db.refresh(user)
        
        logger.info(f"User updated: {user.email}")
        return user
        
    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error updating user: {e}")
        raise ValueError("Email or username already in use")
    except Exception as e:
        db.rollback()
        logger.error(f"Error updating user: {e}")
        raise


def delete_user(db: Session, user_id: int) -> bool:
    """
    Delete a user.
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        True if deleted, False if not found
    """
    user = get_user(db, user_id)
    
    if not user:
        return False
    
    try:
        db.delete(user)
        db.commit()
        
        logger.info(f"User deleted: {user.email}")
        return True
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error deleting user: {e}")
        raise


# ============================================================================
# Role Operations
# ============================================================================

def create_role(
    db: Session,
    name: str,
    description: Optional[str] = None,
) -> Role:
    """
    Create a new role.
    
    Args:
        db: Database session
        name: Role name (unique)
        description: Role description
        
    Returns:
        Created Role object
        
    Raises:
        ValueError: If role already exists
    """
    try:
        # Check if role already exists
        existing_role = db.query(Role).filter(Role.name == name).first()
        
        if existing_role:
            raise ValueError(f"Role '{name}' already exists")
        
        role = Role(name=name, description=description)
        db.add(role)
        db.commit()
        db.refresh(role)
        
        logger.info(f"Role created: {name}")
        return role
        
    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating role: {e}")
        raise ValueError(f"Role '{name}' already exists")
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating role: {e}")
        raise


def get_role(db: Session, role_id: int) -> Optional[Role]:
    """
    Get role by ID.
    
    Args:
        db: Database session
        role_id: Role ID
        
    Returns:
        Role object or None if not found
    """
    return db.query(Role).filter(Role.id == role_id).first()


def get_role_by_name(db: Session, name: str) -> Optional[Role]:
    """
    Get role by name.
    
    Args:
        db: Database session
        name: Role name
        
    Returns:
        Role object or None if not found
    """
    return db.query(Role).filter(Role.name == name).first()


def list_roles(db: Session) -> List[Role]:
    """
    List all roles.
    
    Args:
        db: Database session
        
    Returns:
        List of Role objects
    """
    return db.query(Role).all()


# ============================================================================
# Permission Operations
# ============================================================================

def create_permission(
    db: Session,
    name: str,
    description: Optional[str] = None,
) -> Permission:
    """
    Create a new permission.
    
    Args:
        db: Database session
        name: Permission name (unique)
        description: Permission description
        
    Returns:
        Created Permission object
        
    Raises:
        ValueError: If permission already exists
    """
    try:
        # Check if permission already exists
        existing_permission = db.query(Permission).filter(Permission.name == name).first()
        
        if existing_permission:
            raise ValueError(f"Permission '{name}' already exists")
        
        permission = Permission(name=name, description=description)
        db.add(permission)
        db.commit()
        db.refresh(permission)
        
        logger.info(f"Permission created: {name}")
        return permission
        
    except IntegrityError as e:
        db.rollback()
        logger.error(f"Integrity error creating permission: {e}")
        raise ValueError(f"Permission '{name}' already exists")
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating permission: {e}")
        raise


def get_permission(db: Session, permission_id: int) -> Optional[Permission]:
    """
    Get permission by ID.
    
    Args:
        db: Database session
        permission_id: Permission ID
        
    Returns:
        Permission object or None if not found
    """
    return db.query(Permission).filter(Permission.id == permission_id).first()


def get_permission_by_name(db: Session, name: str) -> Optional[Permission]:
    """
    Get permission by name.
    
    Args:
        db: Database session
        name: Permission name
        
    Returns:
        Permission object or None if not found
    """
    return db.query(Permission).filter(Permission.name == name).first()


def list_permissions(db: Session) -> List[Permission]:
    """
    List all permissions.
    
    Args:
        db: Database session
        
    Returns:
        List of Permission objects
    """
    return db.query(Permission).all()


# ============================================================================
# User-Role Operations
# ============================================================================

def assign_role_to_user(
    db: Session,
    user_id: int,
    role_id: int,
) -> User:
    """
    Assign a role to a user.
    
    Args:
        db: Database session
        user_id: User ID
        role_id: Role ID
        
    Returns:
        Updated User object
        
    Raises:
        ValueError: If user or role not found, or user already has role
    """
    user = get_user(db, user_id)
    if not user:
        raise ValueError(f"User {user_id} not found")
    
    role = get_role(db, role_id)
    if not role:
        raise ValueError(f"Role {role_id} not found")
    
    # Check if user already has role
    if role in user.roles:
        raise ValueError(f"User already has role '{role.name}'")
    
    try:
        user.roles.append(role)
        db.commit()
        db.refresh(user)
        
        logger.info(f"Role '{role.name}' assigned to user {user.email}")
        return user
        
    except Exception as e:
        db.rollback()
        logger.error(f"Error assigning role: {e}")
        raise


def remove_role_from_user(
    db: Session,
    user_id: int,
    role_id: int,
) -> User:
    """
    Remove a role from a user.
    
    Args:
        db: Database session
        user_id: User ID
        role_id: Role ID
        
    Returns:
        Updated User object
        
    Raises:
        ValueError: If user or role not found
    """
    user = get_user(db, user_id)
    if not user:
        raise ValueError(f"User {user_id} not found")
    
    role = get_role(db, role_id)
    if not role:
        raise ValueError(f"Role {role_id} not found")
    
    try:
        user.roles.remove(role)
        db.commit()
        db.refresh(user)
        
        logger.info(f"Role '{role.name}' removed from user {user.email}")
        return user
        
    except ValueError:
        raise ValueError(f"User does not have role '{role.name}'")
    except Exception as e:
        db.rollback()
        logger.error(f"Error removing role: {e}")
        raise


def get_user_roles(db: Session, user_id: int) -> List[Role]:
    """
    Get all roles for a user.
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        List of Role objects
    """
    user = get_user(db, user_id)
    if not user:
        return []
    
    return user.roles


# ============================================================================
# Role-Permission Operations
# ============================================================================

def assign_permission_to_role(
    db: Session,
    role_id: int,
    permission_id: int,
) -> Role:
    """
    Assign a permission to a role.
    
    Args:
        db: Database session
        role_id: Role ID
        permission_id: Permission ID
        
    Returns:
        Updated Role object
        
    Raises:
        ValueError: If role or permission not found
    """
    role = get_role(db, role_id)
    if not role:
        raise ValueError(f"Role {role_id} not found")
    
    permission = get_permission(db, permission_id)
    if not permission:
        raise ValueError(f"Permission {permission_id} not found")
    
    # Check if role already has permission (idempotent - silently skip)
    if permission in role.permissions:
        logger.info(
            f"Permission '{permission.name}' already assigned to role "
            f"'{role.name}'"
        )
        return role

    try:
        role.permissions.append(permission)
        db.commit()
        db.refresh(role)

        logger.info(
            f"Permission '{permission.name}' assigned to role '{role.name}'"
        )
        return role

    except Exception as e:
        db.rollback()
        logger.error(f"Error assigning permission: {e}")
        raise


def remove_permission_from_role(
    db: Session,
    role_id: int,
    permission_id: int,
) -> Role:
    """
    Remove a permission from a role.
    
    Args:
        db: Database session
        role_id: Role ID
        permission_id: Permission ID
        
    Returns:
        Updated Role object
        
    Raises:
        ValueError: If role or permission not found
    """
    role = get_role(db, role_id)
    if not role:
        raise ValueError(f"Role {role_id} not found")
    
    permission = get_permission(db, permission_id)
    if not permission:
        raise ValueError(f"Permission {permission_id} not found")
    
    try:
        role.permissions.remove(permission)
        db.commit()
        db.refresh(role)
        
        logger.info(f"Permission '{permission.name}' removed from role '{role.name}'")
        return role
        
    except ValueError:
        raise ValueError(f"Role does not have permission '{permission.name}'")
    except Exception as e:
        db.rollback()
        logger.error(f"Error removing permission: {e}")
        raise


def get_role_permissions(db: Session, role_id: int) -> List[Permission]:
    """
    Get all permissions for a role.
    
    Args:
        db: Database session
        role_id: Role ID
        
    Returns:
        List of Permission objects
    """
    role = get_role(db, role_id)
    if not role:
        return []
    
    return role.permissions


def get_user_permissions(db: Session, user_id: int) -> List[str]:
    """
    Get all permissions for a user (through all their roles).
    
    Args:
        db: Database session
        user_id: User ID
        
    Returns:
        List of permission names
    """
    user = get_user(db, user_id)
    if not user:
        return []
    
    permissions = set()
    for role in user.roles:
        for permission in role.permissions:
            permissions.add(permission.name)
    
    return list(permissions)
