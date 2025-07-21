import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:silver_widget_parser/silver_widget_parser.dart';

void main() {
  group('SilverWidgetParser', () {
    test('parses Text widget correctly', () async {
      const textWidget = Text(
        'Hello World',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      );
      
      final printItems = await SilverWidgetParser.parseWidget(textWidget);
      
      expect(printItems.length, 1);
      expect(printItems[0], isA<TextPrintItem>());
      
      final textItem = printItems[0] as TextPrintItem;
      expect(textItem.content, 'Hello World');
      expect(textItem.size, TextSize.large);
      expect(textItem.bold, true);
      expect(textItem.alignment, TextAlignment.center);
    });
    
    test('parses Column with multiple Text widgets', () async {
      const columnWidget = Column(
        children: [
          Text('Title', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('Subtitle', style: TextStyle(fontSize: 16)),
          Text('Footer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300)),
        ],
      );
      
      final printItems = await SilverWidgetParser.parseWidget(columnWidget);
      
      expect(printItems.length, 3);
      expect(printItems.every((item) => item is TextPrintItem), true);
      
      final items = printItems.cast<TextPrintItem>();
      expect(items[0].content, 'Title');
      expect(items[0].size, TextSize.extraLarge);
      expect(items[0].bold, true);
      
      expect(items[1].content, 'Subtitle');
      expect(items[1].size, TextSize.normal);
      expect(items[1].bold, false);
      
      expect(items[2].content, 'Footer');
      expect(items[2].size, TextSize.small);
      expect(items[2].bold, false);
    });
    
    test('parses Container with nested widgets', () async {
      final containerWidget = Container(
        child: Column(
          children: [
            const Text('Nested Text', style: TextStyle(fontSize: 20)),
            Container(
              child: const Text('Deeply Nested', textAlign: TextAlign.right),
            ),
          ],
        ),
      );
      
      final printItems = await SilverWidgetParser.parseWidget(containerWidget);
      
      expect(printItems.length, 2);
      expect(printItems.every((item) => item is TextPrintItem), true);
      
      final items = printItems.cast<TextPrintItem>();
      expect(items[0].content, 'Nested Text');
      expect(items[1].content, 'Deeply Nested');
      expect(items[1].alignment, TextAlignment.right);
    });
    
    test('handles empty widgets gracefully', () async {
      final emptyContainer = Container();
      
      final printItems = await SilverWidgetParser.parseWidget(emptyContainer);
      
      expect(printItems.isEmpty, true);
    });
  });
  
  group('TextSize mapping', () {
    test('maps font sizes correctly', () async {
      final testCases = [
        (10.0, TextSize.small),
        (12.0, TextSize.small),
        (14.0, TextSize.normal),
        (16.0, TextSize.normal),
        (20.0, TextSize.large),
        (24.0, TextSize.large),
        (32.0, TextSize.extraLarge),
      ];
      
      for (final (fontSize, expectedSize) in testCases) {
        final textWidget = Text(
          'Test',
          style: TextStyle(fontSize: fontSize),
        );
        
        final printItems = await SilverWidgetParser.parseWidget(textWidget);
        final textItem = printItems[0] as TextPrintItem;
        
        expect(textItem.size, expectedSize, 
            reason: 'fontSize $fontSize should map to $expectedSize');
      }
    });
  });
  
  group('Font weight mapping', () {
    test('maps font weights to bold correctly', () async {
      final testCases = [
        (FontWeight.w100, false),
        (FontWeight.w300, false),
        (FontWeight.w400, false),
        (FontWeight.w500, false),
        (FontWeight.w600, true),
        (FontWeight.w700, true),
        (FontWeight.w900, true),
        (FontWeight.bold, true),
        (FontWeight.normal, false),
      ];
      
      for (final (fontWeight, expectedBold) in testCases) {
        final textWidget = Text(
          'Test',
          style: TextStyle(fontWeight: fontWeight),
        );
        
        final printItems = await SilverWidgetParser.parseWidget(textWidget);
        final textItem = printItems[0] as TextPrintItem;
        
        expect(textItem.bold, expectedBold,
            reason: 'fontWeight $fontWeight should map to bold: $expectedBold');
      }
    });
  });
  
  group('Text alignment mapping', () {
    test('maps text alignment correctly', () async {
      final testCases = [
        (TextAlign.left, TextAlignment.left),
        (TextAlign.center, TextAlignment.center),
        (TextAlign.right, TextAlignment.right),
        (TextAlign.end, TextAlignment.right),
        (TextAlign.start, TextAlignment.left),
        (TextAlign.justify, TextAlignment.left),
      ];
      
      for (final (textAlign, expectedAlignment) in testCases) {
        final textWidget = Text(
          'Test',
          textAlign: textAlign,
        );
        
        final printItems = await SilverWidgetParser.parseWidget(textWidget);
        final textItem = printItems[0] as TextPrintItem;
        
        expect(textItem.alignment, expectedAlignment,
            reason: 'textAlign $textAlign should map to $expectedAlignment');
      }
    });
  });
  
  group('PrintItem factories', () {
    test('creates TextPrintItem correctly', () {
      final textItem = PrintItem.text(
        'Test Content',
        size: TextSize.large,
        bold: true,
        alignment: TextAlignment.center,
      ) as TextPrintItem;
      
      expect(textItem.content, 'Test Content');
      expect(textItem.size, TextSize.large);
      expect(textItem.bold, true);
      expect(textItem.alignment, TextAlignment.center);
    });
    
    test('creates ImagePrintItem correctly', () {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final imageItem = PrintItem.image(
        imageBytes,
        width: 200,
      ) as ImagePrintItem;
      
      expect(imageItem.imageBytes, imageBytes);
      expect(imageItem.width, 200);
    });
    
    test('creates LineFeedPrintItem correctly', () {
      final lineFeedItem = PrintItem.lineFeed(3) as LineFeedPrintItem;
      
      expect(lineFeedItem.lines, 3);
    });
    
    test('creates LineFeedPrintItem with default lines', () {
      final lineFeedItem = PrintItem.lineFeed() as LineFeedPrintItem;
      
      expect(lineFeedItem.lines, 1);
    });
  });
}
