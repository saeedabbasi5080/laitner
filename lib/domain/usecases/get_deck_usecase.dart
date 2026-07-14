import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/repositories/deck_repository.dart';

class GetDeckUseCase {
  GetDeckUseCase(this._repository);

  final IDeckRepository _repository;

  Future<Deck?> call(String id) => _repository.getDeckById(id);
}
