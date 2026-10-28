import 'package:recall/domain/repositories/excel_import_repository.dart';

class DeleteExcelImportUseCase {
  DeleteExcelImportUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<void> call(String id) => _repository.deleteImport(id);

  /// Removes several files at once, returning how many were actually deleted.
  ///
  /// Ids that no longer exist are ignored rather than failing the whole batch,
  /// so a selection made before a refresh cannot leave files behind.
  Future<int> callMany(Iterable<String> ids) async {
    final unique = ids.toSet();
    if (unique.isEmpty) return 0;

    var deleted = 0;
    for (final id in unique) {
      final existing = await _repository.getImportById(id);
      if (existing == null) continue;
      await _repository.deleteImport(id);
      deleted++;
    }
    return deleted;
  }
}