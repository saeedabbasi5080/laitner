import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/services/id_generator.dart';
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
    required IdGenerator idGenerator,
  })  : _spaceId = spaceId,
        _getImportsUseCase = getImportsUseCase,
        _parseAndSaveUseCase = parseAndSaveUseCase,
        _deleteImportUseCase = deleteImportUseCase,
        _idGenerator = idGenerator,
        super(const ExcelLibraryState());

  final String _spaceId;
  final GetExcelImportsUseCase _getImportsUseCase;
  final ParseAndSaveExcelImportUseCase _parseAndSaveUseCase;
  final DeleteExcelImportUseCase _deleteImportUseCase;
  final IdGenerator _idGenerator;

  bool isSelected(String id) => state.selectedIds.contains(id);

  /// The list switches to a pick-to-delete mode as soon as one file is picked.
  bool get isSelectionMode => state.selectedIds.isNotEmpty;

  void toggleSelection(String id) {
    final next = Set<String>.from(state.selectedIds);
    if (!next.remove(id)) next.add(id);
    emit(state.copyWith(selectedIds: next));
  }

  void selectAll() {
    emit(
      state.copyWith(
        selectedIds: {for (final item in state.imports) item.id},
      ),
    );
  }

  void clearSelection() {
    if (state.selectedIds.isEmpty) return;
    emit(state.copyWith(selectedIds: const {}));
  }

  /// Deletes every picked file and clears the selection.
  Future<int> deleteSelected() async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty) return 0;

    final deleted = await _deleteImportUseCase.callMany(ids);
    await load();
    return deleted;
  }

  Future<void> load() async {
    emit(state.copyWith(status: ExcelLibraryStatus.loading));
    try {
      final imports = await _getImportsUseCase(_spaceId);
      // A picked file may have been deleted elsewhere; keep only ids that
      // still exist so the selection can never reference a missing file.
      final live = {for (final item in imports) item.id};
      emit(
        state.copyWith(
          status: ExcelLibraryStatus.loaded,
          imports: imports,
          selectedIds: state.selectedIds.intersection(live),
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
      generateId: _idGenerator.generateId,
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

  Future<List<ExcelImport>> importFiles(
    List<({Uint8List bytes, String fileName})> files,
  ) async {
    final saved = <ExcelImport>[];
    for (final file in files) {
      try {
        final import = await _parseAndSaveUseCase(
          spaceId: _spaceId,
          bytes: file.bytes,
          fileName: file.fileName,
          generateId: _idGenerator.generateId,
        );
        if (import != null) saved.add(import);
      } catch (_) {
        continue;
      }
    }
    final imports = await _getImportsUseCase(_spaceId);
    emit(
      state.copyWith(
        status: ExcelLibraryStatus.loaded,
        imports: imports,
      ),
    );
    return saved;
  }

  Future<void> deleteImport(String id) async {
    await _deleteImportUseCase(id);
    await load();
  }
}
