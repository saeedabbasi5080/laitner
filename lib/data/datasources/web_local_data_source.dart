import 'dart:convert';

import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/seed_data.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Web fallback storage using SharedPreferences (Isar does not support web).
class WebLocalDataSource implements LocalDataSource {
  WebLocalDataSource(this._prefs);

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  static const _decksKey = 'recall_web_decks';
  static const _cardsKey = 'recall_web_cards';

  @override
  Future<void> seedIfEmpty() async {
    if (_prefs.containsKey(_decksKey)) return;

    final sample = SeedData.sample(DateTime.now());
    await _saveDecks(sample.decks);
    await _saveCards(sample.cards);
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

  Future<void> _saveDecks(List<Deck> decks) async {
    final json = jsonEncode(decks.map(_deckToJson).toList());
    await _prefs.setString(_decksKey, json);
  }

  Future<void> _saveCards(List<Flashcard> cards) async {
    final json = jsonEncode(cards.map(_cardToJson).toList());
    await _prefs.setString(_cardsKey, json);
  }

  Map<String, dynamic> _deckToJson(Deck deck) => {
        'id': deck.id,
        'name': deck.name,
        'color': deck.color.name,
        'createdAt': deck.createdAt.toIso8601String(),
      };

  Deck _deckFromJson(Map<String, dynamic> json) => Deck(
        id: json['id'] as String,
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
  Future<List<Deck>> getAllDecks() async {
    final decks = _loadDecks()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return decks;
  }

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
