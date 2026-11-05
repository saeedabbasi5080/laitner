import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recall/data/datasources/api_transport.dart';
import 'package:recall/data/datasources/http_catalog_remote.dart';
import 'package:recall/data/repositories/deck_repository_impl.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/data/repositories/space_repository_impl.dart';
import 'package:recall/data/utils/excel_parser.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/repositories/catalog_remote.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/domain/usecases/add_catalog_words_usecase.dart';
import 'package:recall/domain/usecases/catalog_cards.dart';
import 'package:recall/domain/usecases/export_catalog_excel_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/queue_catalog_words_usecase.dart';
import 'package:recall/domain/usecases/run_daily_excel_feed_usecase.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/repositories/excel_import_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recall/presentation/screens/catalog_screen.dart';
import 'package:recall/presentation/widgets/catalog_add_sheet.dart';

import 'support/in_memory_local_data_source.dart';

const _course = CatalogNode(
  id: 7,
  kind: CatalogNodeKind.course,
  sourceLang: 'fa',
  targetLang: 'en',
  title: '504 Words',
  wordCount: 3,
  hasChildren: true,
);

const _list = CatalogWordList(
  node: _course,
  lessons: [
    CatalogLesson(id: 1, title: 'درس 1', words: [
      CatalogWord(term: 'abandon', meaning: 'ترک کردن', pronunciation: 'əˈbændən'),
      CatalogWord(term: 'keen', meaning: 'مشتاق'),
    ]),
    CatalogLesson(id: 2, title: 'درس 2', words: [
      CatalogWord(term: 'oath', meaning: 'سوگند'),
      CatalogWord(term: '  ', meaning: 'no front'),
    ]),
  ],
);

class _Ids implements IdGenerator {
  var _n = 0;

  @override
  String generateId() => 'id-${++_n}';
}

final _space = LearningSpace(id: 's1', name: 'انگلیسی', color: DeckColor.mint, createdAt: DateTime(2026));

void main() {
  group('cards from a list', () {
    test('meaning on the back with the pronunciation under it, and a lesson tag per card', () {
      expect(_flat(catalogCardRows(_list.lessons, const CatalogCardOptions())), [
        ('abandon', 'ترک کردن\n/əˈbændən/', 'درس_1'),
        ('keen', 'مشتاق', 'درس_1'),
        ('oath', 'سوگند', 'درس_2'),
      ]);
    });

    test('the options turn pronunciation and tags off', () {
      final rows = catalogCardRows(
        _list.lessons,
        const CatalogCardOptions(includePronunciation: false, tagLessons: false),
      );
      expect(_flat(rows).first, ('abandon', 'ترک کردن', ''));
    });

    test('a single lesson is not tagged with its own name', () {
      final rows = catalogCardRows([_list.lessons.first], const CatalogCardOptions());
      expect(rows.every((row) => row.tags.isEmpty), isTrue);
    });
  });

  group('adding to a deck', () {
    late InMemoryLocalDataSource local;
    late AddCatalogWordsUseCase add;

    setUp(() {
      local = InMemoryLocalDataSource(spaces: [_space]);
      add = AddCatalogWordsUseCase(DeckRepositoryImpl(local), FlashcardRepositoryImpl(local), _Ids(),
          clock: () => DateTime(2026, 11, 4, 10));
    });

    test('a new deck named after the list, with every word as a new card', () async {
      final result = await add(
        list: _list,
        target: const NewDeckTarget(spaceId: 's1', name: '  ', color: DeckColor.sky),
      );
      expect(result.deck.name, '504 Words');
      expect(result.deck.spaceId, 's1');
      expect((result.added, result.skipped), (3, 0));
      expect(local.cards.map((c) => (c.front, c.deckId, c.box)), [
        ('abandon', result.deck.id, 1),
        ('keen', result.deck.id, 1),
        ('oath', result.deck.id, 1),
      ]);
    });

    test('an existing deck keeps its cards and does not get the same word twice', () async {
      local.decks.add(Deck(id: 'd1', spaceId: 's1', name: 'لغات', color: DeckColor.mint, createdAt: DateTime(2026)));
      local.cards.add(Flashcard(
        id: 'old',
        deckId: 'd1',
        front: 'Keen',
        back: 'مشتاق',
        box: 3,
        createdAt: DateTime(2026),
      ));

      final result = await add(list: _list, target: const ExistingDeckTarget('d1'));
      expect((result.added, result.skipped, result.deck.name), (2, 1, 'لغات'));
      // The card the learner already had keeps its progress.
      expect(local.cards.firstWhere((c) => c.id == 'old').box, 3);

      // Adding the same list again adds nothing.
      expect((await add(list: _list, target: const ExistingDeckTarget('d1'))).added, 0);
    });

    test('a word already in another deck of the space is not added again', () async {
      local.decks.add(Deck(id: 'other', spaceId: 's1', name: 'قبلی', color: DeckColor.mint, createdAt: DateTime(2026)));
      local.cards.add(Flashcard(id: 'x', deckId: 'other', front: 'oath', back: 'سوگند', box: 2, createdAt: DateTime(2026)));
      final result = await add(
        list: _list,
        target: const NewDeckTarget(spaceId: 's1', name: 'new', color: DeckColor.sky),
      );
      expect((result.added, result.skipped), (2, 1));
    });

    test('a deck that no longer exists is an error, not a silent new deck', () async {
      expect(
        () => add(list: _list, target: const ExistingDeckTarget('gone')),
        throwsA(isA<CatalogDeckNotFoundException>()),
      );
    });
  });

  group('adding gradually', () {
    late InMemoryLocalDataSource local;
    late SpaceSettingsStore settings;
    late QueueCatalogWordsUseCase queue;
    late ExcelImportRepositoryImpl library;
    final today = DateTime(2026, 11, 4, 10);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      settings = SpaceSettingsStore(prefs);
      local = InMemoryLocalDataSource(spaces: [_space]);
      library = ExcelImportRepositoryImpl(ExcelImportStore(prefs));
      final ids = _Ids();
      final decks = DeckRepositoryImpl(local);
      final cards = FlashcardRepositoryImpl(local);
      queue = QueueCatalogWordsUseCase(
        decks: decks,
        cards: cards,
        library: library,
        settings: settings,
        runFeed: RunDailyExcelFeedUseCase(
          localDataSource: local,
          spaceSettingsStore: settings,
          excelRepository: library,
          addSelectedRows: AddSelectedExcelRowsUseCase(library, cards, decks),
          generateId: ids.generateId,
        ),
        ids: ids,
        clock: () => today,
      );
    });

    test('queues the list in the library, makes the deck a feed, and adds the first share now', () async {
      final result = await queue(
        list: _list,
        target: const NewDeckTarget(spaceId: 's1', name: '', color: DeckColor.sky),
        dailyLimit: 2,
      );
      expect((result.queued, result.addedToday, result.dailyLimit), (3, 2, 2));
      expect(local.cards.map((c) => c.front), ['abandon', 'keen']);

      final file = (await library.getImportsBySpaceId('s1')).single;
      expect(file.fileName, '504 Words');
      expect(file.pendingCount, 1);

      final feed = (await settings.load('s1')).dailyExcelFeeds.single;
      expect((feed.deckId, feed.enabled, feed.dailyLimit), (result.deck.id, true, 2));
      expect(feed.importIds, [file.id]);
    });

    test('a deck that already has a feed gets the list at the end of its queue', () async {
      final first = await queue(
        list: _list,
        target: const NewDeckTarget(spaceId: 's1', name: 'Words', color: DeckColor.sky),
        dailyLimit: 2,
      );
      // Same day: that feed already ran, so the new list waits for tomorrow.
      final second = await queue(
        list: const CatalogWordList(node: _course, lessons: [
          CatalogLesson(id: 3, title: 'more', words: [CatalogWord(term: 'vacant', meaning: 'خالی')]),
        ]),
        target: ExistingDeckTarget(first.deck.id),
        dailyLimit: 5,
      );
      expect((second.queued, second.addedToday), (1, 0));
      final feed = (await settings.load('s1')).dailyExcelFeeds.single;
      expect((feed.importIds.length, feed.dailyLimit), (2, 5));
    });

    test('nothing is queued when the space already has every word', () async {
      local.decks.add(Deck(id: 'd', spaceId: 's1', name: 'd', color: DeckColor.mint, createdAt: today));
      for (final row in catalogCardRows(_list.lessons, const CatalogCardOptions())) {
        local.cards.add(Flashcard(id: row.front, deckId: 'd', front: row.front, back: row.back, box: 1, createdAt: today));
      }
      final result = await queue(list: _list, target: const ExistingDeckTarget('d'), dailyLimit: 10);
      expect(result.queued, 0);
      expect(await library.getImportsBySpaceId('s1'), isEmpty);
      expect((await settings.load('s1')).dailyExcelFeeds, isEmpty);
    });
  });

  test('the Excel file reads back through the app\'s own importer', () {
    final exported = const ExportCatalogExcelUseCase()(_list);
    expect(exported.fileName, '504 Words.xlsx');
    final rows = ExcelParser.parseRows(exported.bytes);
    expect(_flat(rows), [
      ('abandon', 'ترک کردن\n/əˈbændən/', 'درس_1'),
      ('keen', 'مشتاق', 'درس_1'),
      ('oath', 'سوگند', 'درس_2'),
    ]);
  });

  group('the catalog API', () {
    HttpCatalogRemote remote(Map<String, Object> pages, {List<Uri>? asked}) => HttpCatalogRemote(
          transport: ApiTransport(
            baseUrl: 'http://api.test/api/v1',
            client: MockClient((request) async {
              asked?.add(request.url);
              final page = pages['${request.url.path}?${request.url.query}'] ?? pages[request.url.path];
              if (page == null) {
                return http.Response(jsonEncode({'error': 'یافت نشد.', 'code': 'not_found'}), 404,
                    headers: {'content-type': 'application/json; charset=utf-8'});
              }
              return http.Response.bytes(utf8.encode(jsonEncode(page)), 200,
                  headers: {'content-type': 'application/json; charset=utf-8'});
            }),
          ),
        );

    test('reads languages, roots, a node and its words', () async {
      final asked = <Uri>[];
      final api = remote({
        '/api/v1/catalog/languages?source=fa': {
          'sourceLang': 'fa',
          'languages': [
            {'targetLang': 'en', 'lists': 2, 'words': 1285},
            {'targetLang': null, 'lists': 1, 'words': 40},
          ],
        },
        '/api/v1/catalog/nodes?source=fa&target=-': {
          'nodes': [
            {'id': 3, 'kind': 'group', 'sourceLang': 'fa', 'targetLang': null, 'title': 'Chemistry', 'wordCount': 40, 'hasChildren': true},
          ],
        },
        '/api/v1/catalog/nodes/7': {
          'node': {'id': 7, 'kind': 'course', 'sourceLang': 'fa', 'targetLang': 'en', 'title': '504 Words', 'wordCount': 3, 'hasChildren': true},
          'path': [
            {'id': 1, 'title': 'English'},
            {'id': 7, 'title': '504 Words'},
          ],
          'children': [
            {'id': 8, 'kind': 'lesson', 'sourceLang': 'fa', 'targetLang': 'en', 'title': '1 - 15', 'wordCount': 3, 'hasChildren': false},
          ],
        },
        '/api/v1/catalog/nodes/7/words': {
          'node': {'id': 7, 'kind': 'course', 'sourceLang': 'fa', 'targetLang': 'en', 'title': '504 Words', 'wordCount': 3, 'hasChildren': true},
          'lessons': [
            {
              'id': 8,
              'title': '1 - 15',
              'words': [
                {'term': 'abandon', 'meaning': 'ترک کردن', 'pronunciation': null},
              ],
            },
          ],
        },
      }, asked: asked);

      expect(await api.languages('fa'), const [
        CatalogLanguage(targetLang: 'en', lists: 2, words: 1285),
        CatalogLanguage(targetLang: null, lists: 1, words: 40),
      ]);
      // A null target asks for topics.
      expect((await api.roots('fa', null)).single.title, 'Chemistry');
      final detail = await api.node(7);
      expect(detail.path.map((p) => p.title), ['English', '504 Words']);
      expect(detail.children.single.kind, CatalogNodeKind.lesson);
      final words = await api.words(7);
      expect(words.lessons.single.words.single, const CatalogWord(term: 'abandon', meaning: 'ترک کردن'));
      expect(asked.map((u) => u.path), everyElement(startsWith('/api/v1/catalog/')));
    });

    test('the server\'s message comes through for a list that is gone', () async {
      await expectLater(
        remote({}).node(99),
        throwsA(isA<AuthError>().having((e) => e.message, 'message', 'یافت نشد.')),
      );
    });
  });

  group('screens', () {
    testWidgets('a language leads to its lists, and a lesson shows its words with both actions', (tester) async {
      await tester.pumpWidget(_app(const CatalogLanguagesScreen(remote: _FakeRemote())));
      await tester.pumpAndSettle();
      expect(find.text('انگلیسی'), findsOneWidget);
      expect(find.text('موضوعی'), findsOneWidget);

      await tester.tap(find.text('انگلیسی'));
      await tester.pumpAndSettle();
      expect(find.text('504 Words'), findsOneWidget);

      await tester.tap(find.text('504 Words'));
      await tester.pumpAndSettle();
      // Gradual first, then all at once, then the file.
      expect(find.text('افزودن تدریجی'), findsOneWidget);
      expect(find.text('افزودن یکجا'), findsOneWidget);
      expect(find.text('دانلود اکسل'), findsOneWidget);

      await tester.tap(find.text('1 - 15'));
      await tester.pumpAndSettle();
      expect(find.text('abandon'), findsOneWidget);
      expect(find.text('/əˈbændən/'), findsOneWidget);
    });

    testWidgets('more than 50 cards at once asks first, and cancelling adds nothing', (tester) async {
      final local = InMemoryLocalDataSource(spaces: [_space]);
      final decks = DeckRepositoryImpl(local);
      final big = CatalogWordList(node: _course, lessons: [
        CatalogLesson(id: 1, title: 'big', words: [for (var i = 0; i < 60; i++) CatalogWord(term: 'w$i', meaning: 'm$i')]),
      ]);
      await tester.pumpWidget(_app(Builder(
        builder: (context) => FilledButton(
          onPressed: () => showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => CatalogAddSheet(
              list: big,
              getSpaces: GetSpacesUseCase(SpaceRepositoryImpl(local)),
              getDecks: GetDecksUseCase(decks),
              addWords: AddCatalogWordsUseCase(decks, FlashcardRepositoryImpl(local), _Ids()),
            ),
          ),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('افزودن'));
      await tester.pumpAndSettle();

      expect(find.textContaining('۶۰ کارت همین حالا یکجا'), findsOneWidget);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(local.cards, isEmpty);
      expect(local.decks, isEmpty);

      await tester.tap(find.text('افزودن'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بله، همه را اضافه کن'));
      await tester.pumpAndSettle();
      expect(local.cards, hasLength(60));
    });

    testWidgets('the add sheet creates a new deck by default and reports what it added', (tester) async {
      final local = InMemoryLocalDataSource(spaces: [_space]);
      final decks = DeckRepositoryImpl(local);
      String? reported;
      await tester.pumpWidget(_app(Builder(
        builder: (context) => FilledButton(
          onPressed: () async {
            reported = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (_) => CatalogAddSheet(
                list: _list,
                getSpaces: GetSpacesUseCase(SpaceRepositoryImpl(local)),
                getDecks: GetDecksUseCase(decks),
                addWords: AddCatalogWordsUseCase(decks, FlashcardRepositoryImpl(local), _Ids()),
              ),
            );
          },
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Only one space: no space picker; the deck is named after the list.
      expect(find.text('فضا'), findsNothing);
      expect(find.widgetWithText(TextField, '504 Words'), findsOneWidget);
      // No existing deck to pick.
      final existing = tester.widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>));
      expect(existing.segments.last.enabled, isFalse);

      await tester.tap(find.text('افزودن'));
      await tester.pumpAndSettle();
      expect(local.decks.single.name, '504 Words');
      expect(local.cards, hasLength(3));
      expect(reported, '۳ کارت به «504 Words» اضافه شد.');
    });
  });
}

/// Records compare a list field by identity; the tags are compared as text.
List<(String, String, String)> _flat(Iterable<({String front, String back, List<String> tags})> rows) =>
    [for (final row in rows) (row.front, row.back, row.tags.join(','))];

Widget _app(Widget home) => MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: home),
    );

class _FakeRemote implements CatalogRemote {
  const _FakeRemote();

  static const _lesson = CatalogNode(
    id: 8,
    kind: CatalogNodeKind.lesson,
    sourceLang: 'fa',
    targetLang: 'en',
    title: '1 - 15',
    wordCount: 2,
    hasChildren: false,
  );

  @override
  Future<List<CatalogLanguage>> languages(String sourceLang) async => const [
        CatalogLanguage(targetLang: 'en', lists: 1, words: 3),
        CatalogLanguage(targetLang: null, lists: 1, words: 40),
      ];

  @override
  Future<List<CatalogNode>> roots(String sourceLang, String? targetLang) async => const [_course];

  @override
  Future<CatalogNodeDetail> node(int id) async => id == _course.id
      ? CatalogNodeDetail(node: _course, path: const [(id: 7, title: '504 Words')], children: const [_lesson])
      : CatalogNodeDetail(
          node: _lesson,
          path: const [(id: 7, title: '504 Words'), (id: 8, title: '1 - 15')],
          children: const [],
        );

  @override
  Future<CatalogWordList> words(int id) async => CatalogWordList(node: _lesson, lessons: [_list.lessons.first]);
}
