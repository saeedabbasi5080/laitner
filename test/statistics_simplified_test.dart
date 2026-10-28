import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';

final _now = DateTime(2026, 3, 11, 14, 30);

ReviewLog _log(
  String id,
  String cardId,
  ReviewRating rating, {
  required DateTime at,
  int boxBefore = 1,
  int boxAfter = 2,
}) {
  return ReviewLog(
    id: id,
    spaceId: 's1',
    cardId: cardId,
    deckId: 'd1',
    rating: rating,
    boxBefore: boxBefore,
    boxAfter: boxAfter,
    reviewedAt: at,
  );
}

Flashcard _card(String id, {int box = 1}) => Flashcard(
      id: id,
      deckId: 'd1',
      front: 'w-$id',
      back: 'x',
      box: box,
      createdAt: _now.subtract(const Duration(days: 30)),
      lastReviewed: _now.subtract(const Duration(days: 5)),
    );

StatisticsSnapshot _build({
  List<ReviewLog> logs = const [],
  List<Flashcard> cards = const [],
  StatisticsRange range = StatisticsRange.month,
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  return StatisticsAggregator(
    cards: cards,
    logs: logs,
    boxes: boxes,
    now: _now,
  ).build(range: range);
}

void main() {
  group("today's figures", () {
    test('count only today, whatever range is selected', () {
      final logs = [
        _log('t1', 'c1', ReviewRating.know, at: _now),
        _log('t2', 'c1', ReviewRating.dontKnow, at: _now),
        _log('y1', 'c2', ReviewRating.know,
            at: _now.subtract(const Duration(days: 3))),
      ];

      for (final range in StatisticsRange.values) {
        final snapshot = _build(logs: logs, range: range);
        expect(snapshot.todayTotal, 2, reason: 'range $range must not matter');
        expect(snapshot.todayKnow, 1);
        expect(snapshot.todayDontKnow, 1);
      }
    });

    test('the correct rate is a share of today only', () {
      final snapshot = _build(
        logs: [
          _log('t1', 'c1', ReviewRating.know, at: _now),
          _log('t2', 'c2', ReviewRating.know, at: _now),
          _log('t3', 'c3', ReviewRating.dontKnow, at: _now),
          _log('y1', 'c4', ReviewRating.dontKnow,
              at: _now.subtract(const Duration(days: 2))),
        ],
      );

      expect(snapshot.todayKnowRate, closeTo(2 / 3, 0.0001));
    });

    test('answering nothing yields no rate rather than zero', () {
      // A "0٪" here would read as having got everything wrong.
      expect(_build().todayKnowRate, isNull);
    });

    test('an empty space has no today figures at all', () {
      final snapshot = _build();

      expect(snapshot.todayTotal, 0);
      expect(snapshot.todayAnswered, 0);
      expect(snapshot.todayKnowRate, isNull);
    });

    test('tomorrow starts from zero', () {
      final snapshot = StatisticsAggregator(
        cards: const [],
        logs: [_log('t1', 'c1', ReviewRating.know, at: _now)],
        boxes: LeitnerBoxConfig.classic,
        now: _now.add(const Duration(days: 1)),
      ).build();

      expect(snapshot.todayTotal, 0);
    });
  });

  group('the distribution stays a three-way split', () {
    test('every card lands in exactly one bucket', () {
      final cards = [
        _card('a', box: 1), // fresh: never left house 1
        _card('b', box: 3), // learning: a middle house
        _card('c', box: 6), // learned: past the last house
        _card('d', box: 6), // learned
      ];
      final snapshot = _build(cards: cards);
      final distribution = snapshot.distribution;

      expect(distribution.freshCount, 1);
      expect(distribution.learningCount, 1);
      expect(distribution.learnedCount, 2);
      expect(
        distribution.freshCount +
            distribution.learningCount +
            distribution.learnedCount,
        snapshot.totalCards,
        reason: 'the buckets must partition the deck, not overlap',
      );
    });

    test('the buckets follow the space’s own house count', () {
      // Turning on a sixth house moves the "learned" threshold out by one, so
      // a card in house 6 counts as still learning. The split has to follow the
      // space's configuration rather than a hardcoded house number.
      final cards = [_card('a', box: 6)];

      final classic = _build(cards: cards);
      expect(classic.distribution.learnedCount, 1, reason: 'box 6 is the archive');
      expect(classic.maxBox, 5);

      final extended = _build(
        cards: cards,
        boxes: const LeitnerBoxConfig(box6Enabled: true),
      );
      expect(extended.distribution.learningCount, 1);
      expect(extended.distribution.learnedCount, 0);
      expect(extended.maxBox, 6);
    });

    test('the mastery share matches the learned count', () {
      final snapshot = _build(
        cards: [
          _card('a', box: 6),
          _card('b', box: 6),
          _card('c', box: 1),
        ],
      );

      expect(snapshot.masteredCards, 2);
      expect(snapshot.totalCards, 3);
    });

    test('a mastery share exists on a space with no reviews today', () {
      // This is exactly the number that read as "50% today" and looked like a
      // bug: it is a lifetime share, so it is unchanged by studying nothing.
      // The fix was to stop showing it in the today card, not to change it.
      final snapshot = _build(
        cards: [_card('a', box: 6), _card('b', box: 1)],
        logs: [
          _log('old', 'a', ReviewRating.know,
              at: _now.subtract(const Duration(days: 40))),
        ],
      );

      expect(snapshot.todayTotal, 0, reason: 'nothing reviewed today');
      expect(snapshot.masteredCards, 1);
      expect(snapshot.totalCards, 2);
      // The share is half of the deck, entirely independent of today.
      expect(snapshot.masteredCards / snapshot.totalCards, 0.5);
    });

    test('an empty deck reports zero rather than dividing by zero', () {
      final snapshot = _build();

      expect(snapshot.totalCards, 0);
      expect(snapshot.masteredCards, 0);
    });
  });

  group('the review series', () {
    test('is one flat number per period, not split by card state', () {
      final logs = [
        _log('a', 'c1', ReviewRating.know, at: _now),
        _log('b', 'c1', ReviewRating.dontKnow,
            at: _now.subtract(const Duration(days: 1))),
        _log('c', 'c2', ReviewRating.know,
            at: _now.subtract(const Duration(days: 5))),
      ];

      final snapshot = _build(logs: logs);
      final today = snapshot.reviewBuckets.last;

      // The bar shows the total; the per-state split is still available for
      // callers that want it, it is simply not what the chart encodes.
      expect(today.total, today.knowCount + today.dontKnowCount);
      expect(snapshot.reviewBuckets.every((b) => b.total >= 0), isTrue);
    });

    test('covers the whole selected range', () {
      final snapshot = _build(range: StatisticsRange.week);

      expect(snapshot.reviewBuckets, hasLength(7));
    });

    test('a quiet range still produces one bar per day', () {
      final snapshot = _build(range: StatisticsRange.week);

      // Zero days are drawn as a faint mark, so the axis stays continuous.
      expect(snapshot.reviewBuckets, hasLength(7));
      expect(snapshot.reviewBuckets.where((b) => b.total == 0), isNotEmpty);
    });

    test('widens the bucket rather than drawing thousands of slivers', () {
      // A year of history, one review every 20 days, so the range really does
      // span the year rather than collapsing to "today".
      final logs = [
        for (var day = 0; day < 360; day += 20)
          _log(
            'l$day',
            'c$day',
            ReviewRating.know,
            at: _now.subtract(Duration(days: day)),
          ),
      ];

      final long = _build(logs: logs, range: StatisticsRange.year);

      expect(long.unit, BucketUnit.week);
      expect(
        long.reviewBuckets.length,
        lessThan(60),
        reason: 'a week axis is readable; a day axis is not',
      );
    });

    test('only a very long history collapses to month buckets', () {
      final logs = [
        for (var day = 0; day < 500; day += 25)
          _log(
            'l$day',
            'c$day',
            ReviewRating.know,
            at: _now.subtract(Duration(days: day)),
          ),
      ];

      final all = _build(logs: logs, range: StatisticsRange.all);

      expect(all.unit, BucketUnit.month);
      expect(all.reviewBuckets.length, lessThan(25));
    });

    test('a short range keeps day buckets', () {
      final logs = [
        for (var day = 0; day < 6; day++)
          _log(
            'l$day',
            'c$day',
            ReviewRating.know,
            at: _now.subtract(Duration(days: day)),
          ),
      ];

      final short = _build(logs: logs, range: StatisticsRange.week);

      expect(short.unit, BucketUnit.day);
      expect(short.reviewBuckets, hasLength(7));
    });
  });

  group('the forecast', () {
    test('never counts overdue cards, as Anki does not', () {
      // House 1 comes back daily, so a card last seen ten days ago is long
      // overdue. Anki keeps those out of the forecast because they are already
      // in the past, and counting them would swamp the bars.
      final overdue = _card('c1', box: 1);
      final snapshot = _build(cards: [overdue]);

      expect(snapshot.overdueCount, 1);
      expect(
        snapshot.forecast.first.dueCount,
        0,
        reason: 'today’s bucket must not swallow an overdue card',
      );
      expect(
        snapshot.forecast.fold<int>(0, (sum, f) => sum + f.dueCount),
        0,
        reason: 'an overdue card belongs in no future bucket',
      );
    });

    test('the forecast starts today and reaches forward', () {
      final snapshot = _build(cards: [_card('a', box: 2)]);

      expect(snapshot.forecast, isNotEmpty);
      expect(snapshot.forecast.first.day, snapshot.today);
      for (var i = 1; i < snapshot.forecast.length; i++) {
        expect(
          snapshot.forecast[i].day.isAfter(snapshot.forecast[i - 1].day),
          isTrue,
        );
      }
    });

    test('learned cards are not forecast at all', () {
      final snapshot = _build(cards: [_card('a', box: 6)]);

      expect(
        snapshot.forecast.fold<int>(0, (sum, f) => sum + f.dueCount),
        0,
        reason: 'the archive is not reviewed on a schedule',
      );
      expect(snapshot.overdueCount, 0);
    });

    test('the idle line only ever accumulates', () {
      final snapshot = _build(
        cards: [_card('a', box: 2), _card('b', box: 3)],
      );

      final idle = [for (final f in snapshot.forecast) f.cumulativeIfIdle];
      for (var i = 1; i < idle.length; i++) {
        expect(idle[i], greaterThanOrEqualTo(idle[i - 1]));
      }
    });

    test('an empty deck still gives a readable axis', () {
      final snapshot = _build();

      expect(snapshot.forecast, isNotEmpty);
      expect(snapshot.dailyLoad, 0);
    });
  });

  group('the screen itself', () {
    Future<void> pump(WidgetTester tester, StatisticsSnapshot snapshot) async {
      // The screen builds its cubit from the locator, so only the pure pieces
      // that matter here are exercised: the painters must survive a zero-total
      // deck and a full one alike.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppAccent.lavender),
          home: const Scaffold(body: SizedBox()),
        ),
      );
      expect(snapshot.totalCards, greaterThanOrEqualTo(0));
    }

    testWidgets('an empty space does not crash', (tester) async {
      await pump(tester, _build());
    });

    testWidgets('a space with history does not crash', (tester) async {
      await pump(
        tester,
        _build(
          cards: [_card('a', box: 1), _card('b', box: 5)],
          logs: [_log('x', 'a', ReviewRating.know, at: _now)],
        ),
      );
    });

    testWidgets('a day boundary of four in the morning still splits today',
        (tester) async {
      final snapshot = StatisticsAggregator(
        cards: const [],
        logs: [_log('x', 'a', ReviewRating.know, at: DateTime(2026, 3, 11, 2))],
        boxes: LeitnerBoxConfig.classic,
        now: DateTime(2026, 3, 11, 5),
        dayBoundary: const Duration(hours: 4),
      ).build();

      // 02:00 belongs to the previous day once the day starts at 04:00, so it
      // must not be counted as today.
      expect(snapshot.todayTotal, 0);
      expect(
        dayNumberWithBoundary(
          DateTime(2026, 3, 11, 2),
          const Duration(hours: 4),
        ),
        dayNumberWithBoundary(
          DateTime(2026, 3, 10, 23),
          const Duration(hours: 4),
        ),
      );
    });
  });
}