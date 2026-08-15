import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';

class UpdateExcelRowUseCase {
  UpdateExcelRowUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<ExcelImport?> call({
    required String importId,
    required String rowId,
    required String front,
    required String back,
  }) async {
    final import = await _repository.getImportById(importId);
    if (import == null) return null;

    final trimmedFront = front.trim();
    final trimmedBack = back.trim();
    if (trimmedFront.isEmpty || trimmedBack.isEmpty) return import;

    final rows = import.rows.map((row) {
      if (row.id != rowId) return row;
      return row.copyWith(
        front: trimmedFront,
        back: trimmedBack,
        isAdded: false,
        clearAddedAt: true,
      );
    }).toList();

    final updated = import.copyWith(rows: rows);
    await _repository.updateImport(updated);
    return updated;
  }
}
