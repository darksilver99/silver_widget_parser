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
      // Test would work when silver_printer is available
      // For now, we test the parsing logic works
      expect(printItems, isNotEmpty);
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
    });
    
    test('handles empty widgets gracefully', () async {
      final emptyContainer = Container();
      
      final printItems = await SilverWidgetParser.parseWidget(emptyContainer);
      
      expect(printItems.isEmpty, true);
    });
  });
}