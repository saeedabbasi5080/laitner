import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

class GetDueCardsUseCase {
  GetDueCardsUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<List<Flashcard>> call(String deckId, {DateTime? now}) async {
    final reference = now ?? DateTime.now();
    final cards = await _repository.getCardsByDeckId(deckId);
    return cards.where((card) => isCardDue(card, reference)).toList();
  }
}
