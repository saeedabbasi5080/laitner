import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';

abstract class LocalDataSource {
  Future<void> seedIfEmpty();

  Future<List<Deck>> getAllDecks();
  Future<Deck?> getDeckById(String id);
  Future<Deck> addDeck(Deck deck);
  Future<Deck> updateDeck(Deck deck);
  Future<void> deleteDeck(String id);

  Future<List<Flashcard>> getAllCards();
  Future<List<Flashcard>> getCardsByDeckId(String deckId);
  Future<Flashcard?> getCardById(String id);
  Future<Flashcard> addCard(Flashcard card);
  Future<Flashcard> updateCard(Flashcard card);
  Future<void> deleteCard(String id);

  String generateId();
}
