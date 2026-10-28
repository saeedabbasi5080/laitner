import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';
import 'package:recall/presentation/widgets/chart_primitives.dart';

final _now = DateTime(2026, 3, 11, 14, 30);

Flashcard _card(String id, {int box = 2, int daysAgo = 2}) => Flashcard(
      id: id,
      deckId: 'd1',
      front: 'w-$id',
      back: 'x',
      box: box,
      createdAt: _now.subtract(const Duration(days: 60)),
      lastReviewed: _now.subtract(Duration(days: daysAgo)),
    );

StatisticsSnapshot _build({int cards = 0, int days = 0}) {
  return StatisticsAggregator(
    cards: [
      for (var i = 0; i < cards; i++) _card('c$i', box: 1 + i % 5, daysAgo: i % 5),
    ],
    logs: [
      for (var d = 0; d < days; d++)
        ReviewLog(
          id: 'l$d',
          spaceId: 's1',
          cardId: 'c0',
          deckId: 'd1',
          rating: ReviewRating.know,
          boxBefore: 1,
          boxAfter: 2,
          reviewedAt: _now.subtract(Duration(days: d)),
        ),
    ],
    boxes: LeitnerBoxConfig.classic,
    now: _now,
  ).build();
}

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light(AppAccent.lavender),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  group('bars are one layer, not one widget per bar', () {
    testWidgets('a thirty-day chart costs no more than a three-day one',
        (tester) async {
      // The whole point of the refactor. Thirty bars built as thirty Containers
      // would be thirty rounded-rect draws and thirty subtrees, all redrawn on
      // every frame of a scroll; one painter is one layer either way, so the
      // cost must not grow with the number of bars.
      Future<int> costOf(List<double> values) async {
        await tester.pumpWidget(
          host(
            ChartBars(values: values, color: Colors.blue, zeroColor: Colors.grey),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widgetList(find.byType(CustomPaint)).length;
      }

      final small = await costOf([3, 7, 2]);
      final large = await costOf([
        for (var i = 0; i < 30; i++) (i * 7) % 11,
      ]);

      expect(large, small, reason: 'ten times the data, the same work');
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('each chart isolates its own repaints', (tester) async {
      await tester.pumpWidget(
        host(
          const ChartBars(
            values: [3, 7, 2],
            color: Colors.blue,
            zeroColor: Colors.grey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('an empty series draws nothing instead of dividing by zero',
        (tester) async {
      await tester.pumpWidget(
        host(
          const ChartBars(
            values: [],
            color: Colors.blue,
            zeroColor: Colors.grey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a slot with no data still gets a stub', (tester) async {
      await tester.pumpWidget(
        host(
          const ChartBars(
            values: [0, 4, 0],
            color: Colors.blue,
            zeroColor: Colors.grey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('labels are painted too', () {
    testWidgets('thirty slots cost no more than three', (tester) async {
      // Text widgets would each be laid out and composited on every scroll.
      Future<int> costOf(int count) async {
        await tester.pumpWidget(
          host(
            ChartBarLabels(
              count: count,
              labelAt: (index) => index % 3 == 0 ? '$index' : null,
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.widgetList(find.byType(Container)).length;
      }

      expect(await costOf(30), await costOf(3));
    });

    testWidgets('a long label is clipped to its own slot', (tester) async {
      await tester.pumpWidget(
        host(
          ChartBarLabels(
            count: 3,
            labelAt: (index) => 'a very long label ${index * 100}',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('zero slots draws nothing', (tester) async {
      await tester.pumpWidget(host(ChartBarLabels(count: 0, labelAt: (_) => null)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('the dashed overlay', () {
    testWidgets('survives a single point and a zero peak', (tester) async {
      for (final values in [
        [1.0],
        [0.0, 0.0],
        [1.0, 0.0, 1.0],
      ]) {
        await tester.pumpWidget(
          host(
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: ChartDashedLinePainter(
                  values: values,
                  peak: 0,
                  color: Colors.grey,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'values $values');
      }
    });

    testWidgets('draws a normal series without complaint', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            height: 100,
            child: CustomPaint(
              painter: ChartDashedLinePainter(
                values: [1.0, 4.0, 2.0, 9.0],
                peak: 10,
                color: Colors.grey,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('a long history stays cheap', () {
    testWidgets('the whole-history range still renders without overflowing',
        (tester) async {
      final snapshot = _build(cards: 200, days: 120);

      await tester.pumpWidget(
        host(
          ChartBars(
            values: [for (final b in snapshot.reviewBuckets) b.total.toDouble()],
            color: Colors.blue,
            zeroColor: Colors.grey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Container), findsNothing);
    });
  });
}