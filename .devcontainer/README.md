# Flutter Web Development in Codespaces

This DevContainer configuration enables Flutter web development within GitHub Codespaces.

## Features

✅ Flutter SDK (stable channel)  
✅ Dart SDK  
✅ Port forwarding (8080 for web app)  
✅ VS Code extensions: Dart, Flutter, Prettier  
✅ Web development enabled  

## Getting Started

### 1. Rebuild Codespace (if freshly created)
The `.devcontainer/devcontainer.json` will automatically run `setup.sh` after container creation.

### 2. Verify Installation
```bash
flutter --version
dart --version
```

### 3. Run Flutter Web App
```bash
cd /workspaces/crop-ai/mobile
flutter pub get
flutter run -d web-server --web-port=8080
```

Your app will be available at: `http://localhost:8080`

## Development Workflow

### Build
```bash
flutter build web
```

### Run with Hot Reload
```bash
flutter run -d web-server --web-port=8080
```

### Testing
```bash
flutter test
```

## Ports

- **8080**: Flutter Web App
- **5037**: ADB Server (for future Android device support)

## Limitations

❌ Android emulator (not available in Linux container)  
❌ iOS development (Linux-based environment)  
✅ Flutter web (fully supported)  
✅ Flutter desktop on Linux (supported)  

For mobile testing, use:
- Physical devices (via ADB over network)
- Cloud device services (Firebase Test Lab)
- Local machine with Android/iOS SDKs

## Environment Variables

- `FLUTTER_ROOT=/opt/flutter`
- `ANDROID_SDK_ROOT=/opt/android-sdk`
- `PATH` includes Flutter bin

## Troubleshooting

### Flutter not found
```bash
export PATH="/opt/flutter/bin:$PATH"
```

### Pub get fails
```bash
flutter pub cache clean
flutter pub get
```

### Port already in use
```bash
flutter run -d web-server --web-port=9090
```

## Additional Resources

- [Flutter Web Documentation](https://flutter.dev/web)
- [Dart Documentation](https://dart.dev/guides)
- [GitHub Codespaces Docs](https://docs.github.com/en/codespaces)
