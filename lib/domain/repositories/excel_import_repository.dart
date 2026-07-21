import 'package:recall/domain/entities/excel_import.dart';

abstract class IExcelImportRepository {
  Future<List<ExcelImport>> getAllImports();

  Future<List<ExcelImport>> getImportsBySpaceId(String spaceId);

  Future<ExcelImport?> getImportById(String id);

  Future<ExcelImport> saveImport(ExcelImport import);

  Future<ExcelImport> updateImport(ExcelImport import);

  Future<void> deleteImport(String id);
}
