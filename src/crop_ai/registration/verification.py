"""
Email and SMS verification handling for registration.

Supports:
- Email verification tokens (links)
- SMS OTP (6-digit codes)
- Attempt tracking and limiting
- Token expiration
"""
import os
import secrets
import smtplib
from dataclasses import dataclass
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Optional, Tuple

# ============================================================================
# Verification Configuration
# ============================================================================

@dataclass
class VerificationConfig:
    """Verification configuration."""
    email_token_expiry_minutes: int = 60
    sms_otp_expiry_minutes: int = 10
    max_verification_attempts: int = 5
    max_email_attempts: int = 3
    otp_length: int = 6
    resend_cooldown_seconds: int = 60


# ============================================================================
# SMS Provider Interface
# ============================================================================

class SMSProvider:
    """Base SMS provider interface."""
    
    async def send_otp(self, phone_number: str, otp: str) -> bool:
        """Send OTP to phone number."""
        raise NotImplementedError


class TwilioSMSProvider(SMSProvider):
    """Twilio SMS provider."""
    
    def __init__(self, account_sid: str, auth_token: str, from_number: str):
        """Initialize Twilio SMS provider."""
        self.account_sid = account_sid
        self.auth_token = auth_token
        self.from_number = from_number
        # In production, use: from twilio.rest import Client
        # self.client = Client(account_sid, auth_token)
    
    async def send_otp(self, phone_number: str, otp: str) -> bool:
        """Send OTP via Twilio."""
        try:
            # In production, uncomment below:
            # message = self.client.messages.create(
            #     body=f"Your CropAI verification code is: {otp}. Valid for 10 minutes.",
            #     from_=self.from_number,
            #     to=phone_number,
            # )
            # return message.sid is not None
            
            # Mock implementation for development
            print(f"[MOCK SMS] To {phone_number}: Your CropAI verification code is: {otp}")
            return True
        except Exception as e:
            print(f"SMS send error: {e}")
            return False


class AmazonSNSSMSProvider(SMSProvider):
    """Amazon SNS SMS provider."""
    
    def __init__(self, region: str):
        """Initialize Amazon SNS SMS provider."""
        self.region = region
        # In production, use: import boto3
        # self.sns_client = boto3.client('sns', region_name=region)
    
    async def send_otp(self, phone_number: str, otp: str) -> bool:
        """Send OTP via Amazon SNS."""
        try:
            # In production, uncomment below:
            # response = self.sns_client.publish(
            #     PhoneNumber=phone_number,
            #     Message=f"Your CropAI verification code is: {otp}. Valid for 10 minutes.",
            # )
            # return response['MessageId'] is not None
            
            # Mock implementation for development
            print(f"[MOCK SNS] To {phone_number}: Your CropAI verification code is: {otp}")
            return True
        except Exception as e:
            print(f"SMS send error: {e}")
            return False


# ============================================================================
# Email Provider Interface
# ============================================================================

class EmailProvider:
    """Base email provider interface."""
    
    async def send_verification_email(
        self,
        recipient_email: str,
        recipient_name: str,
        verification_token: str,
        registration_id: str,
    ) -> bool:
        """Send verification email."""
        raise NotImplementedError


class SMTPEmailProvider(EmailProvider):
    """SMTP email provider."""
    
    def __init__(
        self,
        smtp_server: str,
        smtp_port: int,
        sender_email: str,
        sender_password: str,
        sender_name: str = "CropAI",
    ):
        """Initialize SMTP email provider."""
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.sender_email = sender_email
        self.sender_password = sender_password
        self.sender_name = sender_name
    
    async def send_verification_email(
        self,
        recipient_email: str,
        recipient_name: str,
        verification_token: str,
        registration_id: str,
    ) -> bool:
        """Send verification email via SMTP."""
        try:
            # Build verification link
            verification_url = (
                f"{os.getenv('APP_URL', 'http://localhost:3000')}"
                f"/register/verify-email?"
                f"token={verification_token}&registration_id={registration_id}"
            )
            
            # Create email message
            message = MIMEMultipart("alternative")
            message["Subject"] = "Verify Your CropAI Account"
            message["From"] = f"{self.sender_name} <{self.sender_email}>"
            message["To"] = recipient_email
            
            # HTML content
            html_body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                        <h2>Welcome to CropAI, {recipient_name}!</h2>
                        <p>Thank you for registering. Please verify your email address to complete your registration.</p>
                        
                        <div style="margin: 30px 0;">
                            <a href="{verification_url}" 
                               style="background-color: #4CAF50; color: white; padding: 12px 30px; 
                                      text-decoration: none; border-radius: 4px; display: inline-block;">
                                Verify Email Address
                            </a>
                        </div>
                        
                        <p>Or copy and paste this link in your browser:</p>
                        <p style="word-break: break-all; color: #666;">
                            {verification_url}
                        </p>
                        
                        <p style="margin-top: 30px; color: #999; font-size: 12px;">
                            This link will expire in 1 hour. If you didn't create this account, 
                            please ignore this email.
                        </p>
                    </div>
                </body>
            </html>
            """
            
            # Plain text alternative
            text_body = f"""
            Welcome to CropAI, {recipient_name}!
            
            Please verify your email by visiting:
            {verification_url}
            
            This link will expire in 1 hour.
            """
            
            message.attach(MIMEText(text_body, "plain"))
            message.attach(MIMEText(html_body, "html"))
            
            # Send email
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.starttls()
                server.login(self.sender_email, self.sender_password)
                server.sendmail(self.sender_email, [recipient_email], message.as_string())
            
            return True
        except Exception as e:
            print(f"Email send error: {e}")
            return False


class MockEmailProvider(EmailProvider):
    """Mock email provider for development."""
    
    async def send_verification_email(
        self,
        recipient_email: str,
        recipient_name: str,
        verification_token: str,
        registration_id: str,
    ) -> bool:
        """Print verification email to console."""
        verification_url = (
            f"{os.getenv('APP_URL', 'http://localhost:3000')}"
            f"/register/verify-email?"
            f"token={verification_token}&registration_id={registration_id}"
        )
        print(f"\n[MOCK EMAIL] To {recipient_email}:")
        print("Subject: Verify Your CropAI Account")
        print(f"Verification URL: {verification_url}\n")
        return True


# ============================================================================
# Verification Token Generator
# ============================================================================

class VerificationTokenGenerator:
    """Generate and manage verification tokens."""
    
    def __init__(self, config: VerificationConfig = None):
        """Initialize token generator."""
        self.config = config or VerificationConfig()
    
    def generate_email_token(self) -> str:
        """Generate email verification token."""
        # Use URL-safe token
        return secrets.token_urlsafe(32)
    
    def generate_otp(self) -> str:
        """Generate 6-digit OTP."""
        # Generate random 6-digit code
        otp = secrets.randbelow(10 ** self.config.otp_length)
        return str(otp).zfill(self.config.otp_length)
    
    def get_token_expiry(self, token_type: str) -> datetime:
        """Get expiry time for token type."""
        if token_type == "email":
            return datetime.utcnow() + timedelta(
                minutes=self.config.email_token_expiry_minutes
            )
        elif token_type == "sms":
            return datetime.utcnow() + timedelta(
                minutes=self.config.sms_otp_expiry_minutes
            )
        else:
            raise ValueError(f"Unknown token type: {token_type}")


# ============================================================================
# Verification Service
# ============================================================================

class VerificationService:
    """Service for managing verification process."""
    
    def __init__(
        self,
        email_provider: EmailProvider = None,
        sms_provider: SMSProvider = None,
        config: VerificationConfig = None,
    ):
        """Initialize verification service."""
        self.email_provider = email_provider or MockEmailProvider()
        self.sms_provider = sms_provider or TwilioSMSProvider(
            account_sid=os.getenv("TWILIO_ACCOUNT_SID", ""),
            auth_token=os.getenv("TWILIO_AUTH_TOKEN", ""),
            from_number=os.getenv("TWILIO_PHONE_NUMBER", ""),
        )
        self.config = config or VerificationConfig()
        self.token_generator = VerificationTokenGenerator(self.config)
    
    async def send_email_verification(
        self,
        email: str,
        name: str,
        registration_id: str,
    ) -> Tuple[str, datetime]:
        """Send email verification and return token + expiry."""
        token = self.token_generator.generate_email_token()
        expiry = self.token_generator.get_token_expiry("email")
        
        success = await self.email_provider.send_verification_email(
            recipient_email=email,
            recipient_name=name,
            verification_token=token,
            registration_id=registration_id,
        )
        
        if not success:
            raise Exception("Failed to send verification email")
        
        return token, expiry
    
    async def send_sms_otp(
        self,
        phone_number: str,
    ) -> Tuple[str, datetime]:
        """Send SMS OTP and return code + expiry."""
        otp = self.token_generator.generate_otp()
        expiry = self.token_generator.get_token_expiry("sms")
        
        success = await self.sms_provider.send_otp(phone_number, otp)
        
        if not success:
            raise Exception("Failed to send SMS OTP")
        
        return otp, expiry
    
    def verify_token(
        self,
        provided_token: str,
        stored_token: str,
        expires_at: datetime,
        attempts: int,
        max_attempts: int = None,
    ) -> Tuple[bool, Optional[str]]:
        """
        Verify a token.
        
        Returns:
            (is_valid, error_message)
        """
        max_attempts = max_attempts or self.config.max_verification_attempts
        
        # Check attempts
        if attempts >= max_attempts:
            return False, f"Maximum verification attempts ({max_attempts}) exceeded"
        
        # Check expiration
        if datetime.utcnow() > expires_at:
            return False, "Verification token has expired"
        
        # Check token match (constant-time comparison to prevent timing attacks)
        import hmac
        if not hmac.compare_digest(provided_token, stored_token):
            return False, "Invalid verification token"
        
        return True, None


# ============================================================================
# Factory Functions
# ============================================================================

def create_verification_service() -> VerificationService:
    """Create verification service with providers from environment."""
    email_provider = None
    sms_provider = None
    
    # Email provider setup
    if os.getenv("SMTP_SERVER"):
        email_provider = SMTPEmailProvider(
            smtp_server=os.getenv("SMTP_SERVER"),
            smtp_port=int(os.getenv("SMTP_PORT", "587")),
            sender_email=os.getenv("SENDER_EMAIL"),
            sender_password=os.getenv("SENDER_PASSWORD"),
            sender_name=os.getenv("SENDER_NAME", "CropAI"),
        )
    else:
        email_provider = MockEmailProvider()
    
    # SMS provider setup
    if os.getenv("TWILIO_ACCOUNT_SID"):
        sms_provider = TwilioSMSProvider(
            account_sid=os.getenv("TWILIO_ACCOUNT_SID"),
            auth_token=os.getenv("TWILIO_AUTH_TOKEN"),
            from_number=os.getenv("TWILIO_PHONE_NUMBER"),
        )
    elif os.getenv("AWS_REGION"):
        sms_provider = AmazonSNSSMSProvider(
            region=os.getenv("AWS_REGION"),
        )
    else:
        sms_provider = TwilioSMSProvider(
            account_sid="",
            auth_token="",
            from_number="",
        )
    
    return VerificationService(email_provider, sms_provider)


# ============================================================================
# Singleton Instance
# ============================================================================

verification_service: Optional[VerificationService] = None


def get_verification_service() -> VerificationService:
    """Get or create verification service singleton."""
    global verification_service
    if verification_service is None:
        verification_service = create_verification_service()
    return verification_service
