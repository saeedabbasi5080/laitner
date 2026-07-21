import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';

class ExcelImportRepositoryImpl implements IExcelImportRepository {
  ExcelImportRepositoryImpl(this._store);

  final ExcelImportStore _store;

  @override
  Future<List<ExcelImport>> getAllImports() => _store.getAll();

  @override
  Future<List<ExcelImport>> getImportsBySpaceId(String spaceId) =>
      _store.getBySpaceId(spaceId);

  @override
  Future<ExcelImport?> getImportById(String id) => _store.getById(id);

  @override
  Future<ExcelImport> saveImport(ExcelImport import) async {
    await _store.save(import);
    return import;
  }

  @override
  Future<ExcelImport> updateImport(ExcelImport import) async {
    await _store.save(import);
    return import;
  }

  @override
  Future<void> deleteImport(String id) => _store.delete(id);
}
