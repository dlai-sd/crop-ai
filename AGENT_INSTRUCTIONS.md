# GitHub Copilot Agent Instructions for CropAI

## 🎯 Critical Requirements

### 1. Always Provide External Review Link After Changes
**MANDATORY for every code change to web app:**
- After committing changes to `index8.html` or frontend files
- Generate and display the external Codespace URL
- Format: `https://codespaces-XXXXX-YYYYY.preview.app.github.dev/index8.html`
- User needs this link to review changes in their browser

**How to get the link:**
```bash
# Check if port 8000 is forwarded
# If not, user should:
# 1. Open VS Code Command Palette: Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows/Linux)
# 2. Type: "Forward a Port"
# 3. Enter: 8000
# 4. VS Code generates public URL automatically
```

**Expected message format after each frontend change:**
```
✅ Changes committed: [commit-hash]
🔗 External Review Link: https://codespaces-XXXXX-YYYYY.preview.app.github.dev/index8.html
🎯 What to test: [specific features to review]
```

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
- **Landing Page**: `/workspaces/crop-ai/index8.html` (static HTML)
- **Dev Server**: Python HTTP server on port 8000
- **Preview Guide**: `PREVIEW_LINKS.md`
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

### Current Setup
- **HTTP Server**: `python3 -m http.server 8000`
- **Running on**: localhost:8000
- **Root path**: /workspaces/crop-ai/

### Steps to Get External Link
1. VS Code Ports Tab (bottom of screen)
2. Find port 8000 → Click globe icon 🌐
3. OR Command Palette → "Forward a Port" → Enter 8000
4. VS Code auto-generates public URL

### Link Format
```
https://codespaces-[WORKSPACE-ID]-[RANDOM-STRING].preview.app.github.dev/index8.html
```

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
