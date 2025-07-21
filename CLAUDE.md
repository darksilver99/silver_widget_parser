# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
silver_widget_parser is a Flutter Package (pure Dart) that converts Flutter Widgets to PrintItem lists for sending to silver_printer.printHybrid().

### Purpose
Solve iOS performance issues by avoiding full widget-to-image conversion → separate into text (fast) + image (as needed) for hybrid printing.

### Core Functionality
- **Input**: Flutter Widget (Container, Column, Text, Image, etc.)
- **Output**: List<PrintItem> for silver_printer
- **Goal**: Convert complex widgets → simple PrintItem list for hybrid printing

### Usage Pattern
```dart
// 1. Create widget (no WidgetsToImage needed)
final receiptWidget = Container(child: Column(...));

// 2. Convert to PrintItem list
final printItems = await SilverWidgetParser.parseWidget(receiptWidget);

// 3. Print hybrid
await SilverPrinter.instance.printHybrid(printItems);
```

### PrintItem Structure (from silver_printer)
- `PrintItem.text(content, size: TextSize.normal, bold: false, alignment: TextAlignment.left)`
- `PrintItem.image(imageBytes, width: 150)`
- `PrintItem.lineFeed(lines)`

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

### Key Components
1. **SilverWidgetParser** - Main entry point with `parseWidget()` method
2. **PrintItem Classes** - Data structures for text, image, and line feed items
3. **Widget Tree Analyzer** - Recursively processes Flutter widget tree
4. **Style Mappers** - Convert TextStyle → PrintItem properties
5. **Image Processor** - Download and convert Image.network to Uint8List

### Implementation Tasks
1. Create `SilverWidgetParser.parseWidget()` - main conversion method
2. Widget tree analysis - identify Text, Image, layout widgets
3. TextStyle mapping - fontSize → TextSize, fontWeight → bold, textAlign → alignment
4. Image.network downloading - convert to Uint8List
5. Layout support - Row, Column, Padding positioning

### Supported Widgets
- **Text** → PrintItem.text with style mapping
- **Image.network** → PrintItem.image with downloaded bytes
- **Container/Column/Row** → Layout analysis for positioning
- **Padding** → Spacing considerations

The package converts complex Flutter widget trees into simple, printer-optimized PrintItem lists for hybrid printing performance.