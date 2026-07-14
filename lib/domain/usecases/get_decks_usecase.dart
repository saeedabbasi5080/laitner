import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/repositories/deck_repository.dart';

class GetDecksUseCase {
  GetDecksUseCase(this._repository);

  final IDeckRepository _repository;

  Future<List<Deck>> call() => _repository.getAllDecks();
}
