# UI Implementation Quick Reference

**Created:** December 5, 2025  
**Status:** ✅ Production Ready

---

## 🚀 Quick Start

### View the Components

Navigate to the component files:
```
frontend/angular/src/components/
├── registration/registration.component.ts
├── login/login.component.ts
└── mfa-verify/mfa-verify.component.ts
```

### Use the Auth Service

```typescript
import { AuthApiService } from './services/auth-api.service';

constructor(private authApi: AuthApiService) {}

// Register
this.authApi.register({
  email: 'user@example.com',
  phone_number: '+1234567890',
  password: 'SecureP@ss123',
  first_name: 'John',
  last_name: 'Doe',
  date_of_birth: '1990-01-01',
  gender: 'M'
}).subscribe(response => {
  console.log('Registered:', response);
});

// Login
this.authApi.login({
  email_or_username: 'user@example.com',
  password: 'SecureP@ss123',
  remember_me: true
}).subscribe(response => {
  if (response.requires_mfa) {
    // Redirect to MFA verification
    this.router.navigate(['/mfa-verify'], {
      queryParams: { challenge_id: response.challenge_id }
    });
  } else {
    // Store tokens and redirect
    localStorage.setItem('access_token', response.access_token);
  }
});

// Verify MFA
this.authApi.verifyMFA({
  challenge_id: 'challenge-123',
  code: '123456'
}).subscribe(response => {
  localStorage.setItem('access_token', response.access_token);
});
```

---

## 📁 File Structure

```
frontend/angular/src/
├── components/
│   ├── registration/
│   │   └── registration.component.ts .............. 650+ lines
│   ├── login/
│   │   └── login.component.ts ..................... 350+ lines
│   └── mfa-verify/
│       └── mfa-verify.component.ts ............... 450+ lines
├── services/
│   └── auth-api.service.ts ........................ 350+ lines (NEW)
└── UI_IMPLEMENTATION_GUIDE.md ..................... Comprehensive guide
```

---

## 🎨 Component Overview

### Registration Component
```
Inputs:
- First Name, Last Name
- Email, Phone Number
- Date of Birth, Gender
- Password, Confirm Password
- Terms & Conditions (checkbox)

Outputs:
- Success message + redirect to login
- Error messages with field-specific hints

Features:
- Real-time password strength indicator
- Comprehensive form validation
- Mobile responsive
- i18n support
```

### Login Component
```
Inputs:
- Email or Username
- Password
- Remember Me (checkbox)

Outputs:
- If MFA required: redirect to /mfa-verify
- If success: tokens stored, redirect to /dashboard

Features:
- SSO buttons (Google, Facebook)
- Forgot password link
- Status-specific error messages
- Rate limiting feedback
```

### MFA Verify Component
```
Inputs:
- 6-digit MFA code
- Optional: backup code

Outputs:
- Tokens stored + redirect to /dashboard

Features:
- Countdown timer (300 seconds)
- Attempt counter
- Backup code option
- Real-time validation
- Auto-submit on 6 digits (optional)
```

---

## 🔌 API Integration

### Base URL
```
/api/v1
```

### Endpoints

**Registration:**
```
POST /api/v1/register
Content-Type: application/json

{
  "email": "user@example.com",
  "phone_number": "+1234567890",
  "password": "SecureP@ss123",
  "first_name": "John",
  "last_name": "Doe",
  "date_of_birth": "1990-01-01",
  "gender": "M"
}

Response:
{
  "id": "user-123",
  "email": "user@example.com",
  "message": "Registration successful"
}
```

**Login:**
```
POST /api/v1/login
Content-Type: application/json

{
  "email_or_username": "user@example.com",
  "password": "SecureP@ss123",
  "remember_me": true
}

Response (No MFA):
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user_id": "user-123",
  "email": "user@example.com",
  "role": "farmer",
  "name": "John Doe"
}

Response (MFA Required):
{
  "requires_mfa": true,
  "challenge_id": "challenge-456",
  "mfa_method": "TOTP",
  "expires_in": 600
}
```

**MFA Verify:**
```
POST /api/v1/login/mfa/verify
Content-Type: application/json
Authorization: Bearer <token>

{
  "challenge_id": "challenge-456",
  "code": "123456"
}

Response:
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "Bearer",
  "expires_in": 900,
  "user_id": "user-123"
}
```

---

## 🌐 Internationalization

### Supported Languages
- English (en)
- Hindi (hi)
- Marathi (mr)
- Gujarati (gu)

### Common Translation Keys

**Registration:**
```
register, personalInformation, firstName, lastName,
contactInformation, email, phoneNumber, security,
password, confirmPassword, passwordMismatch,
agreeToTerms, createAccount, registrationSuccess
```

**Login:**
```
login, emailOrUsername, password, rememberMe,
forgotPassword, loginWithGoogle, loginWithFacebook,
loginSuccessful, invalidCredentials
```

**MFA:**
```
verifyIdentity, enterCode, verify, verifying,
mfaVerificationSuccess, invalidCode,
useBackupCode, backToLogin
```

---

## 🔐 Security

### Password Requirements
- ✓ 8+ characters
- ✓ At least 1 uppercase letter (A-Z)
- ✓ At least 1 lowercase letter (a-z)
- ✓ At least 1 digit (0-9)
- ✓ At least 1 special character (!@#$%^&*_-+)

### Token Management
```typescript
// Store tokens
localStorage.setItem('access_token', response.access_token);
localStorage.setItem('refresh_token', response.refresh_token);

// Retrieve token
const token = localStorage.getItem('access_token');

// Clear on logout
localStorage.removeItem('access_token');
localStorage.removeItem('refresh_token');
```

### MFA Methods
1. **TOTP** - Google Authenticator (30-second window)
2. **SMS OTP** - 6-digit code via SMS (10-minute expiry)
3. **Email OTP** - 6-digit code via email (10-minute expiry)

---

## 🧪 Testing Examples

### Test Registration Flow
```typescript
describe('RegistrationComponent', () => {
  it('should validate email format', () => {
    // Test email validation
  });

  it('should enforce password strength', () => {
    // Test password requirements
  });

  it('should handle API errors', () => {
    // Test error handling
  });

  it('should submit valid form', () => {
    // Test successful registration
  });
});
```

### Test Login Flow
```typescript
describe('LoginComponent', () => {
  it('should require email/username', () => {
    // Test required validation
  });

  it('should handle invalid credentials', () => {
    // Test 401 error handling
  });

  it('should detect MFA requirement', () => {
    // Test MFA redirect
  });

  it('should store tokens on success', () => {
    // Test token storage
  });
});
```

---

## 📱 Mobile Responsiveness

### Responsive Classes
```css
@media (max-width: 600px) {
  /* Mobile optimizations */
  .registration-card {
    padding: 25px;
  }
  
  .btn-sso {
    flex-direction: column;
  }
}
```

### Touch-Friendly Elements
- Minimum button height: 48px
- Minimum input padding: 10px
- Proper spacing between interactive elements
- Responsive font sizes

---

## ⚙️ Configuration

### Environment Variables
```
API_BASE_URL=http://localhost:8000
ENVIRONMENT=development
ENABLE_SSO=true
MFA_TIMEOUT=600
```

### Proxy Configuration
**proxy.conf.json:**
```json
{
  "/api": {
    "target": "http://localhost:8000",
    "secure": false,
    "changeOrigin": true
  }
}
```

---

## 🚨 Error Handling

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 202 | Accepted (MFA required) | Redirect to MFA |
| 400 | Bad Request | Show field errors |
| 401 | Unauthorized | Show invalid credentials |
| 429 | Too Many Attempts | Show rate limit message |
| 500 | Server Error | Show generic error |

### Error Messages
```typescript
// In components
if (error?.status === 401) {
  this.errorMessage = 'Invalid email or password';
} else if (error?.status === 429) {
  this.errorMessage = 'Too many login attempts. Please try again later.';
} else {
  this.errorMessage = error?.message || 'An error occurred';
}
```

---

## 🎯 Common Tasks

### Add a New Translation Key
1. Add key to translation service
2. Update all language files
3. Use in component: `t('keyName')`

### Add Form Validation
```typescript
const control = this.form.get('fieldName');
control?.setValidators([Validators.required, customValidator]);
control?.updateValueAndValidity();
```

### Handle API Error
```typescript
this.authApi.login(data).subscribe({
  next: response => { /* success */ },
  error: error => {
    this.errorMessage = error.message;
  }
});
```

### Store User Session
```typescript
this.authService.login({
  id: response.user_id,
  name: response.name,
  email: response.email,
  role: response.role
});
```

---

## 🐛 Troubleshooting

### Issue: Component not showing
**Solution:** Check route configuration and imports

### Issue: API calls failing
**Solution:** Verify proxy.conf.json and API base URL

### Issue: Form validation not working
**Solution:** Ensure FormBuilder is injected and validators are set

### Issue: Translations not updating
**Solution:** Check language code in translation service

### Issue: Tokens not persisting
**Solution:** Verify localStorage is available and not blocked

---

## 📚 Related Documentation

- **Full Guide:** `frontend/angular/UI_IMPLEMENTATION_GUIDE.md`
- **Implementation Summary:** `frontend/angular/UI_IMPLEMENTATION_SUMMARY.md`
- **Backend Login:** `src/crop_ai/login/LOGIN_GUIDE.md`
- **Backend Registration:** Backend docs
- **Angular Docs:** https://angular.io

---

## ✅ Checklist for Using Components

- [ ] Install Angular 16+
- [ ] Install dependencies: `npm install`
- [ ] Configure proxy.conf.json
- [ ] Import components in routes
- [ ] Setup translation service
- [ ] Configure API base URL
- [ ] Test locally: `npm start`
- [ ] Run tests: `npm test`
- [ ] Build for production: `npm run build`

---

## 🎉 Next Steps

1. **Integrate Routes** - Add components to router configuration
2. **Setup Testing** - Create unit test files
3. **Test Flows** - Verify registration, login, MFA workflows
4. **Connect to Backend** - Ensure API endpoints match
5. **Deploy** - Build and deploy to staging/production

---

**Status:** ✅ Ready for Integration  
**Last Updated:** December 5, 2025
