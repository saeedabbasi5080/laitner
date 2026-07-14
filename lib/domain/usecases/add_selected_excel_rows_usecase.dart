import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class AddSelectedExcelRowsUseCase {
  AddSelectedExcelRowsUseCase(
    this._excelRepository,
    this._flashcardRepository,
  );

  final IExcelImportRepository _excelRepository;
  final IFlashcardRepository _flashcardRepository;

  Future<int> call({
    required String importId,
    required String deckId,
    required List<String> rowIds,
    required String Function() generateId,
  }) async {
    final import = await _excelRepository.getImportById(importId);
    if (import == null || rowIds.isEmpty) return 0;

    final now = DateTime.now();
    var added = 0;
    final updatedRows = <ExcelImportRow>[];

    for (final row in import.rows) {
      if (rowIds.contains(row.id) && !row.isAdded) {
        await _flashcardRepository.addCard(
          Flashcard(
            id: generateId(),
            deckId: deckId,
            front: row.front,
            back: row.back,
            box: 1,
            createdAt: now,
          ),
        );
        updatedRows.add(row.copyWith(isAdded: true, addedAt: now));
        added++;
      } else {
        updatedRows.add(row);
      }
    }

    await _excelRepository.updateImport(import.copyWith(rows: updatedRows));
    return added;
  }
}
