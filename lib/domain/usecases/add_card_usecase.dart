import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class AddCardUseCase {
  AddCardUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<Flashcard> call(Flashcard card) => _repository.addCard(card);
}
