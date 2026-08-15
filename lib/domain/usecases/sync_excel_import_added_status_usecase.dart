import 'package:recall/domain/entities/duplicate_card.dart';
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

  /// Keeps Excel rows in sync with live cards: a row is added only while the
  /// same front text still exists. Editing or deleting the card returns the
  /// row to pending.
  Future<ExcelImport> call(ExcelImport import) async {
    final cards = await _flashcardRepository.getCardsBySpaceId(import.spaceId);
    final cardKeys = cards.map((c) => normalizeCardFront(c.front)).toSet();

    var changed = false;
    final now = DateTime.now();
    final updatedRows = import.rows.map((row) {
      final exists = cardKeys.contains(normalizeCardFront(row.front));
      if (exists && !row.isAdded) {
        changed = true;
        return row.copyWith(isAdded: true, addedAt: now);
      }
      if (!exists && row.isAdded) {
        changed = true;
        return row.copyWith(isAdded: false, clearAddedAt: true);
      }
      return row;
    }).toList();

    if (!changed) return import;

    final updated = import.copyWith(rows: updatedRows);
    await _excelRepository.updateImport(updated);
    return updated;
  }
}
