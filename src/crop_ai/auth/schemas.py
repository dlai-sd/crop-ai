"""
Pydantic schemas for authentication and authorization.
"""
from typing import List, Optional
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime


class TokenRequest(BaseModel):
    """Login request schema."""
    email: str = Field(..., description="User email address")
    password: str = Field(..., description="User password", min_length=8)


class RefreshTokenRequest(BaseModel):
    """Refresh token request schema."""
    refresh_token: str = Field(..., description="Refresh token")


class TokenResponse(BaseModel):
    """Token response schema."""
    access_token: str = Field(..., description="JWT access token")
    refresh_token: Optional[str] = Field(None, description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiry time in seconds")


class UserCreate(BaseModel):
    """User creation schema."""
    email: str = Field(..., description="User email address")
    username: str = Field(..., min_length=3, max_length=100, description="Username")
    password: str = Field(..., min_length=8, description="Password (min 8 chars)")


class UserUpdate(BaseModel):
    """User update schema."""
    email: Optional[str] = None
    username: Optional[str] = None
    is_active: Optional[bool] = None


class PermissionResponse(BaseModel):
    """Permission response schema."""
    id: int
    name: str
    description: Optional[str] = None

    class Config:
        from_attributes = True


class RoleResponse(BaseModel):
    """Role response schema."""
    id: int
    name: str
    description: Optional[str] = None
    permissions: List[PermissionResponse] = []

    class Config:
        from_attributes = True


class UserResponse(BaseModel):
    """User response schema."""
    id: int
    email: str
    username: str
    is_active: bool
    roles: List[RoleResponse] = []
    permissions: List[str] = []
    created_at: datetime
    last_login: Optional[datetime] = None

    class Config:
        from_attributes = True


class SessionResponse(BaseModel):
    """Session response schema."""
    id: int
    device_name: Optional[str] = None
    device_type: Optional[str] = None
    ip_address: Optional[str] = None
    is_active: bool
    last_activity: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class ErrorResponse(BaseModel):
    """Error response schema."""
    detail: str
    error_code: Optional[str] = None
