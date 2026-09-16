import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class MoveCardsToDeckUseCase {
  MoveCardsToDeckUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<int> call({
    required List<String> cardIds,
    required String targetDeckId,
  }) async {
    var moved = 0;
    for (final id in cardIds) {
      final card = await _repository.getCardById(id);
      if (card == null || card.deckId == targetDeckId) continue;
      await _repository.updateCard(card.copyWith(deckId: targetDeckId));
      moved++;
    }
    return moved;
  }
}
