import 'package:recall/core/utils/day_key.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/build_daily_excel_feed_plan.dart';

/// What one space's feed did.
class SpaceFeedRun {
  const SpaceFeedRun({
    required this.spaceId,
    required this.spaceName,
    required this.addedCount,
    required this.backlog,
    required this.dailyLimit,
    this.duplicateCount = 0,
    this.skipped = false,
  });

  final String spaceId;
  final String spaceName;
  final int addedCount;

  /// Rows still waiting after this run.
  final int backlog;

  final int dailyLimit;

  /// How many of the added cards clashed with something already in the space.
  final int duplicateCount;

  /// True when the feed was off, unconfigured, or had already run today.
  final bool skipped;

  bool get hitLimit => addedCount >= dailyLimit && dailyLimit > 0;
}

/// The outcome of a run across every space.
class DailyExcelFeedReport {
  const DailyExcelFeedReport({this.spaces = const []});

  final List<SpaceFeedRun> spaces;

  int get totalAdded =>
      spaces.fold(0, (sum, space) => sum + space.addedCount);

  int get totalBacklog =>
      spaces.fold(0, (sum, space) => sum + space.backlog);

  List<SpaceFeedRun> get active =>
      spaces.where((space) => !space.skipped).toList();

  bool get didAnything => totalAdded > 0;
}

/// Releases one day's worth of queued Excel rows into each space's feed deck.
///
/// Runs on app start and whenever the app returns to the foreground, next to
/// the reminder sync: by then it is known how many cards are waiting, so any
/// study done elsewhere cannot have invalidated the plan.
class RunDailyExcelFeedUseCase {
  const RunDailyExcelFeedUseCase({
    required this.localDataSource,
    required this.spaceSettingsStore,
    required this.excelRepository,
    required this.addSelectedRows,
    required this.generateId,
    this.planner = const BuildDailyExcelFeedPlan(),
  });

  final LocalDataSource localDataSource;
  final SpaceSettingsStore spaceSettingsStore;
  final IExcelImportRepository excelRepository;
  final AddSelectedExcelRowsUseCase addSelectedRows;
  final String Function() generateId;
  final BuildDailyExcelFeedPlan planner;

  /// [force] ignores the "already ran today" check, which is what the manual
  /// "add now" button needs. The daily limit still applies either way.
  Future<DailyExcelFeedReport> call({DateTime? now, bool force = false}) async {
    final timestamp = now ?? DateTime.now();
    final todayDay = dayNumber(timestamp);

    final spaces = await localDataSource.getAllSpaces();
    final results = <SpaceFeedRun>[];

    for (final space in spaces) {
      final settings = await spaceSettingsStore.load(space.id);
      results.add(
        await _runForSpace(
          spaceId: space.id,
          spaceName: space.name,
          feed: settings.dailyExcelFeed,
          now: timestamp,
          todayDay: todayDay,
          force: force,
        ),
      );
    }

    return DailyExcelFeedReport(spaces: results);
  }

  /// The same work for one space, used by the settings screen's "add now"
  /// button so a manual run reports to the person who pressed it.
  Future<SpaceFeedRun> runForSpaceId({
    required String spaceId,
    DateTime? now,
    bool force = true,
  }) async {
    final timestamp = now ?? DateTime.now();
    final settings = await spaceSettingsStore.load(spaceId);
    final name = await _spaceName(spaceId);

    return _runForSpace(
      spaceId: spaceId,
      spaceName: name,
      feed: settings.dailyExcelFeed,
      now: timestamp,
      todayDay: dayNumber(timestamp),
      force: force,
    );
  }

  Future<SpaceFeedRun> _runForSpace({
    required String spaceId,
    required String spaceName,
    required DailyExcelFeedSettings feed,
    required DateTime now,
    required int todayDay,
    required bool force,
  }) async {
    final deckId = feed.deckId;
    if (!feed.enabled ||
        deckId == null ||
        deckId.isEmpty ||
        feed.importIds.isEmpty ||
        feed.dailyLimit <= 0) {
      return SpaceFeedRun(
        spaceId: spaceId,
        spaceName: spaceName,
        addedCount: 0,
        backlog: 0,
        dailyLimit: feed.dailyLimit,
        skipped: true,
      );
    }

    final allImports = await excelRepository.getImportsBySpaceId(spaceId);
    final wanted = feed.importIds.toSet();
    final imports = allImports
        .where((import) => wanted.contains(import.id))
        .toList();

    // A file deleted since the feed was set up must not resurrect it, so the
    // live id set is written back rather than the stale one kept around.
    final liveIds = imports.map((import) => import.id).toList();
    if (!_sameIds(liveIds, feed.importIds)) {
      await _saveFeed(
        spaceId,
        feed.copyWith(importIds: liveIds, enabled: liveIds.isNotEmpty && feed.enabled),
      );
    }

    final plan = planner(
      imports: imports,
      dailyLimit: feed.dailyLimit,
      lastRunDay: force ? null : feed.lastRunDay,
      todayDay: todayDay,
    );

    if (plan.isEmpty) {
      return SpaceFeedRun(
        spaceId: spaceId,
        spaceName: spaceName,
        addedCount: 0,
        backlog: plan.backlog,
        dailyLimit: feed.dailyLimit,
        skipped: plan.alreadyRanToday || imports.isEmpty,
      );
    }

    var added = 0;
    var duplicates = 0;
    for (final entry in plan.rowIdsByImport.entries) {
      final result = await addSelectedRows(
        importId: entry.key,
        deckId: deckId,
        rowIds: entry.value,
        generateId: generateId,
      );
      added += result.addedCount;
      duplicates += result.addedDuplicateCount;
    }

    await _saveFeed(
      spaceId,
      feed.copyWith(lastRunDay: todayDay, lastRunAdded: added),
    );

    return SpaceFeedRun(
      spaceId: spaceId,
      spaceName: spaceName,
      addedCount: added,
      // Read the backlog back rather than guessing: the add path may have
      // skipped rows it considered already present.
      backlog: plan.backlog - plan.totalPlanned,
      dailyLimit: feed.dailyLimit,
      duplicateCount: duplicates,
    );
  }

  Future<void> _saveFeed(String spaceId, DailyExcelFeedSettings feed) async {
    final settings = await spaceSettingsStore.load(spaceId);
    await spaceSettingsStore.save(
      spaceId,
      settings.copyWith(dailyExcelFeed: feed),
    );
  }

  Future<String> _spaceName(String spaceId) async {
    final spaces = await localDataSource.getAllSpaces();
    for (final space in spaces) {
      if (space.id == spaceId) return space.name;
    }
    return spaceId;
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}