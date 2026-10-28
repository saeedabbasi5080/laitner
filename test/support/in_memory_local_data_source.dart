import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';

/// In-memory [LocalDataSource] for tests.
///
/// Keeps the same semantics as the real sources — notably that log ids are
/// unique and upsert on conflict — so tests exercise the production
/// repository code instead of a parallel implementation.
class InMemoryLocalDataSource implements LocalDataSource {
  InMemoryLocalDataSource({
    List<LearningSpace>? spaces,
    List<Deck>? decks,
    List<Flashcard>? cards,
    List<ReviewLog>? reviewLogs,
  })  : spaces = List.of(spaces ?? const []),
        decks = List.of(decks ?? const []),
        cards = List.of(cards ?? const []),
        reviewLogs = List.of(reviewLogs ?? const []);

  List<LearningSpace> spaces;
  List<Deck> decks;
  List<Flashcard> cards;
  List<ReviewLog> reviewLogs;

  @override
  Future<LearningSpace> addSpace(LearningSpace space) async {
    spaces.add(space);
    return space;
  }

  @override
  Future<Deck> addDeck(Deck deck) async {
    decks.add(deck);
    return deck;
  }

  @override
  Future<Flashcard> addCard(Flashcard card) async {
    cards.add(card);
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {
    cards.removeWhere((card) => card.id == id);
  }

  @override
  Future<void> deleteDeck(String id) async {
    decks.removeWhere((deck) => deck.id == id);
    cards.removeWhere((card) => card.deckId == id);
  }

  @override
  Future<void> deleteSpace(String id) async {
    final deckIds = decks
        .where((deck) => deck.spaceId == id)
        .map((deck) => deck.id)
        .toSet();
    spaces.removeWhere((space) => space.id == id);
    for (final deckId in deckIds) {
      await deleteDeck(deckId);
    }
    await deleteReviewLogsBySpaceId(id);
  }

  @override
  Future<List<Flashcard>> getAllCards() async => List.of(cards);

  @override
  Future<List<Deck>> getAllDecks() async => List.of(decks);

  @override
  Future<List<LearningSpace>> getAllSpaces() async => List.of(spaces);

  @override
  Future<Flashcard?> getCardById(String id) async =>
      cards.where((card) => card.id == id).firstOrNull;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((card) => card.deckId == deckId).toList();

  @override
  Future<Deck?> getDeckById(String id) async =>
      decks.where((deck) => deck.id == id).firstOrNull;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async =>
      decks.where((deck) => deck.spaceId == spaceId).toList();

  @override
  Future<LearningSpace?> getSpaceById(String id) async =>
      spaces.where((space) => space.id == id).firstOrNull;

  @override
  Future<int> getSpaceCount() async => spaces.length;

  @override
  Future<List<ReviewLog>> getAllReviewLogs() async =>
      _sorted(reviewLogs.where((log) => true));

  @override
  Future<List<ReviewLog>> getReviewLogsBySpaceId(String spaceId) async =>
      _sorted(reviewLogs.where((log) => log.spaceId == spaceId));

  @override
  Future<int> countReviewLogsBySpaceId(String spaceId) async =>
      reviewLogs.where((log) => log.spaceId == spaceId).length;

  @override
  Future<List<ReviewLog>> getReviewLogsInRange({
    required String spaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _sorted(
      reviewLogs.where(
        (log) =>
            log.spaceId == spaceId &&
            !log.reviewedAt.isBefore(from) &&
            log.reviewedAt.isBefore(to),
      ),
    );
  }

  @override
  Future<ReviewLog> addReviewLog(ReviewLog log) async {
    final index = reviewLogs.indexWhere((item) => item.id == log.id);
    if (index >= 0) {
      reviewLogs[index] = log;
    } else {
      reviewLogs.add(log);
    }
    return log;
  }

  @override
  Future<void> deleteReviewLogsBySpaceId(String spaceId) async {
    reviewLogs.removeWhere((log) => log.spaceId == spaceId);
  }

  @override
  Future<void> replaceReviewLogs(List<ReviewLog> logs) async {
    reviewLogs
      ..clear()
      ..addAll(logs);
  }

  @override
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
    required List<ReviewLog> reviewLogs,
  }) async {
    this.spaces
      ..clear()
      ..addAll(spaces);
    this.decks
      ..clear()
      ..addAll(decks);
    this.cards
      ..clear()
      ..addAll(cards);
    this.reviewLogs
      ..clear()
      ..addAll(reviewLogs);
  }

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    final index = cards.indexWhere((item) => item.id == card.id);
    if (index >= 0) cards[index] = card;
    return card;
  }

  @override
  Future<Deck> updateDeck(Deck deck) async {
    final index = decks.indexWhere((item) => item.id == deck.id);
    if (index >= 0) decks[index] = deck;
    return deck;
  }

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) async {
    final index = spaces.indexWhere((item) => item.id == space.id);
    if (index >= 0) spaces[index] = space;
    return space;
  }

  List<ReviewLog> _sorted(Iterable<ReviewLog> logs) =>
      logs.toList()..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
}