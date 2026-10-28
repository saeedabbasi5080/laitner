import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

/// Every card in a space, whatever its due date.
///
/// Distinct from [GetAllDueCardsUseCase] on purpose. A retry run over the cards
/// the user just got wrong needs exactly the cards that are *not* due — failing
/// a card sends it back to the first house, which makes it due tomorrow, so the
/// due-card query returns nothing at all and the retry comes back empty.
class GetSpaceCardsUseCase {
  GetSpaceCardsUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<List<Flashcard>> call(String spaceId) =>
      _repository.getCardsBySpaceId(spaceId);
}