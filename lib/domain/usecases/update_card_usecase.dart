import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class UpdateCardUseCase {
  UpdateCardUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<Flashcard> call(Flashcard card) => _repository.updateCard(card);
}
