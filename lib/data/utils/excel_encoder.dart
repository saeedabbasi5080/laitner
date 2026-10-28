import 'dart:typed_data';

import 'package:excel/excel.dart';

class ExcelEncodeException implements Exception {
  ExcelEncodeException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExcelWorkbookEncoder {
  /// Column A = front (key), column B = back (value), column C = optional
  /// tags.
  ///
  /// No header row, so the file still round-trips with [ExcelParser] and with
  /// Anki/Quizlet-style two-field lists. The tag column is only written when a
  /// row actually has tags, which keeps plain exports byte-identical to before.
  static Uint8List encodeKeyValue(
    Iterable<({String front, String back, List<String> tags})> rows,
  ) {
    final excel = Excel.createExcel();
    final sheetName = excel.getDefaultSheet() ?? 'Sheet1';
    final sheet = excel[sheetName];

    var count = 0;
    for (final row in rows) {
      final front = row.front.trim();
      final back = row.back.trim();
      if (front.isEmpty || back.isEmpty) continue;

      final tags = row.tags.map((tag) => tag.trim()).where((t) => t.isNotEmpty);
      final tagList = tags.toList();
      sheet.appendRow([
        TextCellValue(front),
        TextCellValue(back),
        if (tagList.isNotEmpty) TextCellValue(tagList.join(' ')),
      ]);
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
