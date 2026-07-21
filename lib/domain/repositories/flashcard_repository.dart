import 'package:recall/domain/entities/flashcard.dart';

abstract class IFlashcardRepository {
  Future<List<Flashcard>> getAllCards();

  Future<List<Flashcard>> getCardsBySpaceId(String spaceId);

  Future<List<Flashcard>> getCardsByDeckId(String deckId);

  Future<Flashcard?> getCardById(String id);

  Future<Flashcard> addCard(Flashcard card);

  Future<Flashcard> updateCard(Flashcard card);

  Future<void> deleteCard(String id);
}
