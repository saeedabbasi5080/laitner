import 'dart:typed_data';

import 'package:excel/excel.dart';

class ExcelEncodeException implements Exception {
  ExcelEncodeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExcelWorkbookEncoder {
  /// Column A = front (key), column B = back (value). No header row so the
  /// file round-trips with [ExcelParser] and Anki/Quizlet-style two-field lists.
  static Uint8List encodeKeyValue(
    Iterable<({String front, String back})> rows,
  ) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    var count = 0;
    for (final row in rows) {
      final front = row.front.trim();
      final back = row.back.trim();
      if (front.isEmpty || back.isEmpty) continue;
      sheet.appendRow([TextCellValue(front), TextCellValue(back)]);
      count++;
    }

    if (count == 0) {
      throw ExcelEncodeException('ردیفی برای خروجی وجود ندارد');
    }

    final bytes = excel.save();
    if (bytes == null || bytes.isEmpty) {
      throw ExcelEncodeException('ساخت فایل اکسل ناموفق بود');
    }
    return Uint8List.fromList(bytes);
  }

  static String fileNameForDeck(String deckName) {
    var base = deckName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    base = base.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (base.isEmpty) base = 'deck';
    if (base.length > 80) base = base.substring(0, 80).trim();
    return '$base.xlsx';
  }
}
