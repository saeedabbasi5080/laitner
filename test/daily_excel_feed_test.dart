import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/usecases/build_daily_excel_feed_plan.dart';

final _day0 = DateTime(2026, 3, 1);

ExcelImport _import(
  String id, {
  int rows = 5,
  int alreadyAdded = 0,
  int daysAfterCreation = 0,
}) {
  return ExcelImport(
    id: id,
    spaceId: 's1',
    fileName: '$id.xlsx',
    createdAt: _day0.add(Duration(days: daysAfterCreation)),
    rows: [
      for (var i = 0; i < rows; i++)
        ExcelImportRow(
          id: '$id-r$i',
          front: 'w$i',
          back: 'b$i',
          isAdded: i < alreadyAdded,
        ),
    ],
  );
}

void main() {
  const planner = BuildDailyExcelFeedPlan();

  group('the daily cap', () {
    test('releases at most one day’s worth of rows', () {
      final plan = planner(
        imports: [_import('a', rows: 500)],
        dailyLimit: 200,
        todayDay: 1,
      );

      expect(plan.totalPlanned, 200);
      expect(plan.backlog, 500);
      expect(plan.limitReached, isTrue);
    });

    test('releases everything when the file fits inside the cap', () {
      final plan = planner(
        imports: [_import('a', rows: 30)],
        dailyLimit: 200,
        todayDay: 1,
      );

      expect(plan.totalPlanned, 30);
      expect(plan.limitReached, isFalse);
    });

    test('a smaller cap releases only that many', () {
      final plan = planner(
        imports: [_import('a', rows: 50)],
        dailyLimit: 10,
        todayDay: 1,
      );

      expect(plan.totalPlanned, 10);
      expect(plan.backlog, 50);
    });

    test('rows already added are never re-released', () {
      final plan = planner(
        imports: [_import('a', rows: 10, alreadyAdded: 4)],
        dailyLimit: 200,
        todayDay: 1,
      );

      expect(plan.backlog, 6);
      expect(plan.totalPlanned, 6);
    });

    test('the default cap is 200', () {
      expect(DailyExcelFeedSettings.defaultDailyLimit, 200);
      expect(const DailyExcelFeedSettings().dailyLimit, 200);
    });

    test('an absurd cap is clamped so one run cannot flood a deck', () {
      final plan = planner(
        imports: [_import('a', rows: 10)],
        dailyLimit: 99999999,
        todayDay: 1,
      );

      expect(plan.totalPlanned, 10);
    });

    test('a limit of zero releases nothing rather than everything', () {
      final plan = planner(
        imports: [_import('a', rows: 100)],
        dailyLimit: 0,
        todayDay: 1,
      );

      expect(plan.totalPlanned, 0);
      expect(plan.backlog, 100);
    });
  });

  group('gradual catch-up', () {
    test('a week away still releases only one day’s allowance', () {
      final plan = planner(
        imports: [_import('a', rows: 1000)],
        dailyLimit: 200,
        lastRunDay: 1,
        todayDay: 8,
      );

      // Not 1400, and not 1000: one chunk, and the rest waits.
      expect(plan.totalPlanned, 200);
      expect(plan.daysSinceLastRun, 7);
      expect(plan.limitReached, isTrue);
    });

    test('running again the next day releases the next chunk', () {
      final feed = [_import('a', rows: 1000)];
      final first = planner(
        imports: feed,
        dailyLimit: 200,
        lastRunDay: null,
        todayDay: 1,
      );
      expect(first.totalPlanned, 200);

      // Mark the first chunk as added, as the writer would.
      final after = [
        ExcelImport(
          id: 'a',
          spaceId: 's1',
          fileName: 'a.xlsx',
          createdAt: _day0,
          rows: [
            for (var i = 0; i < 1000; i++)
              ExcelImportRow(
                id: 'a-r$i',
                front: 'w$i',
                back: 'b$i',
                isAdded: i < first.totalPlanned,
              ),
          ],
        ),
      ];

      final second = planner(
        imports: after,
        dailyLimit: 200,
        lastRunDay: 1,
        todayDay: 2,
      );
      expect(second.totalPlanned, 200);
      expect(second.backlog, 800);

      // Draining the whole backlog takes as many runs as the cap implies.
      var remaining = after;
      var lastRunDay = 1;
      var runs = 1;
      var added = first.totalPlanned;
      while (added < 1000) {
        final chunk = planner(
          imports: remaining,
          dailyLimit: 200,
          lastRunDay: lastRunDay,
          todayDay: lastRunDay + 1,
        );
        if (chunk.isEmpty) break;
        added += chunk.totalPlanned;
        lastRunDay++;
        runs++;
      }
      expect(added, 1000);
      expect(runs, 5, reason: '200 a day drains 1000 rows in five runs');
    });

    test('a clock moved backwards does not hand out a second allowance', () {
      final plan = planner(
        imports: [_import('a', rows: 500)],
        dailyLimit: 200,
        lastRunDay: 10,
        todayDay: 3,
      );

      expect(plan.totalPlanned, 0);
      expect(plan.alreadyRanToday, isTrue);
    });

    test('a feed that never ran reports no elapsed days', () {
      final plan = planner(
        imports: [_import('a', rows: 5)],
        dailyLimit: 200,
        todayDay: 1,
      );

      expect(plan.daysSinceLastRun, isNull);
    });
  });

  group('one run per day', () {
    test('a second run on the same day releases nothing', () {
      final plan = planner(
        imports: [_import('a', rows: 500)],
        dailyLimit: 200,
        lastRunDay: 5,
        todayDay: 5,
      );

      expect(plan.totalPlanned, 0);
      expect(plan.alreadyRanToday, isTrue);
      expect(plan.backlog, 500);
    });
  });

  group('ordering across files', () {
    test('the older file is drained before the newer one', () {
      final plan = planner(
        imports: [
          _import('new', rows: 10, daysAfterCreation: 5),
          _import('old', rows: 10),
        ],
        dailyLimit: 12,
        todayDay: 1,
      );

      expect(plan.rowIdsByImport.keys, ['old', 'new']);
      expect(plan.rowIdsByImport['old'], hasLength(10),
          reason: 'the older file is emptied first');
      expect(plan.rowIdsByImport['new'], hasLength(2),
          reason: 'the remainder of the allowance goes to the newer one');
      expect(plan.totalPlanned, 12);
    });

    test('a cap smaller than the older file leaves the newer one untouched',
        () {
      final plan = planner(
        imports: [
          _import('new', rows: 10, daysAfterCreation: 5),
          _import('old', rows: 10),
        ],
        dailyLimit: 4,
        todayDay: 1,
      );

      expect(plan.rowIdsByImport.keys, ['old']);
      expect(plan.totalPlanned, 4);
    });

    test('a cap spanning files shares one allowance', () {
      final plan = planner(
        imports: [
          _import('a', rows: 10),
          _import('b', rows: 10, daysAfterCreation: 1),
        ],
        dailyLimit: 15,
        todayDay: 1,
      );

      expect(plan.rowIdsByImport['a'], hasLength(10));
      expect(plan.rowIdsByImport['b'], hasLength(5));
      expect(plan.totalPlanned, 15);
    });

    test('row order inside a file is preserved', () {
      final plan = planner(
        imports: [_import('a', rows: 3)],
        dailyLimit: 3,
        todayDay: 1,
      );

      expect(plan.rowIdsByImport['a'], ['a-r0', 'a-r1', 'a-r2']);
    });

    test('the same date does not make the order wobble between runs', () {
      final a = _import('a', rows: 3);
      final b = _import('b', rows: 3);
      final first = planner(
        imports: [b, a],
        dailyLimit: 4,
        todayDay: 1,
      );
      final second = planner(
        imports: [a, b],
        dailyLimit: 4,
        todayDay: 1,
      );

      expect(first.rowIdsByImport.keys, second.rowIdsByImport.keys);
    });
  });

  group('empty and edge cases', () {
    test('no files means nothing to do', () {
      final plan = planner(imports: const [], dailyLimit: 200, todayDay: 1);

      expect(plan.isEmpty, isTrue);
      expect(plan.backlog, 0);
      expect(plan.limitReached, isFalse);
    });

    test('a fully drained file reports no backlog', () {
      final plan = planner(
        imports: [_import('a', rows: 5, alreadyAdded: 5)],
        dailyLimit: 200,
        todayDay: 1,
      );

      expect(plan.isEmpty, isTrue);
      expect(plan.backlog, 0);
      expect(plan.limitReached, isFalse);
    });
  });

  group('settings serialisation', () {
    test('survives a JSON round trip', () {
      const feed = DailyExcelFeedSettings(
        enabled: true,
        deckId: 'd1',
        importIds: ['i1', 'i2'],
        dailyLimit: 50,
        lastRunDay: 1234,
        lastRunAdded: 50,
      );

      final restored = DailyExcelFeedSettings.fromJson(feed.toJson());

      expect(restored.enabled, isTrue);
      expect(restored.deckId, 'd1');
      expect(restored.importIds, ['i1', 'i2']);
      expect(restored.dailyLimit, 50);
      expect(restored.lastRunDay, 1234);
      expect(restored.lastRunAdded, 50);
    });

    test('a missing or malformed blob falls back to the defaults', () {
      expect(DailyExcelFeedSettings.fromJson(null).enabled, isFalse);
      expect(
        DailyExcelFeedSettings.fromJson({}).dailyLimit,
        DailyExcelFeedSettings.defaultDailyLimit,
      );
      expect(
        DailyExcelFeedSettings.fromJson({'importIds': 'nonsense'}).importIds,
        isEmpty,
      );
    });

    test('configured means on, with a deck, files and a positive cap', () {
      expect(const DailyExcelFeedSettings().isConfigured, isFalse);

      const on = DailyExcelFeedSettings(enabled: true);
      expect(on.isConfigured, isFalse, reason: 'no deck yet');
      expect(on.needsSetup, isTrue);

      const noFiles = DailyExcelFeedSettings(
        enabled: true,
        deckId: 'd1',
      );
      expect(noFiles.isConfigured, isFalse, reason: 'no files yet');

      const ready = DailyExcelFeedSettings(
        enabled: true,
        deckId: 'd1',
        importIds: ['i1'],
      );
      expect(ready.isConfigured, isTrue);
      expect(ready.needsSetup, isFalse);
    });

    test('clearing the deck id really clears it', () {
      const feed = DailyExcelFeedSettings(enabled: true, deckId: 'd1');

      // copyWith cannot pass a null deckId, so the flag exists for exactly this.
      expect(feed.copyWith(clearDeckId: true).deckId, isNull);
      expect(feed.copyWith(deckId: 'd2').deckId, 'd2');
    });
  });
}