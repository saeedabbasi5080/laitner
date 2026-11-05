import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/reminder_settings.dart';
import 'package:recall/domain/entities/review_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guards the store against the failure mode where a new field is added to
/// [SpaceSettingsData] but forgotten in one of the two directions, which shows
/// up as settings silently resetting whenever the app is reopened.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpaceSettingsStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = SpaceSettingsStore(await SharedPreferences.getInstance());
  });

  test('the daily feed survives a write and a read', () async {
    const feed = DailyExcelFeedSettings(
      enabled: true,
      deckId: 'deck-1',
      importIds: ['file-a', 'file-b'],
      dailyLimit: 75,
      lastRunDay: 20500,
      lastRunAdded: 75,
    );

    await store.save(
      'space-1',
      const SpaceSettingsData(dailyExcelFeeds: [feed]),
    );

    final loaded = await store.load('space-1');
    expect(loaded.dailyExcelFeeds.single.enabled, isTrue);
    expect(loaded.dailyExcelFeeds.single.deckId, 'deck-1');
    expect(loaded.dailyExcelFeeds.single.importIds, ['file-a', 'file-b']);
    expect(loaded.dailyExcelFeeds.single.dailyLimit, 75);
    expect(loaded.dailyExcelFeeds.single.lastRunDay, 20500);
    expect(loaded.dailyExcelFeeds.single.lastRunAdded, 75);
  });

  test('an untouched space has no feeds', () async {
    final loaded = await store.load('never-saved');
    expect(loaded.dailyExcelFeeds, isEmpty);
  });

  test('the single feed of an older version becomes the first of the list', () async {
    SharedPreferences.setMockInitialValues({
      'recall_space_settings_space-1':
          '{"dailyExcelFeed":{"enabled":true,"deckId":"deck-1","importIds":["file-a"],"dailyLimit":30,"lastRunDay":20500}}',
    });
    final old = SpaceSettingsStore(await SharedPreferences.getInstance());

    final feed = (await old.load('space-1')).dailyExcelFeeds.single;
    expect((feed.id, feed.enabled, feed.deckId, feed.dailyLimit, feed.lastRunDay), ('', true, 'deck-1', 30, 20500));
    expect(feed.importIds, ['file-a']);
  });

  test('an older feed that was never set up is not carried over', () async {
    SharedPreferences.setMockInitialValues({
      'recall_space_settings_space-1': '{"dailyExcelFeed":{"enabled":false,"importIds":[],"dailyLimit":200}}',
    });
    final old = SpaceSettingsStore(await SharedPreferences.getInstance());
    expect((await old.load('space-1')).dailyExcelFeeds, isEmpty);
  });

  test('several decks keep their own feeds, and one is replaced by its id', () async {
    final settings = const SpaceSettingsData()
        .withFeed(const DailyExcelFeedSettings(id: 'f1', enabled: true, deckId: 'd1', dailyLimit: 10))
        .withFeed(const DailyExcelFeedSettings(id: 'f2', enabled: true, deckId: 'd2', dailyLimit: 50))
        .withFeed(const DailyExcelFeedSettings(id: 'f1', enabled: false, deckId: 'd1', dailyLimit: 20));
    await store.save('space-1', settings);

    final loaded = (await store.load('space-1')).dailyExcelFeeds;
    expect(loaded.map((f) => (f.id, f.deckId, f.enabled, f.dailyLimit)), [
      ('f1', 'd1', false, 20),
      ('f2', 'd2', true, 50),
    ]);
    expect((await store.load('space-1')).withoutFeed('f1').dailyExcelFeeds.single.id, 'f2');
  });

  test('saving the feed does not wipe the other space settings', () async {
    await store.save(
      'space-1',
      const SpaceSettingsData(
        reminder: ReminderSettings(enabled: true, hour: 21, minute: 30),
        reviewSettings: ReviewSettings(
          dontKnowBehaviour: DontKnowBehaviour.stepBack,
        ),
      ),
    );

    await store.save(
      'space-1',
      (await store.load('space-1')).copyWith(
        dailyExcelFeeds: const [
          DailyExcelFeedSettings(
            enabled: true,
            deckId: 'deck-1',
            importIds: ['file-a'],
          ),
        ],
      ),
    );

    final loaded = await store.load('space-1');
    expect(loaded.reminder.enabled, isTrue);
    expect(loaded.reminder.hour, 21);
    expect(loaded.reminder.minute, 30);
    expect(
      loaded.reviewSettings.dontKnowBehaviour,
      DontKnowBehaviour.stepBack,
    );
    expect(loaded.dailyExcelFeeds.single.enabled, isTrue);
  });

  test('the feed is included in the backup export and restore', () async {
    await store.save(
      'space-1',
      const SpaceSettingsData(
        dailyExcelFeeds: [
          DailyExcelFeedSettings(
            enabled: true,
            deckId: 'deck-1',
            importIds: ['file-a'],
            dailyLimit: 40,
            lastRunDay: 100,
          ),
        ],
      ),
    );

    final exported = await store.exportAll();
    expect(exported['space-1']!.dailyExcelFeeds.single.dailyLimit, 40);

    await store.clearAll();
    await store.replaceAll(exported);

    final restored = (await store.load('space-1')).dailyExcelFeeds.single;
    expect(restored.enabled, isTrue);
    expect(restored.deckId, 'deck-1');
    expect(restored.importIds, ['file-a']);
    expect(restored.dailyLimit, 40);
    expect(restored.lastRunDay, 100);
  });

  test('each space keeps its own feed', () async {
    await store.save(
      'space-a',
      const SpaceSettingsData(
        dailyExcelFeeds: [DailyExcelFeedSettings(enabled: true, deckId: 'da')],
      ),
    );
    await store.save(
      'space-b',
      const SpaceSettingsData(
        dailyExcelFeeds: [DailyExcelFeedSettings(enabled: true, deckId: 'db')],
      ),
    );

    expect((await store.load('space-a')).dailyExcelFeeds.single.deckId, 'da');
    expect((await store.load('space-b')).dailyExcelFeeds.single.deckId, 'db');
  });

  test('a corrupt blob degrades to the defaults instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'recall_space_settings_space-1': 'not json at all',
    });
    final fresh = SpaceSettingsStore(await SharedPreferences.getInstance());

    final loaded = await fresh.load('space-1');
    expect(loaded.dailyExcelFeeds, isEmpty);
  });
}