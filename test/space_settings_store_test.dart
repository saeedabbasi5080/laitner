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
      const SpaceSettingsData(dailyExcelFeed: feed),
    );

    final loaded = await store.load('space-1');
    expect(loaded.dailyExcelFeed.enabled, isTrue);
    expect(loaded.dailyExcelFeed.deckId, 'deck-1');
    expect(loaded.dailyExcelFeed.importIds, ['file-a', 'file-b']);
    expect(loaded.dailyExcelFeed.dailyLimit, 75);
    expect(loaded.dailyExcelFeed.lastRunDay, 20500);
    expect(loaded.dailyExcelFeed.lastRunAdded, 75);
  });

  test('an untouched space still reads the feed defaults', () async {
    final loaded = await store.load('never-saved');

    expect(loaded.dailyExcelFeed.enabled, isFalse);
    expect(loaded.dailyExcelFeed.deckId, isNull);
    expect(loaded.dailyExcelFeed.importIds, isEmpty);
    expect(
      loaded.dailyExcelFeed.dailyLimit,
      DailyExcelFeedSettings.defaultDailyLimit,
    );
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
        dailyExcelFeed: const DailyExcelFeedSettings(
          enabled: true,
          deckId: 'deck-1',
          importIds: ['file-a'],
        ),
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
    expect(loaded.dailyExcelFeed.enabled, isTrue);
  });

  test('the feed is included in the backup export and restore', () async {
    await store.save(
      'space-1',
      const SpaceSettingsData(
        dailyExcelFeed: DailyExcelFeedSettings(
          enabled: true,
          deckId: 'deck-1',
          importIds: ['file-a'],
          dailyLimit: 40,
          lastRunDay: 100,
        ),
      ),
    );

    final exported = await store.exportAll();
    expect(exported['space-1']!.dailyExcelFeed.dailyLimit, 40);

    await store.clearAll();
    await store.replaceAll(exported);

    final restored = (await store.load('space-1')).dailyExcelFeed;
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
        dailyExcelFeed: DailyExcelFeedSettings(enabled: true, deckId: 'da'),
      ),
    );
    await store.save(
      'space-b',
      const SpaceSettingsData(
        dailyExcelFeed: DailyExcelFeedSettings(enabled: true, deckId: 'db'),
      ),
    );

    expect((await store.load('space-a')).dailyExcelFeed.deckId, 'da');
    expect((await store.load('space-b')).dailyExcelFeed.deckId, 'db');
  });

  test('a corrupt blob degrades to the defaults instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      'recall_space_settings_space-1': 'not json at all',
    });
    final fresh = SpaceSettingsStore(await SharedPreferences.getInstance());

    final loaded = await fresh.load('space-1');
    expect(loaded.dailyExcelFeed.enabled, isFalse);
    expect(loaded.dailyExcelFeed.dailyLimit, 200);
  });
}