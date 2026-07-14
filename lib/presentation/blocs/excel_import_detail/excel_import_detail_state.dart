part of 'excel_import_detail_cubit.dart';

enum ExcelImportDetailStatus { initial, loading, loaded, error }

class ExcelImportDetailState extends Equatable {
  const ExcelImportDetailState({
    this.status = ExcelImportDetailStatus.initial,
    this.import,
    this.decks = const [],
    this.selectedDeckId,
    this.selectedRowIds = const {},
    this.pendingOnly = false,
    this.errorMessage,
  });

  final ExcelImportDetailStatus status;
  final ExcelImport? import;
  final List<Deck> decks;
  final String? selectedDeckId;
  final Set<String> selectedRowIds;
  final bool pendingOnly;
  final String? errorMessage;

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
