part of 'excel_import_detail_cubit.dart';

enum ExcelImportDetailStatus { initial, loading, loaded, error }

class ExcelImportDetailState extends Equatable {
  const ExcelImportDetailState({
    this.status = ExcelImportDetailStatus.initial,
    this.import,
    this.decks = const [],
    this.selectedDeckId,
    this.selectedRowIds = const {},
    this.duplicates = const [],
    this.pendingOnly = false,
    this.errorMessage,
  });

  final ExcelImportDetailStatus status;
  final ExcelImport? import;
  final List<Deck> decks;
  final String? selectedDeckId;
  final Set<String> selectedRowIds;

  /// Pending rows that clash with a card in this space or with an earlier row
  /// in the same file.
  final List<ExcelRowDuplicate> duplicates;

  final bool pendingOnly;
  final String? errorMessage;

  Set<String> get duplicateRowIds =>
      {for (final item in duplicates) item.rowId};

  bool isDuplicate(String rowId) => duplicateRowIds.contains(rowId);

  ExcelRowDuplicate? duplicateFor(String rowId) {
    for (final item in duplicates) {
      if (item.rowId == rowId) return item;
    }
    return null;
  }

  List<ExcelImportRow> get visibleRows {
    final import = this.import;
    if (import == null) return [];

    final pending = import.pendingRows;
    final added = import.rows.where((r) => r.isAdded).toList();

    if (pendingOnly) return pending;
    return [...pending, ...added];
  }

  int get selectedPendingCount {
    final import = this.import;
    if (import == null) return 0;
    return selectedRowIds
        .where((id) {
          final row = import.rows.where((r) => r.id == id).firstOrNull;
          return row != null && !row.isAdded;
        })
        .length;
  }

  ExcelImportDetailState copyWith({
    ExcelImportDetailStatus? status,
    ExcelImport? import,
    List<Deck>? decks,
    String? selectedDeckId,
    Set<String>? selectedRowIds,
    List<ExcelRowDuplicate>? duplicates,
    bool? pendingOnly,
    String? errorMessage,
    bool clearSelectedDeckId = false,
  }) {
    return ExcelImportDetailState(
      status: status ?? this.status,
      import: import ?? this.import,
      decks: decks ?? this.decks,
      selectedDeckId:
          clearSelectedDeckId ? null : (selectedDeckId ?? this.selectedDeckId),
      selectedRowIds: selectedRowIds ?? this.selectedRowIds,
      duplicates: duplicates ?? this.duplicates,
      pendingOnly: pendingOnly ?? this.pendingOnly,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        import,
        decks,
        selectedDeckId,
        selectedRowIds,
        duplicates,
        pendingOnly,
        errorMessage,
      ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
