import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';

class GetExcelImportsUseCase {
  GetExcelImportsUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<List<ExcelImport>> call(String spaceId) =>
      _repository.getImportsBySpaceId(spaceId);
}

class GetExcelImportUseCase {
  GetExcelImportUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<ExcelImport?> call(String id) => _repository.getImportById(id);
}
