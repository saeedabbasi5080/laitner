import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/repositories/deck_repository.dart';

class AddDeckUseCase {
  AddDeckUseCase(this._repository);

  final IDeckRepository _repository;

  Future<Deck> call(Deck deck) => _repository.addDeck(deck);
}
