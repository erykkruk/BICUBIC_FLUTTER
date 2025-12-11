# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BICUBIC_FLUTTER is a Flutter application. The project is currently in initial setup phase.

## Common Commands

```bash
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device_id>

# Build commands
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build ios          # iOS
flutter build web          # Web

# Run tests
flutter test                        # All tests
flutter test test/widget_test.dart  # Single test file
flutter test --coverage             # With coverage

# Code quality
flutter analyze           # Static analysis
dart format .             # Format code

# Generate code (if using build_runner)
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

*(To be documented as the codebase develops)*

## License

Apache License 2.0
