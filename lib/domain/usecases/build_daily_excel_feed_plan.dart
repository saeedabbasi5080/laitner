import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/excel_import.dart';

/// What a daily feed run should add, worked out before anything is written.
class DailyExcelFeedPlan {
  const DailyExcelFeedPlan({
    required this.rowIdsByImport,
    required this.backlog,
    required this.limitReached,
    this.daysSinceLastRun,
    this.alreadyRanToday = false,
  });

  /// Row ids to add, keyed by the import they came from.
  ///
  /// Keying rather than using a flat list keeps the writer able to reuse the
  /// existing per-file add path, which already handles duplicate detection and
  /// marks the rows as added.
  final Map<String, List<String>> rowIdsByImport;

  /// How many rows are waiting across the feed files.
  final int backlog;

  /// True when the backlog is larger than one day's allowance, so the feed has
  /// more to give tomorrow.
  final bool limitReached;

  /// Days since the last run, or null if it has never run.
  final int? daysSinceLastRun;

  /// True when the feed already ran today and the daily cap is spent.
  final bool alreadyRanToday;

  int get totalPlanned =>
      rowIdsByImport.values.fold(0, (sum, ids) => sum + ids.length);

  bool get isEmpty => totalPlanned == 0;
}

/// Decides how much of a space's queued Excel rows enter its feed deck today.
///
/// The rule that matters is that the allowance is a *daily* one: returning
/// after a week away does not release seven days' worth at once. It releases
/// one chunk and leaves the rest queued, so a backlog is worked off gradually
/// and can never flood a deck while the user was away — the same trade-off
/// Anki makes with its new-cards-per-day limit.
///
/// Pure on purpose: the arithmetic that decides what gets through is the part
/// worth testing, and it should not need a database to be exercised.
class BuildDailyExcelFeedPlan {
  const BuildDailyExcelFeedPlan();

  DailyExcelFeedPlan call({
    required List<ExcelImport> imports,
    required int dailyLimit,
    int? lastRunDay,
    int? todayDay,
  }) {
    // Oldest file first, so a long-standing feed is not starved by a file added
    // today, and ties broken by id so the order never wobbles between runs.
    final ordered = [...imports]..sort((a, b) {
        final byDate = a.createdAt.compareTo(b.createdAt);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    final pending = <({String importId, String rowId})>[];
    for (final import in ordered) {
      for (final row in import.rows) {
        if (row.isAdded) continue;
        pending.add((importId: import.id, rowId: row.id));
      }
    }

    final daysSince = _daysSince(lastRunDay, todayDay);

    // A limit of zero or less is treated as "off" rather than as an error, so a
    // corrupted settings blob cannot ask for an unlimited feed.
    if (dailyLimit <= 0 || pending.isEmpty) {
      return DailyExcelFeedPlan(
        rowIdsByImport: const {},
        backlog: pending.length,
        limitReached: pending.isNotEmpty,
        daysSinceLastRun: daysSince,
      );
    }

    // Already fed today. Comparing with >= also covers the clock being moved
    // backwards, which would otherwise hand out a second allowance.
    if (lastRunDay != null &&
        todayDay != null &&
        lastRunDay >= todayDay) {
      return DailyExcelFeedPlan(
        rowIdsByImport: const {},
        backlog: pending.length,
        limitReached: pending.length > dailyLimit,
        daysSinceLastRun: daysSince,
        alreadyRanToday: true,
      );
    }

    final allowance = dailyLimit > DailyExcelFeedSettings.maxDailyLimit
        ? DailyExcelFeedSettings.maxDailyLimit
        : dailyLimit;
    final taking = pending.length <= allowance ? pending : pending.sublist(0, allowance);

    final byImport = <String, List<String>>{};
    for (final entry in taking) {
      byImport.putIfAbsent(entry.importId, () => []).add(entry.rowId);
    }

    return DailyExcelFeedPlan(
      rowIdsByImport: byImport,
      backlog: pending.length,
      limitReached: pending.length > allowance,
      daysSinceLastRun: daysSince,
    );
  }

  int? _daysSince(int? lastRunDay, int? todayDay) {
    if (lastRunDay == null || todayDay == null) return null;
    final days = todayDay - lastRunDay;
    return days < 0 ? 0 : days;
  }
}