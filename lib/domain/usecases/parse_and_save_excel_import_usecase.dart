import 'dart:typed_data';

import 'package:recall/data/utils/excel_parser.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';

class ParseAndSaveExcelImportUseCase {
  ParseAndSaveExcelImportUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<ExcelImport?> call({
    required String spaceId,
    required Uint8List bytes,
    required String fileName,
    required String Function() generateId,
  }) async {
    final parsed = ExcelParser.parseRows(bytes, fileName: fileName);
    if (parsed.isEmpty) return null;

    final now = DateTime.now();
    final import = ExcelImport(
      id: generateId(),
      spaceId: spaceId,
      fileName: fileName,
      createdAt: now,
      rows: parsed
          .map(
            (r) => ExcelImportRow(
              id: generateId(),
              front: r.front,
              back: r.back,
            ),
          )
          .toList(),
    );

    return _repository.saveImport(import);
  }
}
