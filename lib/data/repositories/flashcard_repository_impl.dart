import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';

class FlashcardRepositoryImpl implements IFlashcardRepository {
  FlashcardRepositoryImpl(this._localDataSource);

  final LocalDataSource _localDataSource;

  @override
  Future<List<Flashcard>> getAllCards() => _localDataSource.getAllCards();

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async {
    final decks = await _localDataSource.getDecksBySpaceId(spaceId);
    if (decks.isEmpty) return const [];

    final deckIds = decks.map((deck) => deck.id).toSet();
    final cards = await _localDataSource.getAllCards();
    return cards.where((card) => deckIds.contains(card.deckId)).toList();
  }

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) =>
      _localDataSource.getCardsByDeckId(deckId);

  @override
  Future<Flashcard?> getCardById(String id) =>
      _localDataSource.getCardById(id);

  @override
  Future<Flashcard> addCard(Flashcard card) =>
      _localDataSource.addCard(card);

  @override
  Future<Flashcard> updateCard(Flashcard card) =>
      _localDataSource.updateCard(card);

  @override
  Future<void> deleteCard(String id) => _localDataSource.deleteCard(id);
}
