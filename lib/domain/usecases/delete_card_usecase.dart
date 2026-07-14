import 'package:recall/domain/repositories/flashcard_repository.dart';

class DeleteCardUseCase {
  DeleteCardUseCase(this._repository);

  final IFlashcardRepository _repository;

  Future<void> call(String id) => _repository.deleteCard(id);
}
