
<img width="300" height="100" alt="Progetto senza titolo (2)" src="https://github.com/user-attachments/assets/c483c98c-32d7-4e8e-b742-ef63b3b41425" />

# WebWrap

**Transform any website into a native mobile app with Flutter**

WebWrap is a lightweight, highly configurable Flutter app that wraps any website into a native mobile experience. Perfect for quickly deploying web apps to iOS and Android app stores.

<p float="left">
  <img src="https://github.com/user-attachments/assets/45e470ae-5865-4a13-a8b9-dd5f9c4d6d11" width="49%" alt="Simulator Screenshot - iPhone 17 Pro Max - 2025-10-17 at 01 26 36" />
  <img src="https://github.com/user-attachments/assets/85d0939e-ec9d-4326-b00d-32a6b81c35aa" width="49%" alt="Simulator Screenshot - iPhone 17 Pro Max - 2025-10-17 at 01 26 24" />
</p>


## Features

✅ **Single YAML Configuration** - Configure everything from one file
✅ **Native Feel** - Gesture navigation, system integration, adaptive theming
✅ **Dark Mode Support** - Automatic, light, or dark theme modes
✅ **Offline Ready** - Works offline with WebView caching
✅ **Native URL Handling** - Opens tel:, mailto:, maps:, and social links in native apps
✅ **Customizable Splash Screen** - Brand your app with custom logo and colors
✅ **iOS-Style Swipe Navigation** - Swipe from left edge to go back
✅ **Store Ready** - Meets Apple and Google Play requirements

## Quick Start


### 1. Clone & Install

```bash
git clone <your-repo>
cd webwrap
flutter pub get
```

### 2. Configure Your App

Edit `assets/config.yaml`:

```yaml
app:
  name: "My App"
  website_url: "https://yourwebsite.com"
  description: "Your app description"

theme:
  dark_mode: "system"  # "system", "light", or "dark"
  light:
    primary_color: "#2196F3"
    background_color: "#FFFFFF"
  dark:
    primary_color: "#1976D2"
    background_color: "#121212"
```

### 3. Add Your Logo

Place your logo at `assets/splash/logo.png` (150x150px recommended)

### 4. Run

```bash
flutter run
```

## Configuration

### App Settings

```yaml
app:
  name: "App Name"              # App title
  website_url: "https://..."    # Website to wrap
  description: "Description"    # App description
```

### Theme & Dark Mode

WebWrap supports three theme modes:
- `system` - Follows device settings (default)
- `light` - Always light theme
- `dark` - Always dark theme

```yaml
theme:
  dark_mode: "system"

  light:
    primary_color: "#2196F3"
    status_bar_color: "#1976D2"
    status_bar_brightness: "dark"
    background_color: "#FFFFFF"

  dark:
    primary_color: "#1976D2"
    status_bar_color: "#000000"
    status_bar_brightness: "light"
    background_color: "#121212"
```

### Splash Screen

```yaml
splash_screen:
  image: "assets/splash/logo.png"
  background_color: "#FFFFFF"
  duration_seconds: 2
```

### WebView Settings

```yaml
webview:
  enable_javascript: true
  enable_dom_storage: true
  enable_zoom: false
  clear_cache_on_start: false
  allow_media_playback: true
  allow_inline_media_playback: true
  user_agent: null  # null = default
```

### Native URL Handlers

URLs with these prefixes will open in native apps:

```yaml
native_url_handlers:
  - "tel:"        # Phone calls
  - "mailto:"     # Email
  - "sms:"        # SMS messages
  - "maps:"       # Maps
  - "whatsapp:"   # WhatsApp
  - "tg:"         # Telegram
```

### Offline Mode

```yaml
offline:
  enabled: true

  light:
    background_color: "#F5F5F5"
    text_color: "#333333"

  dark:
    background_color: "#121212"
    text_color: "#FFFFFF"
```

## Features in Detail

### Gesture Navigation

Swipe from the left edge to navigate back - works just like iOS Safari. A subtle indicator appears during the gesture.

### Offline Support

The app works offline by leveraging WebView's native caching:
- Automatically caches visited pages
- Shows toast notifications when going offline/online
- WebView remains visible even without connection

### Dark Mode

Automatically adapts to system theme or uses fixed light/dark mode. All UI elements (status bar, background, indicators) respect the current theme.

### Store Compliance

WebWrap includes features required for App Store and Play Store approval:
- Offline functionality (required by Apple)
- Native gesture navigation
- Proper error handling
- System integration (status bar, safe areas)

## Building for Production

### iOS

```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode to:
- Configure signing
- Set bundle identifier
- Upload to App Store Connect

### Android

```bash
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Google Play Console.

## Project Structure

```
webwrap/
├── assets/
│   ├── config.yaml          # Main configuration
│   └── splash/
│       └── logo.png         # Splash screen logo
├── lib/
│   ├── config/              # Configuration models
│   ├── screens/             # UI screens
│   ├── services/            # Business logic
│   └── main.dart            # App entry point
└── pubspec.yaml             # Dependencies
```

## Requirements

- Flutter 3.9.2+
- Dart 3.0+
- iOS 12.0+ / Android 5.0+

## Dependencies

- `webview_flutter` - WebView implementation
- `connectivity_plus` - Network status monitoring
- `url_launcher` - Native URL handling
- `shared_preferences` - Local storage
- `yaml` - Configuration parsing

## License

MIT License - See LICENSE file for details

## Support

For issues and feature requests, please open an issue on GitHub.

---

**Made with Flutter** 💙
