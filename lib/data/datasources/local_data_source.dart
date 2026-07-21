import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';

abstract class LocalDataSource {
  Future<List<LearningSpace>> getAllSpaces();
  Future<LearningSpace?> getSpaceById(String id);
  Future<int> getSpaceCount();
  Future<LearningSpace> addSpace(LearningSpace space);
  Future<LearningSpace> updateSpace(LearningSpace space);
  Future<void> deleteSpace(String id);

  Future<List<Deck>> getAllDecks();
  Future<List<Deck>> getDecksBySpaceId(String spaceId);
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
