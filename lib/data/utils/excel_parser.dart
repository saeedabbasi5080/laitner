import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:excel2003/excel2003.dart';

class ExcelParseException implements Exception {
  ExcelParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExcelParser {
  /// Column A = front, Column B = back. Skips empty rows.
  static List<({String front, String back})> parseRows(
    Uint8List bytes, {
    String? fileName,
  }) {
    if (bytes.isEmpty) {
      throw ExcelParseException('فایل خالی است');
    }

    if (_isLegacyXls(bytes, fileName)) {
      return _parseXls(bytes);
    }

    return _parseXlsx(bytes);
  }

  static bool _isLegacyXls(Uint8List bytes, String? fileName) {
    if (fileName != null && fileName.toLowerCase().endsWith('.xls')) {
      return true;
    }
    // OLE2 compound document header (Excel 97-2003 .xls)
    if (bytes.length >= 4 &&
        bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      return true;
    }
    return false;
  }

  static List<({String front, String back})> _parseXls(Uint8List bytes) {
    try {
      final reader = XlsReader.fromBytes(bytes);
      reader.open();

      if (reader.sheetCount == 0) return [];

      final sheet = reader.sheet(0);
      final rows = <({String front, String back})>[];

      for (var r = sheet.firstRow; r < sheet.lastRow; r++) {
        final front = _formatCell(sheet.cell(r, 0));
        final back = _formatCell(sheet.cell(r, 1));
        if (front.isEmpty || back.isEmpty) continue;
        rows.add((front: front, back: back));
      }

      return rows;
    } catch (e) {
      throw ExcelParseException('خواندن فایل xls ناموفق بود: $e');
    }
  }

  static List<({String front, String back})> _parseXlsx(Uint8List bytes) {
    try {
      final excel = Excel.decodeBytes(bytes);
      if (excel.tables.isEmpty) return [];

      final sheet = excel.tables.values.first;
      final rows = <({String front, String back})>[];

      for (final row in sheet.rows) {
        if (row.isEmpty) continue;
        final front = _xlsxCellText(row, 0);
        final back = _xlsxCellText(row, 1);
        if (front.isEmpty || back.isEmpty) continue;
        rows.add((front: front, back: back));
      }

      return rows;
    } catch (e) {
      throw ExcelParseException('خواندن فایل xlsx ناموفق بود: $e');
    }
  }

  static String _xlsxCellText(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return '';
    return _formatCell(row[index]!.value);
  }

  static String _formatCell(dynamic value) {
    if (value == null) return '';
    if (value is TextCellValue) {
      return value.value.text?.trim() ?? value.toString().trim();
    }
    if (value is IntCellValue) return value.value.toString();
    if (value is DoubleCellValue) return value.value.toString();
    if (value is BoolCellValue) return value.value.toString();
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toString().trim();
    }
    if (value is DateTime) {
      return value.toString().trim();
    }
    return value.toString().trim();
  }
}
