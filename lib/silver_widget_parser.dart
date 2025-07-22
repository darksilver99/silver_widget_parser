import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show HttpClient;
import 'package:silver_printer/silver_printer.dart';

/// Main parser class for converting Flutter widgets to PrintItems
class SilverWidgetParser {
  /// Parse a Flutter widget into a list of PrintItems
  static Future<List<PrintItem>> parseWidget(Widget widget, {
    List<dynamic>? foodListData,
    String? currentUserDisplayName,
  }) async {
    final parser = SilverWidgetParser._();
    
    // เก็บข้อมูลที่ต้องใช้สำหรับ ListView
    parser._foodListData = foodListData;
    parser._currentUserDisplayName = currentUserDisplayName;
    
    // Debug: แสดงข้อมูลที่ได้รับ
    print('SilverWidgetParser: foodListData length = ${foodListData?.length ?? 0}');
    print('SilverWidgetParser: currentUserDisplayName = $currentUserDisplayName');
    
    // หาก widget เป็น WidgetsToImage ให้เอา child มาใช้แทน
    Widget targetWidget = widget;
    if (widget.runtimeType.toString().contains('WidgetsToImage')) {
      try {
        final dynamic widgetsToImageWidget = widget;
        if (widgetsToImageWidget.child != null) {
          targetWidget = widgetsToImageWidget.child;
        }
      } catch (e) {
        print('Cannot extract child from WidgetsToImage: $e');
      }
    }
    
    return await parser._parseWidgetRecursive(targetWidget);
  }
  
  /// Parse receipt widget with ListView data extraction
  static Future<List<PrintItem>> parseReceiptWidget({
    required Widget widget,
    required List<dynamic> foodList,
    required String currentUserDisplayName,
    required String orderStatus,
    required String Function(List<dynamic>) getTotalPrice,
    required String Function(List<dynamic>) getTotalPriceOnlyServe,
    required String Function(DateTime) dateTimeTh,
    required String topImageUrl,
    required String bottomImageUrl,
    required String bottomText,
  }) async {
    final items = <PrintItem>[];
    
    // Top image
    if (topImageUrl.isNotEmpty) {
      try {
        final imageBytes = await SilverWidgetParser._()._downloadImage(topImageUrl);
        items.add(PrintItem.image(imageBytes));
        items.add(PrintItem.lineFeed());
      } catch (e) {
        print('Failed to download top image: $e');
      }
    }
    
    // Store name
    if (currentUserDisplayName.isNotEmpty) {
      items.add(PrintItem.text(
        currentUserDisplayName,
        size: TextSize.extraLarge,
        bold: true,
        alignment: TextAlignment.center,
      ));
      items.add(PrintItem.lineFeed());
    }
    
    // Title
    items.add(PrintItem.text(
      'Order.',
      size: TextSize.extraLarge,
      alignment: TextAlignment.left,
    ));
    items.add(PrintItem.lineFeed());
    
    // Food items from ListView data
    for (final foodItem in foodList) {
      final dynamic food = foodItem;
      final name = food.tmpSubject?.toString() ?? '';
      final quantity = food.quantity?.toString() ?? '0';
      final price = food.tmpPrice?.toString() ?? '0';
      final status = food.status?.toString() ?? '';
      
      final foodText = '$name x $quantity${status == 'ยกเลิก' ? ' ยกเลิก' : ''}';
      
      items.add(PrintItem.text(foodText, size: TextSize.large));
      items.add(PrintItem.text(price, size: TextSize.large, bold: true, alignment: TextAlignment.right));
    }
    
    items.add(PrintItem.lineFeed());
    
    // Total price
    final totalPrice = (orderStatus == 'เสร็จสิ้น' || orderStatus == 'ยกเลิก')
        ? getTotalPriceOnlyServe(foodList)
        : getTotalPrice(foodList);
        
    items.add(PrintItem.text(
      totalPrice,
      size: TextSize.extraLarge,
      bold: true,
      alignment: TextAlignment.right,
    ));
    items.add(PrintItem.lineFeed());
    
    // Date time
    final dateTime = dateTimeTh(DateTime.now());
    items.add(PrintItem.text(
      dateTime,
      size: TextSize.normal,
      bold: true,
      alignment: TextAlignment.center,
    ));
    items.add(PrintItem.lineFeed());
    
    // Bottom section
    if (bottomImageUrl.isNotEmpty) {
      items.add(PrintItem.text('--------------------------------', alignment: TextAlignment.center));
      items.add(PrintItem.lineFeed());
      items.add(PrintItem.text('QR Code สำหรับชำระเงิน', size: TextSize.normal, bold: true, alignment: TextAlignment.center));
      items.add(PrintItem.lineFeed());
      
      try {
        final imageBytes = await SilverWidgetParser._()._downloadImage(bottomImageUrl);
        items.add(PrintItem.image(imageBytes));
        items.add(PrintItem.lineFeed());
      } catch (e) {
        print('Failed to download bottom image: $e');
      }
    }
    
    // Bottom text
    if (bottomText.isNotEmpty) {
      items.add(PrintItem.text(
        bottomText,
        size: TextSize.normal,
        bold: true,
        alignment: TextAlignment.center,
      ));
      items.add(PrintItem.lineFeed());
    }
    
    return items;
  }

  /// Parse receipt data directly (recommended for complex receipt layouts)
  static Future<List<PrintItem>> parseReceiptData({
    String? topImageUrl,
    String? storeName,
    String? title = 'Order.',
    required List<Map<String, dynamic>> foodItems,
    required String totalPrice,
    String? dateTime,
    String? bottomImageUrl,
    String? bottomText,
  }) async {
    final items = <PrintItem>[];
    
    // Top image
    if (topImageUrl != null && topImageUrl.isNotEmpty) {
      try {
        final imageBytes = await SilverWidgetParser._()._downloadImage(topImageUrl);
        items.add(PrintItem.image(imageBytes));
        items.add(PrintItem.lineFeed());
      } catch (e) {
        print('Failed to download top image: $e');
      }
    }
    
    // Store name
    if (storeName != null && storeName.isNotEmpty) {
      items.add(PrintItem.text(
        storeName,
        size: TextSize.extraLarge,
        bold: true,
        alignment: TextAlignment.center,
      ));
      items.add(PrintItem.lineFeed());
    }
    
    // Title
    if (title != null && title.isNotEmpty) {
      items.add(PrintItem.text(
        title,
        size: TextSize.extraLarge,
        alignment: TextAlignment.left,
      ));
      items.add(PrintItem.lineFeed());
    }
    
    // Food items
    for (final food in foodItems) {
      final name = food['name'] as String? ?? '';
      final quantity = food['quantity']?.toString() ?? '0';
      final price = food['price']?.toString() ?? '0';
      final status = food['status'] as String? ?? '';
      
      final foodText = '$name x $quantity${status == 'ยกเลิก' ? ' ยกเลิก' : ''}';
      
      items.add(PrintItem.text(foodText, size: TextSize.large));
      items.add(PrintItem.text(price, size: TextSize.large, bold: true, alignment: TextAlignment.right));
    }
    
    items.add(PrintItem.lineFeed());
    
    // Total price
    items.add(PrintItem.text(
      totalPrice,
      size: TextSize.extraLarge,
      bold: true,
      alignment: TextAlignment.right,
    ));
    items.add(PrintItem.lineFeed());
    
    // Date time
    if (dateTime != null && dateTime.isNotEmpty) {
      items.add(PrintItem.text(
        dateTime,
        size: TextSize.normal,
        bold: true,
        alignment: TextAlignment.center,
      ));
      items.add(PrintItem.lineFeed());
    }
    
    // Bottom section
    if (bottomImageUrl != null && bottomImageUrl.isNotEmpty) {
      items.add(PrintItem.text('--------------------------------', alignment: TextAlignment.center));
      items.add(PrintItem.lineFeed());
      items.add(PrintItem.text('QR Code สำหรับชำระเงิน', size: TextSize.normal, bold: true, alignment: TextAlignment.center));
      items.add(PrintItem.lineFeed());
      
      try {
        final imageBytes = await SilverWidgetParser._()._downloadImage(bottomImageUrl);
        items.add(PrintItem.image(imageBytes));
        items.add(PrintItem.lineFeed());
      } catch (e) {
        print('Failed to download bottom image: $e');
      }
    }
    
    // Bottom text
    if (bottomText != null && bottomText.isNotEmpty) {
      items.add(PrintItem.text(
        bottomText,
        size: TextSize.normal,
        bold: true,
        alignment: TextAlignment.center,
      ));
      items.add(PrintItem.lineFeed());
    }
    
    return items;
  }
  
  SilverWidgetParser._();
  
  // Instance variables สำหรับเก็บข้อมูลที่ ListView ต้องใช้
  List<dynamic>? _foodListData;
  String? _currentUserDisplayName;
  
  /// Recursively parse widget tree
  Future<List<PrintItem>> _parseWidgetRecursive(Widget widget) async {
    final items = <PrintItem>[];
    
    try {
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
      } else if (widget is Expanded) {
        if (widget.child != null) {
          items.addAll(await _parseWidgetRecursive(widget.child));
        }
      } else if (widget is ClipRRect) {
        if (widget.child != null) {
          items.addAll(await _parseWidgetRecursive(widget.child!));
        }
      } else if (widget is SizedBox) {
        // SizedBox เป็น spacing - เพิ่ม line feed เฉพาะที่มี height
        if (widget.height != null && widget.height! > 0) {
          items.add(PrintItem.lineFeed());
        }
      } else if (widget is Divider) {
        // Divider แปลงเป็น separator text
        items.add(PrintItem.text('--------------------------------', 
            alignment: TextAlignment.center));
        items.add(PrintItem.lineFeed());
      } else {
        // Handle specific widget types
        print('Found unknown widget: ${widget.runtimeType}');
        if (widget.runtimeType.toString().contains('ListView')) {
          print('Parsing ListView...');
          items.addAll(await _parseListView(widget));
        } else if (widget.runtimeType.toString().contains('Builder')) {
          print('Parsing Builder widget: ${widget.runtimeType}');
          items.addAll(await _parseBuilderWidget(widget));
        } else {
          // สำหรับ widget อื่นๆ ที่ไม่รู้จัก ลองใช้ reflection หา child
          final dynamic widgetDynamic = widget;
          
          // ลองหา child property
          try {
            if (widgetDynamic.child != null) {
              items.addAll(await _parseWidgetRecursive(widgetDynamic.child));
            }
          } catch (e) {
            // ไม่มี child property
          }
          
          // ลองหา children property
          try {
            if (widgetDynamic.children != null) {
              final children = widgetDynamic.children as List<Widget>;
              for (final child in children) {
                items.addAll(await _parseWidgetRecursive(child));
              }
            }
          } catch (e) {
            // ไม่มี children property
          }
        }
      }
    } catch (e) {
      print('Error parsing widget ${widget.runtimeType}: $e');
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
        
        // สำหรับรูป เราจะแปลงเป็น text แทนเพื่อประหยัดเนื้อที่
        // หรือจัดการ aspect ratio ให้เหมาะสม
        return PrintItem.image(imageBytes);
      } catch (e) {
        // Return null if image download fails
        print('Failed to download image: $e');
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
  
  /// Parse ListView using provided food list data
  Future<List<PrintItem>> _parseListView(Widget widget) async {
    final items = <PrintItem>[];
    
    // ใช้ข้อมูลจริงที่ส่งมาแทนการ parse widget
    if (_foodListData != null) {
      for (final foodItem in _foodListData!) {
        try {
          final dynamic food = foodItem;
          final name = food.tmpSubject?.toString() ?? '';
          final quantity = food.quantity?.toString() ?? '0';
          final price = food.tmpPrice?.toString() ?? '0';
          final status = food.status?.toString() ?? '';
          
          final foodText = '$name x $quantity${status == 'ยกเลิก' ? ' ยกเลิก' : ''}';
          
          items.add(PrintItem.text(foodText, size: TextSize.large));
          items.add(PrintItem.text(price, size: TextSize.large, bold: true, alignment: TextAlignment.right));
        } catch (e) {
          print('Error parsing food item: $e');
        }
      }
    } else {
      // fallback หากไม่มีข้อมูล
      items.add(PrintItem.text('--- ไม่มีรายการสินค้า ---', size: TextSize.normal, alignment: TextAlignment.center));
    }
    
    return items;
  }
  
  /// Parse Builder widget 
  Future<List<PrintItem>> _parseBuilderWidget(Widget widget) async {
    final items = <PrintItem>[];
    
    try {
      // ตรวจสอบว่าเป็น AuthUserStreamWidget หรือไม่
      if (widget.runtimeType.toString().contains('AuthUserStreamWidget')) {
        // ใช้ข้อมูลจาก currentUserDisplayName ที่ส่งมา
        if (_currentUserDisplayName != null && _currentUserDisplayName!.isNotEmpty) {
          items.add(PrintItem.text(
            _currentUserDisplayName!,
            size: TextSize.extraLarge,
            bold: true,
            alignment: TextAlignment.center,
          ));
        }
      } else {
        final dynamic builder = widget;
        
        if (builder.builder != null) {
          // สร้าง mock context
          final mockContext = _MockBuildContext();
          final childWidget = builder.builder(mockContext);
          
          if (childWidget != null) {
            items.addAll(await _parseWidgetRecursive(childWidget));
          }
        }
      }
    } catch (e) {
      print('Cannot parse Builder widget: $e');
    }
    
    return items;
  }
}

/// Mock BuildContext สำหรับ parsing widgets ที่ต้องใช้ context
class _MockBuildContext implements BuildContext {
  @override
  bool get debugDoingBuild => false;
  
  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    throw UnimplementedError();
  }
  
  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    return null;
  }
  
  @override
  DiagnosticsNode describeElement(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }
  
  @override
  List<DiagnosticsNode> describeMissingAncestor({required Type expectedAncestorType}) {
    return [];
  }
  
  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    throw UnimplementedError();
  }
  
  @override
  DiagnosticsNode describeWidget(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }
  
  @override
  void dispatchNotification(Notification notification) {}
  
  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    return null;
  }
  
  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    return null;
  }
  
  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    return null;
  }
  
  @override
  RenderObject? findRenderObject() {
    return null;
  }
  
  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    return null;
  }
  
  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    return null;
  }
  
  @override
  T? getInheritedWidgetOfExactType<T extends InheritedWidget>() {
    return null;
  }
  
  @override
  BuildOwner? get owner => null;
  
  @override
  Size? get size => null;
  
  @override
  void visitAncestorElements(bool Function(Element element) visitor) {}
  
  @override
  void visitChildElements(ElementVisitor visitor) {}
  
  @override
  Widget get widget => throw UnimplementedError();
  
  @override
  bool get mounted => true;
}
