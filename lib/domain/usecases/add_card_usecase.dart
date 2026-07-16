import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/find_duplicate_card_usecase.dart';

class AddCardUseCase {
  AddCardUseCase(this._repository, this._findDuplicateCardUseCase);

  final IFlashcardRepository _repository;
  final FindDuplicateCardUseCase _findDuplicateCardUseCase;

  Future<Flashcard> call(Flashcard card) async {
    final duplicate = await _findDuplicateCardUseCase(card.front);
    if (duplicate != null) {
      throw DuplicateCardException(
        existingCard: duplicate.card,
        deckName: duplicate.deckName,
      );
    }
    return _repository.addCard(card);
  }
}
