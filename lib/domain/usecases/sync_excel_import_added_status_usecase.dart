import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class SyncExcelImportAddedStatusUseCase {
  SyncExcelImportAddedStatusUseCase(
    this._excelRepository,
    this._flashcardRepository,
  );

  final IExcelImportRepository _excelRepository;
  final IFlashcardRepository _flashcardRepository;

  /// Marks excel rows as added when matching cards already exist in any deck.
  Future<ExcelImport> call(ExcelImport import) async {
    final cards = await _flashcardRepository.getAllCards();
    final cardKeys = cards
        .map((c) => _key(c.front, c.back))
        .toSet();

    var changed = false;
    final now = DateTime.now();
    final updatedRows = import.rows.map((row) {
      if (row.isAdded) return row;
      if (cardKeys.contains(_key(row.front, row.back))) {
        changed = true;
        return row.copyWith(isAdded: true, addedAt: now);
      }
      return row;
    }).toList();

    if (!changed) return import;

    final updated = import.copyWith(rows: updatedRows);
    await _excelRepository.updateImport(updated);
    return updated;
  }

  String _key(String front, String back) =>
      '${front.trim().toLowerCase()}\u0000${back.trim().toLowerCase()}';
}
