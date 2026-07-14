import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class GetCardsByDeckUseCase {
  GetCardsByDeckUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<List<Flashcard>> call(String deckId) =>
      _repository.getCardsByDeckId(deckId);
}
