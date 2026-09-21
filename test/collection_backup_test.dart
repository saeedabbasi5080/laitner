import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/data/backup/collection_backup.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/export_collection_backup_usecase.dart';
import 'package:recall/domain/usecases/restore_collection_backup_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _FakeLocalDataSource local;
  late ReviewHistoryStore reviews;
  late ExcelImportStore excel;
  late SpaceSettingsStore settings;
  late SharedPreferences prefs;

  final space = LearningSpace(
    id: 'space-1',
    name: 'English',
    color: DeckColor.mint,
    createdAt: DateTime(2026, 1, 1),
  );
  final deck = Deck(
    id: 'deck-1',
    spaceId: 'space-1',
    name: 'Words',
    color: DeckColor.sky,
    createdAt: DateTime(2026, 1, 2),
  );
  final card = Flashcard(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'hello',
    back: 'سلام',
    box: 2,
    lastReviewed: DateTime(2026, 1, 3),
    createdAt: DateTime(2026, 1, 2),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    local = _FakeLocalDataSource(
      spaces: [space],
      decks: [deck],
      cards: [card],
    );
    reviews = ReviewHistoryStore(prefs);
    excel = ExcelImportStore(prefs);
    settings = SpaceSettingsStore(prefs);
    await reviews.add(
      ReviewLog(
        id: 'log-1',
        spaceId: 'space-1',
        cardId: 'card-1',
        deckId: 'deck-1',
        rating: ReviewRating.know,
        boxBefore: 1,
        boxAfter: 2,
        reviewedAt: DateTime(2026, 1, 3),
      ),
    );
    await settings.save('space-1', const SpaceSettingsData());
  });

  test('export then restore replaces the collection', () async {
    final exported = await ExportCollectionBackupUseCase(
      localDataSource: local,
      reviewHistoryStore: reviews,
      excelImportStore: excel,
      spaceSettingsStore: settings,
    )(now: DateTime(2026, 9, 21));

    local.spaces = [];
    local.decks = [];
    local.cards = [];
    await reviews.replaceAll(const []);
    await excel.replaceAll(const []);
    await settings.clearAll();

    final result = await RestoreCollectionBackupUseCase(
      localDataSource: local,
      reviewHistoryStore: reviews,
      excelImportStore: excel,
      spaceSettingsStore: settings,
      prefs: prefs,
    )(jsonEncode(exported.toJson()));

    expect(result.cardCount, 1);
    expect(result.firstSpaceId, 'space-1');
    expect(local.cards.single.front, 'hello');
    expect(local.cards.single.box, 2);
    expect(reviews.getAll(), hasLength(1));
    expect(prefs.getBool(defaultSpaceMigrationKey), isTrue);
  });

  test('invalid backup file is rejected', () async {
    final restore = RestoreCollectionBackupUseCase(
      localDataSource: local,
      reviewHistoryStore: reviews,
      excelImportStore: excel,
      spaceSettingsStore: settings,
      prefs: prefs,
    );

    expect(
      () => restore('{"hello":"world"}'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(local.cards, isNotEmpty);
  });
}

class _FakeLocalDataSource implements LocalDataSource {
  _FakeLocalDataSource({
    required this.spaces,
    required this.decks,
    required this.cards,
  });

  List<LearningSpace> spaces;
  List<Deck> decks;
  List<Flashcard> cards;

  @override
  Future<LearningSpace> addSpace(LearningSpace space) async => space;

  @override
  Future<Deck> addDeck(Deck deck) async => deck;

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<void> deleteDeck(String id) async {}

  @override
  Future<void> deleteSpace(String id) async {}

  @override
  String generateId() => 'id';

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Deck>> getAllDecks() async => decks;

  @override
  Future<List<LearningSpace>> getAllSpaces() async => spaces;

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => [];

  @override
  Future<Deck?> getDeckById(String id) async => null;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async => [];

  @override
  Future<LearningSpace?> getSpaceById(String id) async => null;

  @override
  Future<int> getSpaceCount() async => spaces.length;

  @override
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
  }) async {
    this.spaces = List.of(spaces);
    this.decks = List.of(decks);
    this.cards = List.of(cards);
  }

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;

  @override
  Future<Deck> updateDeck(Deck deck) async => deck;

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) async => space;
}
