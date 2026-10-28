import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';

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

  Future<List<ReviewLog>> getAllReviewLogs();

  Future<List<ReviewLog>> getReviewLogsBySpaceId(String spaceId);

  Future<int> countReviewLogsBySpaceId(String spaceId);

  /// Reviews for [spaceId] with `reviewedAt` in `[from, to)`.
  ///
  /// The statistics screen asks for a window instead of the whole history, so
  /// long-lived collections do not have to be decoded on every open.
  Future<List<ReviewLog>> getReviewLogsInRange({
    required String spaceId,
    required DateTime from,
    required DateTime to,
  });

  Future<ReviewLog> addReviewLog(ReviewLog log);

  Future<void> deleteReviewLogsBySpaceId(String spaceId);

  Future<void> replaceReviewLogs(List<ReviewLog> logs);

  /// Wipes and rewrites the whole collection, review history included.
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
    required List<ReviewLog> reviewLogs,
  });
}
