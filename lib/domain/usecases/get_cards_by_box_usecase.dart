import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class GetCardsByBoxUseCase {
  GetCardsByBoxUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<List<Flashcard>> call(int box, {String? deckId, String? spaceId}) async {
    final cards = deckId != null
        ? await _repository.getCardsByDeckId(deckId)
        : spaceId != null
            ? await _repository.getCardsBySpaceId(spaceId)
            : await _repository.getAllCards();
    return cards.where((c) => c.box == box).toList();
  }
}
