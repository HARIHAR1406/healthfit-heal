# HealthFit Heal
## A Production-Ready Flutter Android Fitness & Health Application

### Tech Stack
- **Flutter** 3.x (Material Design 3)
- **State Management**: Riverpod 2 + Riverpod Generator
- **Navigation**: GoRouter
- **Networking**: Dio + Interceptors
- **Local Storage**: Hive Flutter
- **Secure Storage**: flutter_secure_storage
- **Firebase**: firebase_core (placeholder configured)
- **Charts**: fl_chart
- **Animations**: Lottie
- **SVG**: flutter_svg
- **Logging**: logger
- **DI**: get_it

### Project Structure
```
lib/
├── core/           # App-wide infrastructure (network, router, storage, utils)
├── config/         # Firebase & environment configuration
├── design_system/  # Colors, typography, spacing, icons, animations tokens
├── theme/          # Light & dark Material Design 3 themes
├── shared/         # Reusable widgets
├── features/       # Feature modules (feature-first architecture)
└── main.dart       # App entry point
```

### Getting Started
```bash
# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run

# Build release APK
flutter build apk --release
```

### Development Commands
```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Watch mode for code generation
dart run build_runner watch --delete-conflicting-outputs
```
