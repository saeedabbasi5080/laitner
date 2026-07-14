import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/repositories/deck_repository.dart';

class UpdateDeckUseCase {
  UpdateDeckUseCase(this._repository);

  final IDeckRepository _repository;

  Future<Deck> call(Deck deck) => _repository.updateDeck(deck);
}
