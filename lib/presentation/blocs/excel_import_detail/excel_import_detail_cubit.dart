import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/delete_excel_import_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/remove_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/sync_excel_import_added_status_usecase.dart';

part 'excel_import_detail_state.dart';

class ExcelImportDetailCubit extends Cubit<ExcelImportDetailState> {
  ExcelImportDetailCubit({
    required String importId,
    String? initialDeckId,
    required GetExcelImportUseCase getImportUseCase,
    required GetDecksUseCase getDecksUseCase,
    required AddSelectedExcelRowsUseCase addSelectedRowsUseCase,
    required SyncExcelImportAddedStatusUseCase syncAddedStatusUseCase,
    required RemoveExcelRowsUseCase removeExcelRowsUseCase,
    required DeleteExcelImportUseCase deleteImportUseCase,
    required LocalDataSource localDataSource,
  }) : _importId = importId,
       _getImportUseCase = getImportUseCase,
       _getDecksUseCase = getDecksUseCase,
       _addSelectedRowsUseCase = addSelectedRowsUseCase,
       _syncAddedStatusUseCase = syncAddedStatusUseCase,
       _removeExcelRowsUseCase = removeExcelRowsUseCase,
       _deleteImportUseCase = deleteImportUseCase,
       _localDataSource = localDataSource,
       super(ExcelImportDetailState(selectedDeckId: initialDeckId));

  final String _importId;
  final GetExcelImportUseCase _getImportUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final AddSelectedExcelRowsUseCase _addSelectedRowsUseCase;
  final SyncExcelImportAddedStatusUseCase _syncAddedStatusUseCase;
  final RemoveExcelRowsUseCase _removeExcelRowsUseCase;
  final DeleteExcelImportUseCase _deleteImportUseCase;
  final LocalDataSource _localDataSource;

  Future<void> load() async {
    emit(state.copyWith(status: ExcelImportDetailStatus.loading));
    try {
      final import = await _getImportUseCase(_importId);
      if (import == null) {
        emit(state.copyWith(status: ExcelImportDetailStatus.error));
        return;
      }
      final syncedImport = await _syncAddedStatusUseCase(import);
      final decks = await _getDecksUseCase();
      emit(
        state.copyWith(
          status: ExcelImportDetailStatus.loaded,
          import: syncedImport,
          decks: decks,
          selectedDeckId:
              state.selectedDeckId ??
              (decks.isNotEmpty ? decks.first.id : null),
          selectedRowIds: {},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExcelImportDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void selectDeck(String deckId) {
    emit(state.copyWith(selectedDeckId: deckId));
  }

  void toggleRow(String rowId) {
    final row = state.import?.rows.where((r) => r.id == rowId).firstOrNull;
    if (row == null || row.isAdded) return;

    final next = Set<String>.from(state.selectedRowIds);
    if (next.contains(rowId)) {
      next.remove(rowId);
    } else {
      next.add(rowId);
    }
    emit(state.copyWith(selectedRowIds: next));
  }

  void selectAllPending() {
    final import = state.import;
    if (import == null) return;
    final pendingIds = import.pendingRows.map((r) => r.id).toSet();
    emit(state.copyWith(selectedRowIds: pendingIds));
  }

  void clearSelection() {
    emit(state.copyWith(selectedRowIds: {}));
  }

  void togglePendingOnly(bool value) {
    emit(state.copyWith(pendingOnly: value));
  }

  Future<ExcelImportAddResult> addSelectedToDeck() async {
    final deckId = state.selectedDeckId;
    if (deckId == null || state.selectedRowIds.isEmpty) {
      return const ExcelImportAddResult(addedCount: 0, duplicates: []);
    }

    final pendingSelected = state.selectedRowIds.where((id) {
      final row = state.import?.rows.where((r) => r.id == id).firstOrNull;
      return row != null && !row.isAdded;
    }).toList();

    if (pendingSelected.isEmpty) {
      return const ExcelImportAddResult(addedCount: 0, duplicates: []);
    }

    final result = await _addSelectedRowsUseCase(
      importId: _importId,
      deckId: deckId,
      rowIds: pendingSelected,
      generateId: _localDataSource.generateId,
    );

    final import = await _getImportUseCase(_importId);
    final syncedImport = import != null
        ? await _syncAddedStatusUseCase(import)
        : null;
    emit(state.copyWith(import: syncedImport, selectedRowIds: {}));
    return result;
  }

  Future<void> deleteImport() async {
    await _deleteImportUseCase(_importId);
  }

  Future<int> removeRows(Iterable<String> rowIds) async {
    final removed = await _removeExcelRowsUseCase(
      importId: _importId,
      rowIds: rowIds,
    );
    if (removed > 0) {
      final import = await _getImportUseCase(_importId);
      emit(state.copyWith(import: import, selectedRowIds: {}));
    }
    return removed;
  }
}
