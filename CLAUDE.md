# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Flutter/Dart package called "silver_widget_parser" - currently a template package with placeholder Calculator class functionality. The project follows standard Flutter package structure and conventions.

## Development Commands

### Testing
```bash
flutter test                    # Run all tests
flutter test test/specific_test_file.dart  # Run specific test file
```

### Code Quality
```bash
flutter analyze                 # Run static analysis using flutter_lints
dart format .                   # Format all Dart code
dart format --set-exit-if-changed .  # Format check (CI-friendly)
```

### Package Management
```bash
flutter pub get                 # Get dependencies
flutter pub upgrade             # Upgrade dependencies
flutter pub deps                # Show dependency tree
```

### Build & Validation
```bash
flutter pub publish --dry-run   # Validate package for publishing
```

## Project Structure
- `lib/silver_widget_parser.dart` - Main library file with Calculator class
- `test/silver_widget_parser_test.dart` - Unit tests
- `pubspec.yaml` - Package configuration with Flutter SDK ^3.8.1
- `analysis_options.yaml` - Uses package:flutter_lints/flutter.yaml

## Code Architecture
Currently contains a simple Calculator class with an `addOne` method. This appears to be template code that will be replaced with actual widget parsing functionality.

The package is configured as a Flutter package (not plugin) and can be used in Flutter applications.