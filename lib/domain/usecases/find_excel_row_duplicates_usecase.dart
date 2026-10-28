import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/excel_duplicate.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

/// Answers "which pending rows in this file cannot be added, and why".
///
/// The space's cards are loaded once per call rather than per row, so a
/// thousand-word spreadsheet costs a single query.
class FindExcelRowDuplicatesUseCase {
  FindExcelRowDuplicatesUseCase(
    this._flashcardRepository,
    this._deckRepository, [
    this._analysis = const ExcelDuplicateAnalysis(),
  ]);

  final IFlashcardRepository _flashcardRepository;
  final IDeckRepository _deckRepository;
  final ExcelDuplicateAnalysis _analysis;

  Future<List<ExcelRowDuplicate>> call(ExcelImport import) async {
    final cards = await _flashcardRepository.getCardsBySpaceId(import.spaceId);
    if (cards.isEmpty) {
      return _analysis.findDuplicates(
        import: import,
        existingCards: const [],
        deckNames: const {},
      );
    }

    final deckIds = cards.map((card) => card.deckId).toSet();
    final decks = await _deckRepository.getDecksBySpaceId(import.spaceId);
    final deckNames = {
      for (final deck in decks)
        if (deckIds.contains(deck.id)) deck.id: deck.name,
    };

    return _analysis.findDuplicates(
      import: import,
      existingCards: [
        for (final card in cards)
          DuplicateCardMatch(
            card: card,
            deckName: deckNames[card.deckId] ?? card.deckId,
          ),
      ],
      deckNames: deckNames,
    );
  }
}