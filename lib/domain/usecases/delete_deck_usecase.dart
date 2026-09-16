import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class DeleteDeckUseCase {
  DeleteDeckUseCase(this._deckRepository, this._flashcardRepository);

  final IDeckRepository _deckRepository;
  final IFlashcardRepository _flashcardRepository;

  /// Deletes [id]. If [transferToDeckId] is set, cards move there first.
  Future<void> call(String id, {String? transferToDeckId}) async {
    if (transferToDeckId != null && transferToDeckId != id) {
      final cards = await _flashcardRepository.getCardsByDeckId(id);
      for (final card in cards) {
        await _flashcardRepository.updateCard(
          card.copyWith(deckId: transferToDeckId),
        );
      }
    }
    await _deckRepository.deleteDeck(id);
  }
}
