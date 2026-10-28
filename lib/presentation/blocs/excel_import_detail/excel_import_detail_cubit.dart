import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/excel_duplicate.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/delete_excel_import_usecase.dart';
import 'package:recall/domain/usecases/find_excel_row_duplicates_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/remove_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/sync_excel_import_added_status_usecase.dart';
import 'package:recall/domain/usecases/update_excel_row_usecase.dart';

part 'excel_import_detail_state.dart';

class ExcelImportDetailCubit extends Cubit<ExcelImportDetailState> {
  ExcelImportDetailCubit({
    required String importId,
    required String spaceId,
    String? initialDeckId,
    required GetExcelImportUseCase getImportUseCase,
    required GetDecksUseCase getDecksUseCase,
    required AddSelectedExcelRowsUseCase addSelectedRowsUseCase,
    required AddDeckUseCase addDeckUseCase,
    required SyncExcelImportAddedStatusUseCase syncAddedStatusUseCase,
    required RemoveExcelRowsUseCase removeExcelRowsUseCase,
    required UpdateExcelRowUseCase updateExcelRowUseCase,
    required DeleteExcelImportUseCase deleteImportUseCase,
    required FindExcelRowDuplicatesUseCase findDuplicatesUseCase,
    required IdGenerator idGenerator,
  }) : _importId = importId,
       _spaceId = spaceId,
       _getImportUseCase = getImportUseCase,
       _getDecksUseCase = getDecksUseCase,
       _addSelectedRowsUseCase = addSelectedRowsUseCase,
       _addDeckUseCase = addDeckUseCase,
       _syncAddedStatusUseCase = syncAddedStatusUseCase,
       _removeExcelRowsUseCase = removeExcelRowsUseCase,
       _updateExcelRowUseCase = updateExcelRowUseCase,
       _deleteImportUseCase = deleteImportUseCase,
       _findDuplicatesUseCase = findDuplicatesUseCase,
       _idGenerator = idGenerator,
       super(ExcelImportDetailState(selectedDeckId: initialDeckId));

  final String _importId;
  final String _spaceId;
  final GetExcelImportUseCase _getImportUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final AddSelectedExcelRowsUseCase _addSelectedRowsUseCase;
  final AddDeckUseCase _addDeckUseCase;
  final SyncExcelImportAddedStatusUseCase _syncAddedStatusUseCase;
  final RemoveExcelRowsUseCase _removeExcelRowsUseCase;
  final UpdateExcelRowUseCase _updateExcelRowUseCase;
  final DeleteExcelImportUseCase _deleteImportUseCase;
  final FindExcelRowDuplicatesUseCase _findDuplicatesUseCase;
  final IdGenerator _idGenerator;

  Future<void> load() async {
    emit(state.copyWith(status: ExcelImportDetailStatus.loading));
    try {
      final import = await _getImportUseCase(_importId);
      if (import == null) {
        emit(state.copyWith(status: ExcelImportDetailStatus.error));
        return;
      }
      final syncedImport = await _syncAddedStatusUseCase(import);
      final duplicates = await _findDuplicatesUseCase(syncedImport);
      final decks = await _getDecksUseCase(_spaceId);
      emit(
        state.copyWith(
          status: ExcelImportDetailStatus.loaded,
          import: syncedImport,
          duplicates: duplicates,
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
    // Duplicates are included on purpose: the row list already warns about
    // them, and deciding what to keep is the user's call.
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
      return const ExcelImportAddResult(addedCount: 0);
    }

    final pendingSelected = state.selectedRowIds.where((id) {
      final row = state.import?.rows.where((r) => r.id == id).firstOrNull;
      return row != null && !row.isAdded;
    }).toList();

    if (pendingSelected.isEmpty) {
      return const ExcelImportAddResult(addedCount: 0);
    }

    final result = await _addSelectedRowsUseCase(
      importId: _importId,
      deckId: deckId,
      rowIds: pendingSelected,
      generateId: _idGenerator.generateId,
    );

    await _refreshAfterMutation();
    return result;
  }

  /// Deletes every duplicate row from the file, so what is left is exactly
  /// what can actually be added.
  Future<int> removeDuplicateRows() async {
    final duplicates = state.duplicates;
    if (duplicates.isEmpty) return 0;

    final removed = await _removeExcelRowsUseCase(
      importId: _importId,
      rowIds: [for (final item in duplicates) item.rowId],
    );
    if (removed > 0) await _refreshAfterMutation();
    return removed;
  }

  Future<void> _refreshAfterMutation() async {
    final import = await _getImportUseCase(_importId);
    if (import == null) return;
    final duplicates = await _findDuplicatesUseCase(import);
    emit(
      state.copyWith(
        import: import,
        duplicates: duplicates,
        selectedRowIds: state.selectedRowIds,
      ),
    );
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
      final duplicates = import != null
          ? await _findDuplicatesUseCase(import)
          : state.duplicates;
      final remaining = Set<String>.from(state.selectedRowIds)
        ..removeAll(rowIds);
      emit(
        state.copyWith(
          import: import,
          duplicates: duplicates,
          selectedRowIds: remaining,
        ),
      );
    }
    return removed;
  }

  Future<void> updateRow({
    required String rowId,
    required String front,
    required String back,
  }) async {
    final updated = await _updateExcelRowUseCase(
      importId: _importId,
      rowId: rowId,
      front: front,
      back: back,
    );
    if (updated == null) return;
    final synced = await _syncAddedStatusUseCase(updated);
    // Editing a front can clear or create a duplicate, so re-check.
    final duplicates = await _findDuplicatesUseCase(synced);
    emit(
      state.copyWith(
        import: synced,
        duplicates: duplicates,
        selectedRowIds: state.selectedRowIds,
      ),
    );
  }

  Future<Deck> createDeck(String name, DeckColor color) async {
    final deck = Deck(
      id: _idGenerator.generateId(),
      spaceId: _spaceId,
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );
    final saved = await _addDeckUseCase(deck);
    final decks = await _getDecksUseCase(_spaceId);
    emit(state.copyWith(decks: decks, selectedDeckId: saved.id));
    return saved;
  }
}
