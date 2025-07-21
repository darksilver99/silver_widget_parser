import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:io' show HttpClient;
import 'package:silver_printer/silver_printer.dart';

// Export classes เพื่อให้ user ไม่ต้อง import silver_printer เพิ่ม
export 'package:silver_printer/silver_printer.dart' show PrintItem, TextSize, TextAlignment;

/// Main parser class for converting Flutter widgets to PrintItems
class SilverWidgetParser {
  /// Parse a Flutter widget into a list of PrintItems
  static Future<List<PrintItem>> parseWidget(Widget widget) async {
    final parser = SilverWidgetParser._();
    return await parser._parseWidgetRecursive(widget);
  }
  
  SilverWidgetParser._();
  
  /// Recursively parse widget tree
  Future<List<PrintItem>> _parseWidgetRecursive(Widget widget) async {
    final items = <PrintItem>[];
    
    if (widget is Text) {
      items.add(_parseTextWidget(widget));
    } else if (widget is Image) {
      final imageItem = await _parseImageWidget(widget);
      if (imageItem != null) items.add(imageItem);
    } else if (widget is Container) {
      if (widget.child != null) {
        items.addAll(await _parseWidgetRecursive(widget.child!));
      }
    } else if (widget is Column) {
      for (final child in widget.children) {
        items.addAll(await _parseWidgetRecursive(child));
      }
    } else if (widget is Row) {
      for (final child in widget.children) {
        items.addAll(await _parseWidgetRecursive(child));
      }
    } else if (widget is Padding) {
      if (widget.child != null) {
        items.addAll(await _parseWidgetRecursive(widget.child!));
      }
    }
    
    return items;
  }
  
  /// Parse Text widget to PrintItem
  PrintItem _parseTextWidget(Text widget) {
    final style = widget.style ?? const TextStyle();
    
    return PrintItem.text(
      widget.data ?? '',
      size: _mapFontSizeToTextSize(style.fontSize),
      bold: _isBold(style.fontWeight),
      alignment: _mapTextAlignToAlignment(widget.textAlign),
    );
  }
  
  /// Parse Image widget to PrintItem
  Future<PrintItem?> _parseImageWidget(Image widget) async {
    if (widget.image is NetworkImage) {
      final networkImage = widget.image as NetworkImage;
      try {
        final imageBytes = await _downloadImage(networkImage.url);
        return PrintItem.image(imageBytes);
      } catch (e) {
        // Return null if image download fails
        return null;
      }
    }
    return null;
  }
  
  /// Download image from network URL
  Future<Uint8List> _downloadImage(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = await response.expand((chunk) => chunk).toList();
        return Uint8List.fromList(bytes);
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } finally {
      client.close();
    }
  }
  
  /// Map Flutter font size to TextSize enum
  TextSize _mapFontSizeToTextSize(double? fontSize) {
    if (fontSize == null) return TextSize.normal;
    
    if (fontSize <= 12) return TextSize.small;
    if (fontSize <= 16) return TextSize.normal;
    if (fontSize <= 24) return TextSize.large;
    return TextSize.extraLarge;
  }
  
  /// Check if font weight represents bold
  bool _isBold(FontWeight? fontWeight) {
    if (fontWeight == null) return false;
    return fontWeight.index >= FontWeight.w600.index;
  }
  
  /// Map Flutter TextAlign to TextAlignment enum
  TextAlignment _mapTextAlignToAlignment(TextAlign? textAlign) {
    switch (textAlign) {
      case TextAlign.center:
        return TextAlignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return TextAlignment.right;
      default:
        return TextAlignment.left;
    }
  }
}
