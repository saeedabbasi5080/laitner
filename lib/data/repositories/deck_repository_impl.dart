import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/repositories/deck_repository.dart';

class DeckRepositoryImpl implements IDeckRepository {
  DeckRepositoryImpl(this._localDataSource);

  final LocalDataSource _localDataSource;

  @override
  Future<List<Deck>> getAllDecks() => _localDataSource.getAllDecks();

  @override
  Future<Deck?> getDeckById(String id) => _localDataSource.getDeckById(id);

  @override
  Future<Deck> addDeck(Deck deck) => _localDataSource.addDeck(deck);

  @override
  Future<Deck> updateDeck(Deck deck) => _localDataSource.updateDeck(deck);

  @override
  Future<void> deleteDeck(String id) => _localDataSource.deleteDeck(id);
}
