# CropAI Frontend - User Guide & Technical Documentation

## 🌾 Project Overview

CropAI Frontend is a modern, role-based agricultural intelligence platform built with Angular 16. It supports 6 distinct user roles with multi-language support (English, Hindi) and integrates with AI crop identification models.

## 🚀 Quick Start

### Prerequisites
- Node.js 18+ and npm 9+
- Angular CLI 16

### Installation & Running

```bash
cd frontend/angular
npm install
npm start
```

Access the app at: http://localhost:4200

### Production Build

```bash
npm run build
```

---

## 👥 User Roles & Features

### 1. **Farmer** 👨‍🌾
- **Dashboard**: Upload satellite images, get instant crop predictions
- **Features**:
  - Real-time crop identification with confidence scores
  - Risk factor detection & recommendations
  - View crop health status
  - Find service partners nearby
  - Access direct-to-customer sales marketplace
- **Mock Predictions**: Returns randomized crop data for demo purposes

### 2. **Service Partner** 🤝
- **Dashboard**: Market intelligence & lead generation
- **Features**:
  - View farmers by crop type in coverage area
  - Identify service opportunities
  - Manage service requests
  - Track commission earnings
  - Rating & reputation management

### 3. **Customer** 🛒
- **Dashboard**: Fresh produce marketplace
- **Features**:
  - Browse farmer profiles
  - Verify crop authenticity (satellite image + AI)
  - Direct purchase from verified farmers
  - Order tracking
  - Farmer ratings & reviews

### 4. **Call Center Associate** 📞
- **Dashboard**: User support management
- **Features**:
  - Ticket management system
  - User onboarding & support
  - Complaint resolution
  - Issue escalation

### 5. **Tech Support Specialist** 🔧
- **Dashboard**: System health monitoring
- **Features**:
  - API response time monitoring
  - Model inference metrics
  - System uptime tracking
  - Model deployment management
  - Error log viewing

### 6. **Administrator** 👨‍💼
- **Dashboard**: Platform management & analytics
- **Features**:
  - User management
  - Financial reporting (GMV, commissions)
  - Platform configuration
  - KYC approvals
  - Strategic metrics

---

## 🔐 Authentication Flow

### Login Options
1. **Google SSO** - One-click login with Google account
2. **Facebook SSO** - One-click login with Facebook
3. **Email/Password** - Traditional email-based login
4. **AADHAAR** (Coming Soon - Phase 2) - For enhanced authenticity

### After Login
1. Role selection screen
2. Role-specific dashboard
3. Access to role-based features

### Session Management
- User data stored in localStorage
- Automatic login persistence
- Secure logout clears session

---

## 🎨 Design & Aesthetics

### Color Scheme (Agricultural Green Theme)
- **Primary Green**: #2e7d32 (Forest green - nature, growth)
- **Secondary Green**: #1b5e20 (Deep agricultural green)
- **Accent Green**: #4caf50 (Vibrant, fresh produce)
- **Light Green**: #c8e6c9 (Fields, growth)
- **Sky Blue**: #81d4fa (Clear skies, positive)
- **Warning Amber**: #fbc02d (Sun, caution)
- **Success Teal**: #00897b (Fresh harvest)
- **Risk Red**: #d32f2f (Alerts, danger)

### Typography
- Font size base: 16px (readable, mobile-friendly)
- Line height: 1.6 (improved readability)
- Headings: Bold, hierarchical sizing

### Responsive Design
- Mobile-first approach
- Breakpoints: 375px (phone), 768px (tablet), 1024px (desktop)
- Flexible grids & layouts

---

## 🌐 Multi-Language Support

### Supported Languages (Current)
- **English** (en)
- **Hindi** (hi)

### Adding New Languages
1. Add translations to `TranslationService`
2. Update language selector dropdown
3. Add RTL support if needed (for Hindi, Gujarati, etc.)

### Language Selection
- Dropdown in login/navbar
- Persisted in localStorage
- Automatically applied to all UI

---

## 🔄 API Integration

### Prediction API (Mock Currently)
**Endpoint**: POST `/api/predict`

**Request**:
```json
{
  "file": <File object>
}
```

**Response** (Mock):
```json
{
  "crop": "🍅 Tomato",
  "confidence": 0.92,
  "confidence_level": "High",
  "health": "Good",
  "area_sqm": 2500,
  "risk_factors": ["Low soil moisture"],
  "recommendations": ["Increase irrigation"],
  "timestamp": "2025-12-04T10:30:00Z"
}
```

### Data Services
- **AuthService**: User authentication & role management
- **PredictionService**: Crop prediction (mock returns data)
- **TranslationService**: Multi-language support
- **MockDataService**: Mock data for dashboards

---

## 📁 Project Structure

```
frontend/angular/
├── src/
│   ├── app.component.ts           # Root component
│   ├── routes.ts                  # Route definitions
│   ├── main.ts                    # Bootstrap
│   ├── styles.css                 # Global styles
│   ├── components/
│   │   ├── login/
│   │   │   └── login.component.ts           # SSO login screen
│   │   ├── role-selection/
│   │   │   └── role-selection.component.ts  # 6-role selector
│   │   ├── unified-dashboard/
│   │   │   └── unified-dashboard.component.ts # All 6 dashboards
│   │   ├── navbar/
│   │   │   └── navbar.component.ts          # Navigation + user info
│   │   └── footer/
│   │       └── footer.component.ts
│   └── services/
│       ├── auth.service.ts                  # Authentication
│       ├── auth.guard.ts                    # Route protection
│       ├── translation.service.ts           # i18n support
│       ├── prediction.service.ts            # Mock predictions
│       ├── crop-ai.service.ts              # Legacy service
│       └── mock-data.service.ts            # Mock data
├── angular.json                  # Angular config
├── package.json                  # Dependencies
└── tsconfig.json               # TypeScript config
```

---

## ⚙️ Services & Dependencies

### Core Services

#### AuthService
```typescript
// Login/Logout
authService.login(user)
authService.logout()

// Get current user
authService.getCurrentUser() // Observable<User | null>

// Check authentication
authService.isAuthenticated() // Observable<boolean>

// Set user role
authService.setUserRole(role)

// SSO logins
authService.loginWithGoogle(email, name)
authService.loginWithFacebook(email, name)
```

#### TranslationService
```typescript
// Get current language
translationService.getCurrentLanguage() // returns: 'en' | 'hi'

// Set language
translationService.setLanguage('hi')

// Translate key
translationService.translate('login') // returns: 'Login' or 'लॉगिन'

// Get supported languages
translationService.getSupportedLanguages()
```

#### PredictionService
```typescript
// Mock prediction from file
predictionService.predictCrop(imageFile) // Observable<PredictionResult>

// Returns mock data after 2-second delay (simulates API call)
```

---

## 🧪 Testing Workflows

### Farmer Workflow
1. Login (Google/Facebook/Email)
2. Select "Farmer" role
3. Upload satellite image
4. Get instant crop prediction
5. View recommendations
6. Find services or sell direct

### Partner Workflow
1. Login
2. Select "Service Partner" role
3. View market intelligence
4. See farmers by crop type
5. Generate leads
6. Manage commissions

### Customer Workflow
1. Login
2. Select "Customer" role
3. Browse farmer marketplace
4. Verify crop authenticity
5. Place order
6. Track delivery

### Admin Workflow
1. Login
2. Select "Administrator" role
3. View financial metrics
4. Manage users
5. View platform statistics

---

## 🚨 Error Handling & Loading States

### Loading States
- "Uploading image..." - When file is being uploaded
- "Predicting crop..." - When model is processing
- "Prediction complete!" - Success state
- Button disabled during async operations

### Error Handling
- User-friendly error messages
- Automatic retry options
- Error logging to console
- Graceful fallbacks

### Validation
- File type validation (image only)
- File size limits
- Email format validation
- Required field checks

---

## 📱 Mobile Optimization

### Responsive Breakpoints
- **320px - 767px**: Mobile phones
- **768px - 1023px**: Tablets
- **1024px+**: Desktop

### Mobile-Specific Features
- Touch-friendly buttons (min 44x44px)
- Vertical layouts on small screens
- Hamburger menu (future)
- Bottom sheet dialogs (future)
- Native-like experience

---

## 🔄 State Management

### Current State Management
- **Authentication**: AuthService (BehaviorSubject)
- **Language**: TranslationService (BehaviorSubject)
- **Session**: localStorage for persistence
- **User Data**: In-memory service stores

### Data Flow
```
Login → AuthService.login() 
      → Store in localStorage 
      → BehaviorSubject emits 
      → Components subscribe 
      → UI updates
```

---

## 🎯 Next Steps & Future Enhancements

### Phase 2 (Coming Soon)
- [ ] AADHAAR-based authentication
- [ ] Real ML model integration
- [ ] Payment gateway integration
- [ ] Push notifications
- [ ] Offline mode support
- [ ] Progressive Web App (PWA)
- [ ] More Indian languages (Gujarati, Marathi, Tamil)
- [ ] Video tutorials in local languages

### Phase 3
- [ ] Advanced analytics & reporting
- [ ] Mobile app (React Native)
- [ ] Blockchain for supply chain transparency
- [ ] IoT sensor integration
- [ ] Predictive maintenance recommendations

---

## 🐛 Troubleshooting

### Common Issues

**"Cannot find module" errors**
- Run `npm install`
- Clear Angular cache: `ng cache clean`

**Dev server not starting**
- Kill any process on port 4200: `lsof -ti:4200 | xargs kill -9`
- Clear node_modules: `rm -rf node_modules && npm install`

**Styling issues**
- Clear browser cache (Ctrl+Shift+Delete)
- Hard refresh (Ctrl+F5)

**Authentication not persisting**
- Check localStorage in DevTools (F12 > Application > Storage > Local Storage)
- Clear corrupted data manually if needed

---

## 📊 Performance Targets

- **Bundle Size**: < 500KB (gzipped)
- **First Contentful Paint**: < 2s
- **Time to Interactive**: < 3s
- **Mobile Lighthouse Score**: > 90
- **API Response**: < 200ms
- **Model Inference**: < 5s

---

## 🔒 Security Considerations

### Currently Implemented
- SSO authentication (OAuth2 ready)
- localStorage for session storage (basic)
- Route guards for protected pages
- Role-based access control

### Future Security
- JWT tokens (Phase 2)
- HTTPS enforcement
- CORS configuration
- Security headers
- Input sanitization
- Rate limiting
- Audit logging

---

## 📚 Resources & References

- [Angular 16 Docs](https://angular.io/docs)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [Bootstrap 5](https://getbootstrap.com/docs/5.0/)
- [RxJS Guide](https://rxjs.dev/)

---

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review code comments in component files
3. Check browser console (F12)
4. Review application logs

---

**Version**: 1.0.0  
**Last Updated**: December 4, 2025  
**Status**: Production Ready (MVP)
