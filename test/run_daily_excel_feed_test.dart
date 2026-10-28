import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/repositories/excel_import_repository_impl.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/run_daily_excel_feed_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_local_data_source.dart';

final _day1 = DateTime(2026, 3, 1);

ExcelImport _file(String id, {int rows = 5}) => ExcelImport(
      id: id,
      spaceId: 's1',
      fileName: '$id.xlsx',
      createdAt: _day1,
      rows: [
        for (var i = 0; i < rows; i++)
          ExcelImportRow(id: '$id-r$i', front: 'w$i', back: 'b$i'),
      ],
    );

class _Cards implements IFlashcardRepository {
  _Cards(this.cards);

  final List<Flashcard> cards;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((c) => c.deckId == deckId).toList();

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<Flashcard> addCard(Flashcard card) async {
    cards.add(card);
    return card;
  }

  @override
  Future<void> deleteCard(String id) async =>
      cards.removeWhere((c) => c.id == id);

  @override
  Future<Flashcard?> getCardById(String id) async =>
      cards.where((c) => c.id == id).firstOrNull;

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;
}

class _Decks implements IDeckRepository {
  _Decks(this.decks);

  final List<Deck> decks;

  @override
  Future<List<Deck>> getAllDecks() async => decks;

  @override
  Future<Deck?> getDeckById(String id) async =>
      decks.where((d) => d.id == id).firstOrNull;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async => decks;

  @override
  Future<Deck> addDeck(Deck deck) async => deck;

  @override
  Future<void> deleteDeck(String id) async {}

  @override
  Future<Deck> updateDeck(Deck deck) async => deck;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryLocalDataSource local;
  late SpaceSettingsStore settingsStore;
  late ExcelImportRepositoryImpl excel;
  late _Cards cards;
  late RunDailyExcelFeedUseCase feed;
  var nextId = 0;

  Future<void> setUpWorld({
    required DailyExcelFeedSettings settings,
    List<ExcelImport> files = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settingsStore = SpaceSettingsStore(prefs);
    excel = ExcelImportRepositoryImpl(ExcelImportStore(prefs));

    local = InMemoryLocalDataSource(
      spaces: [
        LearningSpace(
          id: 's1',
          name: 'Space',
          color: DeckColor.lavender,
          createdAt: _day1,
        ),
      ],
      decks: [
        Deck(
          id: 'd1',
          spaceId: 's1',
          name: 'Feed',
          color: DeckColor.mint,
          createdAt: _day1,
        ),
      ],
    );
    cards = _Cards([]);

    await settingsStore.save('s1', SpaceSettingsData(dailyExcelFeed: settings));
    for (final file in files) {
      await excel.saveImport(file);
    }

    feed = RunDailyExcelFeedUseCase(
      localDataSource: local,
      spaceSettingsStore: settingsStore,
      excelRepository: excel,
      addSelectedRows: AddSelectedExcelRowsUseCase(excel, cards, _Decks(local.decks)),
      generateId: () => 'card-${nextId++}',
    );
  }

  const ready = DailyExcelFeedSettings(
    enabled: true,
    deckId: 'd1',
    importIds: ['a'],
    dailyLimit: 3,
  );

  test('a run adds rows up to the cap and marks them as added', () async {
    await setUpWorld(settings: ready, files: [_file('a', rows: 10)]);

    final report = await feed(now: _day1);

    expect(report.totalAdded, 3);
    expect(cards.cards, hasLength(3));
    expect(report.totalBacklog, 7);

    final stored = await excel.getImportById('a');
    expect(stored!.addedCount, 3);
    expect(stored.pendingCount, 7);
  });

  test('a second run on the same day adds nothing', () async {
    await setUpWorld(settings: ready, files: [_file('a', rows: 10)]);

    await feed(now: _day1);
    final second = await feed(now: _day1.add(const Duration(hours: 5)));

    expect(second.totalAdded, 0);
    expect(cards.cards, hasLength(3));
  });

  test('the next day releases the next chunk, never more than the cap',
      () async {
    await setUpWorld(settings: ready, files: [_file('a', rows: 10)]);

    await feed(now: _day1);
    final day2 = await feed(now: _day1.add(const Duration(days: 1)));
    final day3 = await feed(now: _day1.add(const Duration(days: 2)));

    expect(day2.totalAdded, 3);
    expect(day3.totalAdded, 3);
    expect(cards.cards, hasLength(9));
  });

  test('a week away still releases only one chunk', () async {
    await setUpWorld(
      settings: ready.copyWith(dailyLimit: 5),
      files: [_file('a', rows: 100)],
    );

    final report = await feed(
      now: _day1,
      // Pretend the last run was a week ago.
      force: true,
    );
    expect(report.totalAdded, 5);

    await settingsStore.save(
      's1',
      (await settingsStore.load('s1')).copyWith(
        dailyExcelFeed: (await settingsStore.load('s1')).dailyExcelFeed.copyWith(
              lastRunDay: dayNumber(_day1) - 7,
            ),
      ),
    );

    final afterAway = await feed(now: _day1.add(const Duration(days: 7)));
    expect(afterAway.totalAdded, 5, reason: 'one day’s worth, not seven days’');
  });

  test('the last run day is recorded so tomorrow can differ from today',
      () async {
    await setUpWorld(settings: ready, files: [_file('a', rows: 10)]);

    await feed(now: _day1);

    final stored = (await settingsStore.load('s1')).dailyExcelFeed;
    expect(stored.lastRunDay, dayNumber(_day1));
    expect(stored.lastRunAdded, 3);
  });

  test('a disabled feed does nothing', () async {
    await setUpWorld(
      settings: ready.copyWith(enabled: false),
      files: [_file('a', rows: 10)],
    );

    final report = await feed(now: _day1);

    expect(report.totalAdded, 0);
    expect(report.spaces.single.skipped, isTrue);
  });

  test('a feed with no deck or no files does nothing', () async {
    await setUpWorld(settings: ready.copyWith(clearDeckId: true));
    expect((await feed(now: _day1)).totalAdded, 0);

    await setUpWorld(settings: ready.copyWith(importIds: []));
    expect((await feed(now: _day1)).totalAdded, 0);
  });

  test('rows carry their tags into the deck', () async {
    await setUpWorld(
      settings: ready.copyWith(dailyLimit: 1),
      files: [
        ExcelImport(
          id: 'a',
          spaceId: 's1',
          fileName: 'a.xlsx',
          createdAt: _day1,
          rows: [
            ExcelImportRow(
              id: 'a-r0',
              front: 'apple',
              back: 'سیب',
              tags: ['hard'],
            ),
          ],
        ),
      ],
    );

    await feed(now: _day1);

    expect(cards.cards.single.tags, ['hard']);
  });

  test('a file deleted after setup is dropped from the feed', () async {
    await setUpWorld(settings: ready, files: [_file('a', rows: 5)]);
    await excel.deleteImport('a');

    final report = await feed(now: _day1);

    expect(report.totalAdded, 0);
    final stored = (await settingsStore.load('s1')).dailyExcelFeed;
    expect(stored.importIds, isEmpty);
    expect(stored.enabled, isFalse, reason: 'nothing left to draw from');
  });

  test('a file in the feed but absent from the library is not resurrected',
      () async {
    await setUpWorld(settings: ready, files: []);

    final report = await feed(now: _day1);

    expect(report.totalAdded, 0);
    expect(cards.cards, isEmpty);
  });

  test('force ignores the same-day check but never the cap', () async {
    await setUpWorld(
      settings: ready.copyWith(dailyLimit: 2),
      files: [_file('a', rows: 10)],
    );

    await feed(now: _day1);
    final manual = await feed(now: _day1, force: true);

    expect(manual.totalAdded, 2, reason: 'the cap still holds on a manual run');
    expect(cards.cards, hasLength(4));
  });

  test('running one space by hand reports what it did', () async {
    await setUpWorld(settings: ready, files: [_file('a', rows: 10)]);

    final result = await feed.runForSpaceId(spaceId: 's1', now: _day1);

    expect(result.spaceId, 's1');
    expect(result.spaceName, 'Space');
    expect(result.addedCount, 3);
    expect(result.backlog, 7);
    expect(result.hitLimit, isTrue);
  });

  test('the cap spans several files rather than applying to each', () async {
    await setUpWorld(
      settings: ready.copyWith(importIds: ['a', 'b'], dailyLimit: 3),
      files: [_file('a', rows: 5), _file('b', rows: 5)],
    );

    final report = await feed(now: _day1);

    expect(report.totalAdded, 3);
    final a = await excel.getImportById('a');
    final b = await excel.getImportById('b');
    expect(a!.addedCount + b!.addedCount, 3);
  });

  test('an already-full file contributes nothing', () async {
    await setUpWorld(
      settings: ready,
      files: [_file('a', rows: 3).copyWith(
        rows: [
          for (final row in _file('a', rows: 3).rows)
            row.copyWith(isAdded: true),
        ],
      )],
    );

    final report = await feed(now: _day1);

    expect(report.totalAdded, 0);
    expect(report.totalBacklog, 0);
  });
}