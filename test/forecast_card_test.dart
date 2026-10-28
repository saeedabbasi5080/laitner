import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';
import 'package:recall/presentation/widgets/forecast_card.dart';

final _now = DateTime(2026, 3, 11, 14, 30);

ReviewLog _log(String id, String cardId, ReviewRating rating, {required DateTime at}) {
  return ReviewLog(
    id: id,
    spaceId: 's1',
    cardId: cardId,
    deckId: 'd1',
    rating: rating,
    boxBefore: 1,
    boxAfter: 2,
    reviewedAt: at,
  );
}

Flashcard _card(String id, {int box = 1, int daysAgo = 2}) => Flashcard(
      id: id,
      deckId: 'd1',
      front: 'w-$id',
      back: 'x',
      box: box,
      createdAt: _now.subtract(const Duration(days: 60)),
      lastReviewed: _now.subtract(Duration(days: daysAgo)),
    );

/// Interval in days for each house, from the app's own Leitner constants.
const _intervals = [0, 1, 2, 4, 8, 16, 21, 30, 45];

/// A card whose next review falls exactly [days] from now.
///
/// Choosing the house by interval matters: picking a house and a last-reviewed
/// date independently is how a test ends up with a card that is overdue and
/// quietly absent from every forecast it is supposed to be checking.
Flashcard _dueIn(String id, int days) {
  for (var box = 1; box < _intervals.length; box++) {
    final interval = _intervals[box];
    if (interval > days) {
      return _card(id, box: box, daysAgo: interval - days);
    }
  }
  throw ArgumentError('no house reaches $days days ahead');
}

StatisticsSnapshot _build({
  List<Flashcard> cards = const [],
  List<ReviewLog> logs = const [],
}) {
  return StatisticsAggregator(
    cards: cards,
    logs: logs,
    boxes: LeitnerBoxConfig.classic,
    now: _now,
  ).build();
}

/// Cards spread across more days than the list spells out, so the summary line
/// has something to summarise.
///
/// Every offset is within sixteen days on purpose. Only houses 1–5 are still
/// being scheduled in the classic layout — house 6 and up are the learned
/// archive — and house 5 tops out at a sixteen-day interval, so a card asked to
/// be due further out than that is silently graduated and drops out of the
/// forecast entirely.
StatisticsSnapshot get busy => _build(
      cards: [
        _dueIn('a', 1),
        _dueIn('b', 1),
        _dueIn('c', 2),
        _dueIn('d', 3),
        _dueIn('e', 4),
        _dueIn('f', 5),
        _dueIn('g', 6),
        _dueIn('h', 8),
        _dueIn('i', 12),
      ],
      logs: [_log('t', 'a', ReviewRating.know, at: _now)],
    );

Widget host(StatisticsSnapshot snapshot) => MaterialApp(
      theme: AppTheme.light(AppAccent.lavender),
      home: Scaffold(
        body: SingleChildScrollView(child: UpcomingCard(snapshot: snapshot)),
      ),
    );

void main() {
  group('the day list', () {
    testWidgets('names days and shows their counts', (tester) async {
      await tester.pumpWidget(host(busy));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forecastTomorrow), findsOneWidget);
      expect(find.text(AppStrings.forecastAfterTomorrow), findsOneWidget);
      // Two cards land on tomorrow, one on the day after.
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('draws a bar per row', (tester) async {
      await tester.pumpWidget(host(busy));
      await tester.pumpAndSettle();

      // Seven days are spelled out before the rest is summarised.
      expect(find.byType(ClipRRect), findsNWidgets(UpcomingCard.shownDays));
    });

    testWidgets('leaves out days with nothing due', (tester) async {
      // One card due tomorrow only; the rest of the window is empty.
      await tester.pumpWidget(host(_build(cards: [_dueIn('a', 1)])));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forecastTomorrow), findsOneWidget);
      expect(
        find.text(AppStrings.forecastToday),
        findsNothing,
        reason: 'a row of zeroes says more about list length than about work',
      );
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('summarises the days past the visible ones', (tester) async {
      await tester.pumpWidget(host(busy));
      await tester.pumpAndSettle();

      expect(find.textContaining(AppStrings.forecastAfterThat), findsOneWidget);
    });

    testWidgets('says so when the window is empty', (tester) async {
      await tester.pumpWidget(host(_build()));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forecastNothingSoon), findsOneWidget);
      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('never shows a "today" row', (tester) async {
      // The forecast never puts anything in the leading bucket: a card already
      // due today is on the deck overview, not in a forward-looking estimate.
      await tester.pumpWidget(host(busy));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.forecastToday), findsNothing);
    });
  });

  group('the long-run average', () {
    testWidgets('is always shown', (tester) async {
      await tester.pumpWidget(host(busy));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.statsDailyLoad), findsOneWidget);
    });

    testWidgets('does not round a fraction to zero', (tester) async {
      // One card in house 2 comes back in two days, so the long-run average is
      // 0.5. Rounding that to a whole number printed "0 cards a day", which
      // reads as having nothing to do rather than as having plenty of time.
      final relaxed = _build(cards: [_dueIn('far', 1)]);

      await tester.pumpWidget(host(relaxed));
      await tester.pumpAndSettle();

      expect(relaxed.dailyLoad, lessThan(1));
      expect(
        find.text(AppStrings.forecastCardsPerDayFraction('0.5')),
        findsOneWidget,
      );
    });
  });

  group('relative day names', () {
    test('only the next two days get a relative name', () {
      final today = DateTime(2026, 3, 11);

      expect(forecastDayName(today, today), AppStrings.forecastToday);
      expect(
        forecastDayName(today.add(const Duration(days: 1)), today),
        AppStrings.forecastTomorrow,
      );
      expect(
        forecastDayName(today.add(const Duration(days: 2)), today),
        AppStrings.forecastAfterTomorrow,
      );
    });

    test('anything further out falls back to a plain date', () {
      final today = DateTime(2026, 3, 11);

      // Three weeks out is not "soon", and pretending otherwise would turn the
      // forecast into a riddle.
      expect(forecastDayName(today.add(const Duration(days: 21)), today), '1/4');
    });

    test('a day before today is still just a date', () {
      final today = DateTime(2026, 3, 11);
      expect(
        forecastDayName(today.subtract(const Duration(days: 2)), today),
        '9/3',
      );
    });
  });

  group('degrading safely', () {
    testWidgets('overdue cards are called out even with nothing due',
        (tester) async {
      // House 1 comes back daily, so a card last seen ten days ago is overdue
      // and cannot appear in the forecast. A reassuring "nothing soon" must not
      // swallow the backlog.
      final snapshot = _build(cards: [_card('old', box: 1, daysAgo: 10)]);

      await tester.pumpWidget(host(snapshot));
      await tester.pumpAndSettle();

      expect(snapshot.overdueCount, 1);
      expect(
        find.textContaining(AppStrings.statsOverdueHidden),
        findsOneWidget,
      );
      expect(find.text(AppStrings.forecastNothingSoon), findsNothing);
    });

    testWidgets('a heavy schedule overflows nothing', (tester) async {
      final many = _build(
        cards: [for (var i = 0; i < 60; i++) _dueIn('c$i', 1 + i % 25)],
      );

      await tester.pumpWidget(host(many));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a long day list is capped and does not overflow',
        (tester) async {
      // Every one of the thirty forecast days has work.
      final packed = _build(
        cards: [for (var d = 1; d <= 30; d++) for (var i = 0; i < 3; i++) _dueIn('c$d$i', d)],
      );

      await tester.pumpWidget(host(packed));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ClipRRect), findsNWidgets(UpcomingCard.shownDays));
    });
  });
}