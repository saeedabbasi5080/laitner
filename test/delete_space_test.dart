import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/space_repository.dart';
import 'package:recall/domain/usecases/delete_space_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _FakeSpaceRepository spaces;
  late _FakeDeckRepository decks;
  late ReviewHistoryStore reviewHistory;
  late ExcelImportStore excelImports;
  late SpaceSettingsStore settings;
  late DeleteSpaceUseCase useCase;

  final source = LearningSpace(
    id: 'space-a',
    name: 'A',
    color: DeckColor.lavender,
    createdAt: DateTime(2026, 1, 1),
  );
  final target = LearningSpace(
    id: 'space-b',
    name: 'B',
    color: DeckColor.mint,
    createdAt: DateTime(2026, 1, 2),
    sortOrder: 1,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final decksList = [
      Deck(
        id: 'deck-1',
        spaceId: 'space-a',
        name: 'Vocab',
        color: DeckColor.sky,
        createdAt: DateTime(2026, 1, 3),
      ),
    ];
    spaces = _FakeSpaceRepository([source, target], decksList);
    decks = _FakeDeckRepository(decksList);
    reviewHistory = ReviewHistoryStore(prefs);
    excelImports = ExcelImportStore(prefs);
    settings = SpaceSettingsStore(prefs);
    useCase = DeleteSpaceUseCase(
      spaces,
      reviewHistory,
      excelImports,
      settings,
      decks,
    );

    await reviewHistory.add(
      ReviewLog(
        id: 'log-1',
        spaceId: 'space-a',
        cardId: 'card-1',
        deckId: 'deck-1',
        rating: ReviewRating.know,
        boxBefore: 1,
        boxAfter: 2,
        reviewedAt: DateTime(2026, 1, 4),
      ),
    );
    await excelImports.save(
      ExcelImport(
        id: 'excel-1',
        spaceId: 'space-a',
        fileName: 'words.xlsx',
        createdAt: DateTime(2026, 1, 5),
        rows: const [],
      ),
    );
    await settings.save('space-a', const SpaceSettingsData());
  });

  test('transfer keeps decks, reviews and excel in the target space', () async {
    await useCase('space-a', transferToSpaceId: 'space-b');

    expect(spaces.spaces.map((space) => space.id), ['space-b']);
    expect(decks.decks.single.spaceId, 'space-b');
    expect(reviewHistory.getAll().single.spaceId, 'space-b');
    expect((await excelImports.getAll()).single.spaceId, 'space-b');
    expect((await excelImports.getBySpaceId('space-a')), isEmpty);
  });

  test('delete without transfer removes space content', () async {
    await useCase('space-a');

    expect(spaces.spaces.map((space) => space.id), ['space-b']);
    expect(decks.decks, isEmpty);
    expect(reviewHistory.getAll(), isEmpty);
    expect(await excelImports.getAll(), isEmpty);
  });
}

class _FakeSpaceRepository implements ISpaceRepository {
  _FakeSpaceRepository(this.spaces, this.decks);

  final List<LearningSpace> spaces;
  final List<Deck> decks;

  @override
  Future<LearningSpace> addSpace(LearningSpace space) async {
    spaces.add(space);
    return space;
  }

  @override
  Future<void> deleteSpace(String id) async {
    spaces.removeWhere((space) => space.id == id);
    decks.removeWhere((deck) => deck.spaceId == id);
  }

  @override
  Future<List<LearningSpace>> getAllSpaces() async => spaces;

  @override
  Future<LearningSpace?> getSpaceById(String id) async =>
      spaces.where((space) => space.id == id).firstOrNull;

  @override
  Future<int> getSpaceCount() async => spaces.length;

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) async => space;
}

class _FakeDeckRepository implements IDeckRepository {
  _FakeDeckRepository(this.decks);

  final List<Deck> decks;

  @override
  Future<Deck> addDeck(Deck deck) async {
    decks.add(deck);
    return deck;
  }

  @override
  Future<void> deleteDeck(String id) async {
    decks.removeWhere((deck) => deck.id == id);
  }

  @override
  Future<List<Deck>> getAllDecks() async => decks;

  @override
  Future<Deck?> getDeckById(String id) async =>
      decks.where((deck) => deck.id == id).firstOrNull;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async =>
      decks.where((deck) => deck.spaceId == spaceId).toList();

  @override
  Future<Deck> updateDeck(Deck deck) async {
    final index = decks.indexWhere((item) => item.id == deck.id);
    if (index >= 0) decks[index] = deck;
    return deck;
  }
}
