import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class FindDuplicateCardUseCase {
  FindDuplicateCardUseCase(this._flashcardRepository, this._deckRepository);

  final IFlashcardRepository _flashcardRepository;
  final IDeckRepository _deckRepository;

  /// جست‌وجوی کارت تکراری بر اساس فیلد اول (روی کارت) در همهٔ دسته‌ها.
  Future<DuplicateCardMatch?> call(
    String spaceId,
    String front, {
    String? excludeCardId,
  }) async {
    final needle = normalizeCardFront(front);
    if (needle.isEmpty) return null;

    final cards = await _flashcardRepository.getCardsBySpaceId(spaceId);
    Flashcard? existing;
    for (final card in cards) {
      if (excludeCardId != null && card.id == excludeCardId) continue;
      if (normalizeCardFront(card.front) == needle) {
        existing = card;
        break;
      }
    }
    if (existing == null) return null;

    final deck = await _deckRepository.getDeckById(existing.deckId);
    return DuplicateCardMatch(
      card: existing,
      deckName: deck?.name ?? existing.deckId,
    );
  }
}
