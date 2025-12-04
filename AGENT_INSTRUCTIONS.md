# GitHub Copilot Agent Instructions for CropAI

## 🎯 Critical Requirements

### 1. Always Provide External Review Link After Changes
**MANDATORY for every code change to web app:**
- After committing changes to Angular SPA or frontend files
- **USE THIS EXACT LINK FOR REVIEW:**
```
https://potential-orbit-q7j949p6j9j7fx9vx-4200.app.github.dev/
```
- This is the Angular SPA running on port 4200 (already configured)
- User accesses this from external computer to review changes
- Link is production-ready and works globally

**Expected message format after each frontend change:**
```
✅ Changes committed: [commit-hash]
🔗 Review Link: https://potential-orbit-q7j949p6j9j7fx9vx-4200.app.github.dev/
🎯 What to test: [specific features to review]
```

**CRITICAL:** Always use this exact link - DO NOT generate new URLs, DO NOT use localhost, DO NOT use index8.html

---

## 📋 Project Context

### Repository
- **Name**: crop-ai
- **Owner**: dlai-sd
- **Main branch**: main
- **Type**: Agricultural satellite imagery + crop identification platform

### Current Status (Dec 4, 2025)
- ✅ Landing page with satellite imagery (Bing + Esri)
- ✅ Interactive hero section with user type toggle
- ✅ Feature carousel (3 stakeholder views)
- ✅ Responsive design (mobile-first)
- ✅ Multi-language support (9 languages)
- ✅ Real satellite map integration
- 🔄 Phase 2 backend development starting

### Key Files
- **Angular SPA**: `/workspaces/crop-ai/frontend/angular/` (Main application)
- **SPA Dev Server**: Running on port 4200 (ng serve)
- **Review Link**: https://potential-orbit-q7j949p6j9j7fx9vx-4200.app.github.dev/
- **Static Landing Page**: `/workspaces/crop-ai/index8.html` (reference only)
- **Documentation**: `AGENT_INSTRUCTIONS.md` (this file), `PREVIEW_LINKS.md`, `docs/PHASE_2_ROADMAP.md`
- **Phase 2 Roadmap**: `docs/PHASE_2_ROADMAP.md`

---

## 🛠️ Development Workflow

### For Frontend Changes
1. Edit `index8.html` or related files
2. Commit with descriptive message
3. Push to origin/main
4. **ALWAYS provide external review link**
5. Specify what features to test

### For Backend/Documentation Changes
1. Edit relevant files
2. Commit with descriptive message
3. Push to origin/main
4. Provide summary of changes

### Git Commit Message Format
```
feat: add [feature name]
- Specific change 1
- Specific change 2
- Impact: [what user experiences]
```

---

## 🌐 External Link Generation

### Current Setup (PRODUCTION)
- **Angular SPA**: `/workspaces/crop-ai/frontend/angular/`
- **Dev Server**: `ng serve --proxy-config proxy.conf.json`
- **Running on**: port 4200
- **Public URL**: https://potential-orbit-q7j949p6j9j7fx9vx-4200.app.github.dev/

### How to Use
1. After any frontend changes, commit and push
2. Provide this link to user for review: **https://potential-orbit-q7j949p6j9j7fx9vx-4200.app.github.dev/**
3. User can access from any browser globally
4. No additional setup needed

---

## ✅ Checklist After Every Frontend Change

- [ ] Code edited and tested locally
- [ ] Git commit created with descriptive message
- [ ] Changes pushed to origin/main
- [ ] External link generated and provided to user
- [ ] Specific test instructions included
- [ ] Related todo items updated

---

## 📝 User Preferences

- **Communication**: Brief, direct, action-oriented
- **Code changes**: Implement by default (don't just suggest)
- **Reviews**: Always provide external link for web changes
- **Documentation**: Keep separate docs files minimal
- **Emoji**: Use sparingly, only for clarity

---

## 🚀 Priority Workflows (Coming)

### Phase 2A Foundation (In Queue)
1. Backend Service Architecture (#25)
2. Docker & Container Setup (#40)
3. ML Model Training Pipeline (#26)

### Future Enhancements (Post-MVP)
1. API development
2. Database integration
3. ML model integration
4. User authentication
5. Real-time data processing

---

**Last Updated**: December 4, 2025
**Critical Reminder**: External link ALWAYS provided after frontend changes!
