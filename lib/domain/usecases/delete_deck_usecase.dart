import 'package:recall/domain/repositories/deck_repository.dart';

class DeleteDeckUseCase {
  DeleteDeckUseCase(this._repository);

  final IDeckRepository _repository;

  Future<void> call(String id) => _repository.deleteDeck(id);
}
