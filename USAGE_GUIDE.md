# คู่มือการใช้งาน silver_widget_parser

## ปัญหาเดิม 🐌
```dart
// ช้า: แปลงทั้ง widget เป็นรูป
final bytes = await controller.capture();
await printer.printImage(bytes); // ปริ้นรูปทั้งใส = ช้ามาก
```

## วิธีแก้ใหม่ ⚡
```dart
// เร็ว: แปลง widget เป็น text + image แยกกัน
final printItems = await SilverWidgetParser.parseWidget(receiptWidget);
await printer.printHybrid(printItems); // text เร็ว + image เฉพาะที่จำเป็น
```

---

## การติดตั้ง

### 1. เพิ่ม dependency
```yaml
dependencies:
  silver_widget_parser: ^0.0.1
```

### 2. Import package
```dart
import 'package:silver_widget_parser/silver_widget_parser.dart';
```

---

## การใช้งานในโปรเจค

### ขั้นตอนที่ 1: แก้ไข Widget

**เดิม (ใช้ WidgetsToImage):**
```dart
WidgetsToImageController controller = WidgetsToImageController();

Widget build(BuildContext context) {
  return WidgetsToImage(
    controller: controller,
    child: Container(
      child: Column(
        children: [
          Image.network('logo.png', width: 150),
          Text('ร้านอาหาร ABC', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          Text('ข้าวผัดกุ้ง x 2', style: TextStyle(fontSize: 18)),
          Text('รวม: 240 บาท', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  );
}
```

**ใหม่ (ใช้ silver_widget_parser):**
```dart
// ✅ ไม่ต้องใช้ WidgetsToImageController
Widget _buildReceiptWidget() {
  return Container(
    child: Column(
      children: [
        Image.network('logo.png', width: 150),
        Text('ร้านอาหาร ABC', 
             style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Text('ข้าวผัดกุ้ง x 2', 
             style: TextStyle(fontSize: 18)),
        Text('รวม: 240 บาท', 
             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
```

### ขั้นตอนที่ 2: แก้ไขฟังก์ชันพิมพ์

**เดิม (ช้า):**
```dart
Future<bool> printSlipOld(WidgetsToImageController controller) async {
  try {
    final printer = SilverPrinter.instance;
    final isConnected = await printer.isConnected();
    if (!isConnected) return false;

    // 🐌 แปลงทั้งหมดเป็นรูป (ช้า)
    final bytes = await controller.capture();
    if (bytes == null) return false;

    // 🐌 พิมพ์รูปทั้งใส (ช้ามาก)
    final success = await printer.printImage(bytes, width: 384);
    return success;
  } catch (e) {
    return false;
  }
}
```

**ใหม่ (เร็ว):**
```dart
Future<bool> printSlipHybrid(Widget receiptWidget) async {
  try {
    final printer = SilverPrinter.instance;
    final isConnected = await printer.isConnected();
    if (!isConnected) return false;

    // ⚡ แปลง widget เป็น PrintItem list (เร็ว)
    final printItems = await SilverWidgetParser.parseWidget(receiptWidget);
    if (printItems.isEmpty) return false;

    // ⚡ พิมพ์แบบ hybrid: text เร็ว + image เฉพาะที่จำเป็น (เร็วมาก)
    final success = await printer.printHybrid(
      printItems,
      settings: {
        'paperWidth': 384, // 58mm paper
        'density': 'medium',
        'feedLines': 3,
      },
    );
    return success;
  } catch (e) {
    return false;
  }
}
```

### ขั้นตอนที่ 3: เรียกใช้งาน

**เดิม:**
```dart
onPressed: () async {
  final success = await printSlipOld(controller);
  if (success) print("ปริ้นสำเร็จ");
}
```

**ใหม่:**
```dart
onPressed: () async {
  final receiptWidget = _buildReceiptWidget();
  final success = await printSlipHybrid(receiptWidget);
  if (success) print("ปริ้นสำเร็จ (เร็วขึ้น!)");
}
```

---

## ผลลัพธ์ที่ได้

### Input Widget:
```dart
Container(
  child: Column(
    children: [
      Image.network('logo.png', width: 150),
      Text('ร้านอาหาร ABC', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
      Text('ข้าวผัดกุ้ง x 2', style: TextStyle(fontSize: 18)),
      Text('รวม: 240 บาท', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
    ],
  ),
)
```

### Output PrintItem List:
```dart
[
  PrintItem.image(logoImageBytes, width: 150),                    // รูปโลโก้
  PrintItem.text('ร้านอาหาร ABC', 
                  size: TextSize.extraLarge, 
                  bold: true, 
                  alignment: TextAlignment.center),               // ข้อความใหญ่ตัวหนา
  PrintItem.text('ข้าวผัดกุ้ง x 2', 
                  size: TextSize.normal),                         // ข้อความปกติ
  PrintItem.text('รวม: 240 บาท', 
                  size: TextSize.large, 
                  bold: true, 
                  alignment: TextAlignment.right),                // ข้อความใหญ่ชิดขวา
]
```

---

## ข้อดีของ Hybrid Printing

| วิธีเดิม (printImage) | วิธีใหม่ (printHybrid) |
|----------------------|------------------------|
| 🐌 แปลงทั้งหมดเป็นรูป | ⚡ แยก text + image |
| 🐌 ปริ้นรูปทั้งใส | ⚡ text เร็ว, image เฉพาะที่จำเป็น |
| ❌ ช้ามากใน iOS | ✅ เร็วขึ้นเยอะ |
| ❌ ใช้ memory เยอะ | ✅ ใช้ memory น้อย |
| ❌ คุณภาพ text อาจเบลอ | ✅ text คมชัด |

---

## Widget ที่รองรับ

| Widget | การแปลง |
|--------|----------|
| `Text` | → `PrintItem.text` พร้อม style mapping |
| `Image.network` | → `PrintItem.image` ดาวน์โหลดอัตโนมัติ |
| `Container` | → วิเคราะห์ child widget |
| `Column/Row` | → วิเคราะห์ children ตามลำดับ |
| `Padding` | → วิเคราะห์ child widget |

## Style Mapping

| Flutter TextStyle | PrintItem |
|------------------|-----------|
| `fontSize: 12` | `TextSize.small` |
| `fontSize: 16` | `TextSize.normal` |
| `fontSize: 24` | `TextSize.large` |
| `fontSize: 32+` | `TextSize.extraLarge` |
| `fontWeight: FontWeight.w600+` | `bold: true` |
| `textAlign: TextAlign.center` | `alignment: TextAlignment.center` |
| `textAlign: TextAlign.right` | `alignment: TextAlignment.right` |

---

## การ Debug

```dart
final printItems = await SilverWidgetParser.parseWidget(receiptWidget);

// ตรวจสอบผลลัพธ์
for (final item in printItems) {
  if (item is TextPrintItem) {
    print('Text: ${item.content}, Size: ${item.size}, Bold: ${item.bold}');
  } else if (item is ImagePrintItem) {
    print('Image: ${item.imageBytes.length} bytes, Width: ${item.width}');
  }
}
```

---

## Tips สำหรับการใช้งาน

1. **ใช้ TextStyle ที่ชัดเจน** - ระบุ fontSize, fontWeight, textAlign เพื่อให้ mapping ถูกต้อง
2. **ใช้ Image.network** - รองรับการดาวน์โหลดอัตโนมัติ
3. **เทสก่อนใช้งานจริง** - ลองดู printItems ที่ได้ออกมา
4. **ตั้งค่า paperWidth** - 384 สำหรับ 58mm, 576 สำหรับ 80mm

ความเร็วที่เพิ่มขึ้นจะเห็นได้ชัดเจนมากใน iOS! 🚀