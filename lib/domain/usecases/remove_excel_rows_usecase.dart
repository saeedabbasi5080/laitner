import 'package:recall/domain/repositories/excel_import_repository.dart';

class RemoveExcelRowsUseCase {
  RemoveExcelRowsUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<int> call({
    required String importId,
    required Iterable<String> rowIds,
  }) async {
    final ids = rowIds.toSet();
    if (ids.isEmpty) return 0;

    final import = await _repository.getImportById(importId);
    if (import == null) return 0;

    final remainingRows = import.rows
        .where((row) => !ids.contains(row.id))
        .toList();
    final removedCount = import.rows.length - remainingRows.length;
    if (removedCount == 0) return 0;

    await _repository.updateImport(import.copyWith(rows: remainingRows));
    return removedCount;
  }
}
