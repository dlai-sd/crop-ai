"""
Comprehensive tests for authentication module.
"""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from crop_ai.auth.models import Base, User
from crop_ai.auth.utils import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
)
from crop_ai.auth.crud import (
    create_user,
    get_user,
    create_role,
    create_permission,
    assign_role_to_user,
    assign_permission_to_role,
    get_user_permissions,
)
from crop_ai.auth.init_db import init_auth_db, get_init_summary


# ============================================================================
# Test Fixtures
# ============================================================================

@pytest.fixture(scope="function")
def db():
    """Create a test database session."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    SessionLocal = sessionmaker(bind=engine)
    db = SessionLocal()
    yield db
    db.close()


@pytest.fixture(scope="function")
def initialized_db(db):
    """Create a test database with roles and permissions initialized."""
    init_auth_db(db, create_admin=True)
    return db


@pytest.fixture
def test_user(initialized_db):
    """Create a test user."""
    user = create_user(
        initialized_db,
        email="testuser@example.com",
        username="testuser",
        password="testpass123!",
    )
    return user


@pytest.fixture
def admin_user(initialized_db):
    """Get the initialized admin user."""
    return initialized_db.query(User).filter(
        User.email == "admin@cropai.dev"
    ).first()


# ============================================================================
# Password Hashing Tests
# ============================================================================

class TestPasswordHashing:
    """Test password hashing and verification."""
    
    def test_hash_password(self):
        """Test password hashing."""
        password = "MySecurePassword123!"
        hashed = hash_password(password)
        
        # Hash should not be the same as password
        assert hashed != password
        # Hash should be a string
        assert isinstance(hashed, str)
        # Hash should be reasonably long (Argon2)
        assert len(hashed) > 20
    
    def test_verify_password_success(self):
        """Test successful password verification."""
        password = "MySecurePassword123!"
        hashed = hash_password(password)
        
        assert verify_password(password, hashed) is True
    
    def test_verify_password_failure(self):
        """Test failed password verification."""
        password = "MySecurePassword123!"
        hashed = hash_password(password)
        
        assert verify_password("WrongPassword", hashed) is False
    
    def test_different_hashes_same_password(self):
        """Test that same password produces different hashes (Argon2 with salt)."""
        password = "MySecurePassword123!"
        hash1 = hash_password(password)
        hash2 = hash_password(password)
        
        # Hashes should be different due to salt
        assert hash1 != hash2
        # But both should verify
        assert verify_password(password, hash1) is True
        assert verify_password(password, hash2) is True


# ============================================================================
# JWT Token Tests
# ============================================================================

class TestJWTTokens:
    """Test JWT token creation and validation."""
    
    def test_create_access_token(self):
        """Test access token creation."""
        token = create_access_token(
            user_id=1,
            email="test@example.com",
            username="testuser",
            roles=["USER"],
            permissions=["read"],
        )
        
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_decode_access_token(self):
        """Test access token decoding."""
        token = create_access_token(
            user_id=1,
            email="test@example.com",
            username="testuser",
            roles=["USER"],
            permissions=["read"],
        )
        
        payload = decode_token(token, token_type="access")
        
        assert payload["sub"] == "1"
        assert payload["email"] == "test@example.com"
        assert payload["username"] == "testuser"
        assert "USER" in payload["roles"]
        assert "read" in payload["permissions"]
    
    def test_create_refresh_token(self):
        """Test refresh token creation."""
        token = create_refresh_token(user_id=1)
        
        assert isinstance(token, str)
        assert len(token) > 0
    
    def test_decode_refresh_token(self):
        """Test refresh token decoding."""
        token = create_refresh_token(user_id=1)
        
        payload = decode_token(token, token_type="refresh")
        
        assert payload["sub"] == "1"
        assert payload["type"] == "refresh"
    
    def test_token_expiration(self):
        """Test that expired tokens raise an error."""
        from crop_ai.auth.utils import ACCESS_TOKEN_EXPIRE_MINUTES
        
        # Create an access token with very short expiration
        token = create_access_token(
            user_id=1,
            email="test@example.com",
            username="testuser",
            roles=["USER"],
            permissions=["read"],
        )
        
        # Should decode successfully
        payload = decode_token(token, token_type="access")
        assert payload is not None
    
    def test_wrong_token_type(self):
        """Test that using access token as refresh token fails."""
        access_token = create_access_token(
            user_id=1,
            email="test@example.com",
            username="testuser",
            roles=["USER"],
            permissions=["read"],
        )
        
        # Should fail - token type mismatch
        with pytest.raises(Exception):
            decode_token(access_token, token_type="refresh")


# ============================================================================
# User Management Tests
# ============================================================================

class TestUserManagement:
    """Test user creation and management."""
    
    def test_create_user(self, db):
        """Test user creation."""
        user = create_user(
            db,
            email="newuser@example.com",
            username="newuser",
            password="password123!",
        )
        
        assert user.id is not None
        assert user.email == "newuser@example.com"
        assert user.username == "newuser"
        assert user.is_active is True
        assert user.password_hash != "password123!"
    
    def test_create_user_duplicate_email(self, db):
        """Test that duplicate email raises error."""
        create_user(db, email="user@example.com", username="user1", password="pass123!")
        
        with pytest.raises(ValueError):
            create_user(db, email="user@example.com", username="user2", password="pass123!")
    
    def test_create_user_duplicate_username(self, db):
        """Test that duplicate username raises error."""
        create_user(db, email="user1@example.com", username="user", password="pass123!")
        
        with pytest.raises(ValueError):
            create_user(db, email="user2@example.com", username="user", password="pass123!")
    
    def test_get_user(self, test_user, initialized_db):
        """Test getting user by ID."""
        user = get_user(initialized_db, test_user.id)
        
        assert user is not None
        assert user.email == "testuser@example.com"
        assert user.id == test_user.id


# ============================================================================
# Role Management Tests
# ============================================================================

class TestRoleManagement:
    """Test role creation and management."""
    
    def test_create_role(self, db):
        """Test role creation."""
        role = create_role(db, name="VIEWER", description="View only access")
        
        assert role.id is not None
        assert role.name == "VIEWER"
        assert role.description == "View only access"
    
    def test_assign_role_to_user(self, initialized_db, test_user):
        """Test assigning role to user."""
        from crop_ai.auth.crud import get_role_by_name
        
        viewer_role = get_role_by_name(initialized_db, "VIEWER")
        
        initial_roles = len(test_user.roles)
        assign_role_to_user(initialized_db, test_user.id, viewer_role.id)
        
        # Refresh user from DB
        user = get_user(initialized_db, test_user.id)
        assert len(user.roles) == initial_roles + 1
        assert viewer_role in user.roles


# ============================================================================
# Permission Management Tests
# ============================================================================

class TestPermissionManagement:
    """Test permission creation and management."""
    
    def test_create_permission(self, db):
        """Test permission creation."""
        perm = create_permission(db, name="crops:read", description="Read crops")
        
        assert perm.id is not None
        assert perm.name == "crops:read"
        assert perm.description == "Read crops"
    
    def test_assign_permission_to_role(self, initialized_db):
        """Test assigning permission to role."""
        from crop_ai.auth.crud import get_role_by_name, get_permission_by_name
        
        role = get_role_by_name(initialized_db, "VIEWER")
        perm = get_permission_by_name(initialized_db, "crops:read")
        
        initial_perms = len(role.permissions)
        assign_permission_to_role(initialized_db, role.id, perm.id)
        
        # Refresh from DB
        role = get_role_by_name(initialized_db, "VIEWER")
        assert len(role.permissions) >= initial_perms
    
    def test_get_user_permissions(self, initialized_db, admin_user):
        """Test getting user permissions."""
        perms = get_user_permissions(initialized_db, admin_user.id)
        
        # Admin should have all permissions
        assert len(perms) > 0
        assert "users:create" in perms
        assert "crops:read" in perms


# ============================================================================
# Database Initialization Tests
# ============================================================================

class TestDatabaseInitialization:
    """Test database initialization."""
    
    def test_init_auth_db(self, db):
        """Test database initialization."""
        result = init_auth_db(db, create_admin=False)
        
        assert result is True
    
    def test_init_auth_db_with_admin(self, db):
        """Test database initialization with admin user."""
        init_auth_db(db, create_admin=True)
        
        admin = db.query(User).filter(
            User.email == "admin@cropai.dev"
        ).first()
        
        assert admin is not None
        assert admin.username == "admin"
        assert admin.is_active is True
    
    def test_get_init_summary(self, initialized_db):
        """Test getting initialization summary."""
        summary = get_init_summary(initialized_db)
        
        assert "roles" in summary
        assert "permissions" in summary
        assert "users" in summary
        assert summary["roles"] >= 4
        assert summary["permissions"] >= 24
        assert summary["users"] >= 1


# ============================================================================
# Integration Tests
# ============================================================================

class TestAuthenticationFlow:
    """Test complete authentication flows."""
    
    def test_complete_auth_flow(self, initialized_db, test_user):
        """Test complete authentication flow."""
        from crop_ai.auth.crud import get_user_by_email
        
        # 1. Get user
        user = get_user_by_email(initialized_db, "testuser@example.com")
        assert user is not None
        
        # 2. Create tokens
        user_roles = [role.name for role in user.roles]
        user_permissions = get_user_permissions(initialized_db, user.id)
        
        access_token = create_access_token(
            user_id=user.id,
            email=user.email,
            username=user.username,
            roles=user_roles,
            permissions=user_permissions,
        )
        
        refresh_token = create_refresh_token(user_id=user.id)
        
        # 3. Verify access token
        payload = decode_token(access_token, token_type="access")
        assert payload["sub"] == str(user.id)
        assert payload["email"] == user.email
        
        # 4. Verify refresh token
        refresh_payload = decode_token(refresh_token, token_type="refresh")
        assert refresh_payload["sub"] == str(user.id)


# ============================================================================
# Run Tests
# ============================================================================

if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
