import 'package:recall/domain/repositories/excel_import_repository.dart';

class DeleteExcelImportUseCase {
  DeleteExcelImportUseCase(this._repository);

  final IExcelImportRepository _repository;

  Future<void> call(String id) => _repository.deleteImport(id);
}
