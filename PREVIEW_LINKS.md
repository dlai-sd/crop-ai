# CropAI Landing Page - Preview Links

## 🌐 Live Landing Page Preview

### Local Development (Codespace)
```
http://localhost:8000/index8.html
```

### External Access (via Codespace Ports)
To access the landing page from outside the codespace:

1. **Port Forward Method:**
   - Open VS Code Command Palette: `Cmd+Shift+P` (Mac) / `Ctrl+Shift+P` (Windows/Linux)
   - Type: `Forward a Port`
   - Enter port: `8000`
   - VS Code will generate a public URL like: `https://codespaces-514173-abcdefg.preview.app.github.dev/index8.html`

2. **GitHub Codespaces Ports Tab:**
   - Click "Ports" tab in VS Code
   - Look for port 8000
   - Click the globe icon to open in browser
   - Or right-click → "Open in Browser"

3. **Direct Codespace URL:**
   - Your codespace URL: `https://potential-orbit-q7j949p6j9j7fx9vx-abcd1234.github.dev/`
   - Full preview: Access via VS Code's port forwarding

## 🎯 What to Review

### ✅ Completed Features
- **Real Satellite Imagery**: Bing Maps + Esri high-resolution satellite data
- **Interactive Map**: Zoom, pan, click functionality
- **Responsive Design**: Works on desktop and mobile
- **Hero Section**: "Shall I plan this Crop?" with search interface
- **Analytics Panel**: Risk indicators and opportunity identification
- **Feature Carousel**: 3-slide carousel (Farmers, Partners, Customers)
- **User Toggle**: Switch between farmer/partner/customer views
- **Team Section**: Leadership team profiles
- **Multi-language Support**: 9 language options
- **Footer**: Contact info and social links

### 🎨 Design Highlights
- **Primary Color**: #2e7d32 (Forest Green)
- **Logo**: "DEEP LEARNING SATELLITE DATA" (uppercase)
- **Map Area**: 65% width with search overlay
- **Analytics**: 35% width with dynamic content
- **Smooth Animations**: All transitions optimized

### 📊 Latest Changes (Commit f1042d37)
- Replaced OpenStreetMap with real satellite imagery
- Bing Maps Aerial (primary) for high-resolution coverage
- Esri World Imagery (fallback) for redundancy
- Zero API key required
- Automatic fallback handling

## 🚀 Tech Stack
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Maps**: Leaflet 1.9.4
- **Satellite Imagery**: Bing Maps + Esri (free tier)
- **Font Icons**: Font Awesome 6.4.0
- **Responsive**: Mobile-first design

## 📝 To Test the App

1. **Map Interaction:**
   - Zoom in/out on the satellite map
   - Pan around Junner East, Pune area
   - Click the marker to see location info

2. **User Toggle:**
   - Click "I am a Farmer" / "I am a Service Partner" / "I am a Customer"
   - Watch analytics panel content update dynamically

3. **Feature Carousel:**
   - Click left/right arrows to navigate features
   - Click dots to jump to specific slide
   - Auto-advances every 5 seconds

4. **Language Selector:**
   - Select different languages
   - (Currently shows alert - full i18n coming in Phase 2)

5. **Navigation:**
   - Hover over menu items to see dropdowns
   - Smooth scroll to sections

## 🔗 GitHub Repository
- **Repo**: https://github.com/dlai-sd/crop-ai
- **Latest Commit**: f1042d37
- **Branch**: main

## 📱 Responsive Breakpoints
- ✅ Desktop: 1400px+
- ✅ Tablet: 768px - 992px
- ✅ Mobile: < 768px

---

**Generated**: December 4, 2025
**Last Updated**: After satellite imagery integration
