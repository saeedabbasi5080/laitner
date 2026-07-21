import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class ExcelDuplicateItem {
  const ExcelDuplicateItem({
    required this.rowId,
    required this.front,
    required this.existingDeckName,
  });

  final String rowId;
  final String front;
  final String existingDeckName;
}

class ExcelImportAddResult {
  const ExcelImportAddResult({
    required this.addedCount,
    required this.duplicates,
  });

  final int addedCount;
  final List<ExcelDuplicateItem> duplicates;

  int get skippedDuplicates => duplicates.length;
  int get totalProcessed => addedCount + skippedDuplicates;
}

class AddSelectedExcelRowsUseCase {
  AddSelectedExcelRowsUseCase(
    this._excelRepository,
    this._flashcardRepository,
    this._deckRepository,
  );

  final IExcelImportRepository _excelRepository;
  final IFlashcardRepository _flashcardRepository;
  final IDeckRepository _deckRepository;

  Future<ExcelImportAddResult> call({
    required String importId,
    required String deckId,
    required List<String> rowIds,
    required String Function() generateId,
  }) async {
    final import = await _excelRepository.getImportById(importId);
    if (import == null || rowIds.isEmpty) {
      return const ExcelImportAddResult(addedCount: 0, duplicates: []);
    }

    final existingCards =
        await _flashcardRepository.getCardsBySpaceId(import.spaceId);
    final decks = await _deckRepository.getDecksBySpaceId(import.spaceId);
    final deckNames = {for (final deck in decks) deck.id: deck.name};
    final existingByFront = <String, Flashcard>{};
    for (final card in existingCards) {
      existingByFront.putIfAbsent(normalizeCardFront(card.front), () => card);
    }

    final now = DateTime.now();
    var added = 0;
    final duplicates = <ExcelDuplicateItem>[];
    final updatedRows = <ExcelImportRow>[];

    for (final row in import.rows) {
      if (rowIds.contains(row.id) && !row.isAdded) {
        final key = normalizeCardFront(row.front);
        final existing = existingByFront[key];
        if (existing != null) {
          duplicates.add(
            ExcelDuplicateItem(
              rowId: row.id,
              front: row.front.trim(),
              existingDeckName: deckNames[existing.deckId] ?? existing.deckId,
            ),
          );
          updatedRows.add(row.copyWith(isAdded: true, addedAt: now));
          continue;
        }

        final card = Flashcard(
          id: generateId(),
          deckId: deckId,
          front: row.front.trim(),
          back: row.back.trim(),
          box: 1,
          createdAt: now,
        );
        await _flashcardRepository.addCard(card);
        existingByFront[key] = card;
        updatedRows.add(row.copyWith(isAdded: true, addedAt: now));
        added++;
      } else {
        updatedRows.add(row);
      }
    }

    await _excelRepository.updateImport(import.copyWith(rows: updatedRows));
    return ExcelImportAddResult(addedCount: added, duplicates: duplicates);
  }
}
