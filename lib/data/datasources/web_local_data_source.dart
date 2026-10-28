import 'dart:convert';

import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web fallback storage using SharedPreferences (Isar does not support web).
///
/// Review history is decoded once and then kept in memory: appending a single
/// review used to re-read and re-encode the entire history array, which made
/// every answered card cost O(history).
class WebLocalDataSource implements LocalDataSource {
  WebLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _spacesKey = 'recall_web_spaces';
  static const _decksKey = 'recall_web_decks';
  static const _cardsKey = 'recall_web_cards';
  static const _reviewLogsKey = 'recall_web_review_logs';

  List<ReviewLog>? _reviewLogCache;

  List<ReviewLog> _loadReviewLogs() {
    final cached = _reviewLogCache;
    if (cached != null) return cached;

    final raw = _prefs.getString(_reviewLogsKey);
    if (raw == null) return _reviewLogCache = [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final logs = list
          .whereType<Map<String, dynamic>>()
          .map(ReviewLog.fromJson)
          .toList()
        ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
      return _reviewLogCache = logs;
    } on FormatException {
      return _reviewLogCache = [];
    } on TypeError {
      return _reviewLogCache = [];
    }
  }

  Future<void> _saveReviewLogs(List<ReviewLog> logs) async {
    _reviewLogCache = logs;
    await _prefs.setString(
      _reviewLogsKey,
      jsonEncode(logs.map((log) => log.toJson()).toList()),
    );
  }

  List<LearningSpace> _loadSpaces() {
    final raw = _prefs.getString(_spacesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _spaceFromJson(e as Map<String, dynamic>))
        .toList();
  }

  List<Deck> _loadDecks() {
    final raw = _prefs.getString(_decksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => _deckFromJson(e as Map<String, dynamic>)).toList();
  }

  List<Flashcard> _loadCards() {
    final raw = _prefs.getString(_cardsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _cardFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveSpaces(List<LearningSpace> spaces) async {
    final json = jsonEncode(spaces.map(_spaceToJson).toList());
    await _prefs.setString(_spacesKey, json);
  }

  Future<void> _saveDecks(List<Deck> decks) async {
    final json = jsonEncode(decks.map(_deckToJson).toList());
    await _prefs.setString(_decksKey, json);
  }

  Future<void> _saveCards(List<Flashcard> cards) async {
    final json = jsonEncode(cards.map(_cardToJson).toList());
    await _prefs.setString(_cardsKey, json);
  }

  Map<String, dynamic> _spaceToJson(LearningSpace space) => {
        'id': space.id,
        'name': space.name,
        'color': space.color.name,
        'createdAt': space.createdAt.toIso8601String(),
        'sortOrder': space.sortOrder,
      };

  LearningSpace _spaceFromJson(Map<String, dynamic> json) => LearningSpace(
        id: json['id'] as String,
        name: json['name'] as String,
        color: DeckColor.fromString(json['color'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  Map<String, dynamic> _deckToJson(Deck deck) => {
        'id': deck.id,
        'spaceId': deck.spaceId,
        'name': deck.name,
        'color': deck.color.name,
        'createdAt': deck.createdAt.toIso8601String(),
      };

  Deck _deckFromJson(Map<String, dynamic> json) => Deck(
        id: json['id'] as String,
        spaceId: json['spaceId'] as String? ?? '',
        name: json['name'] as String,
        color: DeckColor.fromString(json['color'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> _cardToJson(Flashcard card) => card.toJson();

  Flashcard _cardFromJson(Map<String, dynamic> json) => Flashcard.fromJson(json);

  @override
  Future<List<LearningSpace>> getAllSpaces() async {
    final spaces = _loadSpaces()
      ..sort((a, b) {
        final orderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (orderCompare != 0) return orderCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
    return spaces;
  }

  @override
  Future<LearningSpace?> getSpaceById(String id) async =>
      _loadSpaces().where((s) => s.id == id).firstOrNull;

  @override
  Future<int> getSpaceCount() async => _loadSpaces().length;

  @override
  Future<LearningSpace> addSpace(LearningSpace space) async {
    final spaces = _loadSpaces()..add(space);
    await _saveSpaces(spaces);
    return space;
  }

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) async {
    final spaces = _loadSpaces();
    final index = spaces.indexWhere((s) => s.id == space.id);
    if (index >= 0) spaces[index] = space;
    await _saveSpaces(spaces);
    return space;
  }

  @override
  Future<void> deleteSpace(String id) async {
    final decks = _loadDecks().where((d) => d.spaceId == id).toList();
    for (final deck in decks) {
      await deleteDeck(deck.id);
    }
    final spaces = _loadSpaces()..removeWhere((s) => s.id == id);
    await _saveSpaces(spaces);
  }

  @override
  Future<List<Deck>> getAllDecks() async {
    final decks = _loadDecks()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return decks;
  }

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async =>
      _loadDecks()
          .where((d) => d.spaceId == spaceId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Deck?> getDeckById(String id) async {
    return _loadDecks().where((d) => d.id == id).firstOrNull;
  }

  @override
  Future<Deck> addDeck(Deck deck) async {
    final decks = _loadDecks()..add(deck);
    await _saveDecks(decks);
    return deck;
  }

  @override
  Future<Deck> updateDeck(Deck deck) async {
    final decks = _loadDecks();
    final index = decks.indexWhere((d) => d.id == deck.id);
    if (index >= 0) decks[index] = deck;
    await _saveDecks(decks);
    return deck;
  }

  @override
  Future<void> deleteDeck(String id) async {
    final decks = _loadDecks()..removeWhere((d) => d.id == id);
    final cards = _loadCards()..removeWhere((c) => c.deckId == id);
    await _saveDecks(decks);
    await _saveCards(cards);
  }

  @override
  Future<List<Flashcard>> getAllCards() async => _loadCards();

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      _loadCards().where((c) => c.deckId == deckId).toList();

  @override
  Future<Flashcard?> getCardById(String id) async =>
      _loadCards().where((c) => c.id == id).firstOrNull;

  @override
  Future<Flashcard> addCard(Flashcard card) async {
    final cards = _loadCards()..add(card);
    await _saveCards(cards);
    return card;
  }

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    final cards = _loadCards();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index >= 0) cards[index] = card;
    await _saveCards(cards);
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {
    final cards = _loadCards()..removeWhere((c) => c.id == id);
    await _saveCards(cards);
  }

  @override
  Future<List<ReviewLog>> getAllReviewLogs() async =>
      List<ReviewLog>.of(_loadReviewLogs());

  @override
  Future<List<ReviewLog>> getReviewLogsBySpaceId(String spaceId) async =>
      _loadReviewLogs().where((log) => log.spaceId == spaceId).toList();

  @override
  Future<int> countReviewLogsBySpaceId(String spaceId) async =>
      _loadReviewLogs().where((log) => log.spaceId == spaceId).length;

  @override
  Future<List<ReviewLog>> getReviewLogsInRange({
    required String spaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _loadReviewLogs()
        .where(
          (log) =>
              log.spaceId == spaceId &&
              !log.reviewedAt.isBefore(from) &&
              log.reviewedAt.isBefore(to),
        )
        .toList();
  }

  @override
  Future<ReviewLog> addReviewLog(ReviewLog log) async {
    final logs = List<ReviewLog>.of(_loadReviewLogs());
    final index = logs.indexWhere((item) => item.id == log.id);
    if (index >= 0) {
      logs[index] = log;
    } else {
      logs.add(log);
    }
    await _saveReviewLogs(logs);
    return log;
  }

  @override
  Future<void> deleteReviewLogsBySpaceId(String spaceId) async {
    final logs =
        _loadReviewLogs().where((log) => log.spaceId != spaceId).toList();
    await _saveReviewLogs(logs);
  }

  @override
  Future<void> replaceReviewLogs(List<ReviewLog> logs) async {
    await _saveReviewLogs(
      List<ReviewLog>.of(logs)
        ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt)),
    );
  }

  @override
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
    required List<ReviewLog> reviewLogs,
  }) async {
    await _saveSpaces(spaces);
    await _saveDecks(decks);
    await _saveCards(cards);
    await _saveReviewLogs(
      List<ReviewLog>.of(reviewLogs)
        ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt)),
    );
  }
}
