import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/usecases/delete_excel_import_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/parse_and_save_excel_import_usecase.dart';

part 'excel_library_state.dart';

class ExcelLibraryCubit extends Cubit<ExcelLibraryState> {
  ExcelLibraryCubit({
    required String spaceId,
    required GetExcelImportsUseCase getImportsUseCase,
    required ParseAndSaveExcelImportUseCase parseAndSaveUseCase,
    required DeleteExcelImportUseCase deleteImportUseCase,
    required LocalDataSource localDataSource,
  })  : _spaceId = spaceId,
        _getImportsUseCase = getImportsUseCase,
        _parseAndSaveUseCase = parseAndSaveUseCase,
        _deleteImportUseCase = deleteImportUseCase,
        _localDataSource = localDataSource,
        super(const ExcelLibraryState());

  final String _spaceId;
  final GetExcelImportsUseCase _getImportsUseCase;
  final ParseAndSaveExcelImportUseCase _parseAndSaveUseCase;
  final DeleteExcelImportUseCase _deleteImportUseCase;
  final LocalDataSource _localDataSource;

  Future<void> load() async {
    emit(state.copyWith(status: ExcelLibraryStatus.loading));
    try {
      final imports = await _getImportsUseCase(_spaceId);
      emit(
        state.copyWith(
          status: ExcelLibraryStatus.loaded,
          imports: imports,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExcelLibraryStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<ExcelImport?> importFile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final import = await _parseAndSaveUseCase(
      spaceId: _spaceId,
      bytes: bytes,
      fileName: fileName,
      generateId: _localDataSource.generateId,
    );
    if (import != null) {
      final imports = await _getImportsUseCase(_spaceId);
      emit(
        state.copyWith(
          status: ExcelLibraryStatus.loaded,
          imports: imports,
        ),
      );
    }
    return import;
  }

  Future<void> deleteImport(String id) async {
    await _deleteImportUseCase(id);
    await load();
  }
}
