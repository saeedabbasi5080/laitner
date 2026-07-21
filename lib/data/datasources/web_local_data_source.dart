import 'dart:convert';

import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Web fallback storage using SharedPreferences (Isar does not support web).
class WebLocalDataSource implements LocalDataSource {
  WebLocalDataSource(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  static const _spacesKey = 'recall_web_spaces';
  static const _decksKey = 'recall_web_decks';
  static const _cardsKey = 'recall_web_cards';

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

  Map<String, dynamic> _cardToJson(Flashcard card) => {
        'id': card.id,
        'deckId': card.deckId,
        'front': card.front,
        'back': card.back,
        'box': card.box,
        'lastReviewed': card.lastReviewed?.toIso8601String(),
        'createdAt': card.createdAt.toIso8601String(),
      };

  Flashcard _cardFromJson(Map<String, dynamic> json) => Flashcard(
        id: json['id'] as String,
        deckId: json['deckId'] as String,
        front: json['front'] as String,
        back: json['back'] as String,
        box: json['box'] as int,
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(json['lastReviewed'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

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
  String generateId() => _uuid.v4();
}
