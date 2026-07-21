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

  /// Marks excel rows as added when the front field already exists in any deck.
  Future<ExcelImport> call(ExcelImport import) async {
    final cards = await _flashcardRepository.getCardsBySpaceId(import.spaceId);
    final cardKeys = cards.map((c) => normalizeCardFront(c.front)).toSet();

    var changed = false;
    final now = DateTime.now();
    final updatedRows = import.rows.map((row) {
      if (row.isAdded) return row;
      if (cardKeys.contains(normalizeCardFront(row.front))) {
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
}
