import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/excel_duplicate.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

/// Outcome of adding the selected rows of one Excel file to a deck.
class ExcelImportAddResult {
  const ExcelImportAddResult({
    required this.addedCount,
    this.addedDuplicateCount = 0,
  });

  final int addedCount;

  /// How many of the added rows were already flagged as duplicates.
  ///
  /// Duplicates are never withheld — the UI warns about them beforehand and the
  /// user stays in control — but reporting the count means nobody is surprised
  /// later by two identical cards.
  final int addedDuplicateCount;

  bool get hasAddedDuplicates => addedDuplicateCount > 0;
}

class AddSelectedExcelRowsUseCase {
  AddSelectedExcelRowsUseCase(
    this._excelRepository,
    this._flashcardRepository,
    this._deckRepository, [
    this._analysis = const ExcelDuplicateAnalysis(),
  ]);

  final IExcelImportRepository _excelRepository;
  final IFlashcardRepository _flashcardRepository;
  final IDeckRepository _deckRepository;
  final ExcelDuplicateAnalysis _analysis;

  Future<ExcelImportAddResult> call({
    required String importId,
    required String deckId,
    required List<String> rowIds,
    required String Function() generateId,
  }) async {
    final import = await _excelRepository.getImportById(importId);
    if (import == null || rowIds.isEmpty) {
      return const ExcelImportAddResult(addedCount: 0);
    }

    // Duplicates are resolved before anything is written, so the count refers
    // to the state the user saw and approved.
    final duplicateRowIds = await _duplicateRowIds(import);

    final selected = rowIds.toSet();
    final now = DateTime.now();
    var added = 0;
    var addedDuplicates = 0;
    final updatedRows = <ExcelImportRow>[];

    for (final row in import.rows) {
      if (!selected.contains(row.id) || row.isAdded) {
        updatedRows.add(row);
        continue;
      }

      await _flashcardRepository.addCard(
        Flashcard(
          id: generateId(),
          deckId: deckId,
          front: row.front.trim(),
          back: row.back.trim(),
          tags: row.tags,
          box: 1,
          createdAt: now,
        ),
      );
      updatedRows.add(row.copyWith(isAdded: true, addedAt: now));
      added++;
      if (duplicateRowIds.contains(row.id)) addedDuplicates++;
    }

    await _excelRepository.updateImport(import.copyWith(rows: updatedRows));
    return ExcelImportAddResult(
      addedCount: added,
      addedDuplicateCount: addedDuplicates,
    );
  }

  /// Rows that clash with a card in this space, or with an earlier row in the
  /// same file.
  Future<Set<String>> _duplicateRowIds(ExcelImport import) async {
    final cards = await _flashcardRepository.getCardsBySpaceId(import.spaceId);
    final decks = await _deckRepository.getDecksBySpaceId(import.spaceId);
    final deckNames = {for (final deck in decks) deck.id: deck.name};

    return {
      for (final duplicate in _analysis.findDuplicates(
        import: import,
        existingCards: [
          for (final card in cards)
            DuplicateCardMatch(
              card: card,
              deckName: deckNames[card.deckId] ?? card.deckId,
            ),
        ],
        deckNames: deckNames,
      ))
        duplicate.rowId,
    };
  }
}