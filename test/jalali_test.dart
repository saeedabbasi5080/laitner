import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/core/utils/jalali.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';
import 'package:shamsi_date/shamsi_date.dart';

ReviewLog _log(DateTime at) => ReviewLog(
  id: '${at.microsecondsSinceEpoch}',
  spaceId: 's',
  cardId: 'c',
  deckId: 'd',
  rating: ReviewRating.know,
  boxBefore: 1,
  boxAfter: 2,
  reviewedAt: at,
);

void main() {
  group('Persian dates', () {
    test('day and month', () {
      expect(jalaliDayMonth(DateTime(2026, 3, 21)), '1/1'); // Nowruz 1405
      expect(jalaliDayMonth(DateTime(2026, 11, 5)), '14/8'); // 14 Aban
    });

    test('month and year', () {
      expect(jalaliMonthYear(DateTime(2026, 11, 5)), '8/05');
    });

    test('a month index round-trips to the 1st of that month', () {
      final index = jalaliMonthIndex(DateTime(2026, 11, 5));
      final start = Jalali.fromDateTime(jalaliMonthStart(index));
      expect((start.year, start.month, start.day), (1405, 8, 1));
      expect(jalaliMonthIndex(jalaliMonthStart(index + 1)), index + 1);
    });

    test('weeks start on Saturday', () {
      final saturday = DateTime(2026, 11, 7);
      expect(saturday.weekday, DateTime.saturday);
      expect(daysSinceSaturday(dayNumber(saturday)), 0);
      expect(daysSinceSaturday(dayNumber(DateTime(2026, 11, 8))), 1); // Sunday
      expect(daysSinceSaturday(dayNumber(DateTime(2026, 11, 13))), 6); // Friday
    });
  });

  group('the review chart', () {
    test('weekly bars start on Saturday', () {
      final now = DateTime(2026, 11, 5, 12);
      final snapshot = StatisticsAggregator(
        cards: const [],
        logs: [_log(now.subtract(const Duration(days: 40)))],
        boxes: LeitnerBoxConfig.classic,
        now: now,
      ).build(range: StatisticsRange.quarter);

      expect(snapshot.unit, BucketUnit.week);
      for (final bucket in snapshot.reviewBuckets) {
        expect(bucket.start.weekday, DateTime.saturday);
      }
    });

    test('monthly bars are Persian months', () {
      final now = DateTime(2026, 11, 5, 12);
      final snapshot = StatisticsAggregator(
        cards: const [],
        logs: [
          _log(DateTime(2024, 6, 1)),
          // 23 October 2026 is 1 Aban 1405; 22 October is still Mehr.
          _log(DateTime(2026, 10, 22, 10)),
          _log(DateTime(2026, 10, 23, 10)),
        ],
        boxes: LeitnerBoxConfig.classic,
        now: now,
      ).build(range: StatisticsRange.all);

      expect(snapshot.unit, BucketUnit.month);
      for (final bucket in snapshot.reviewBuckets) {
        expect(Jalali.fromDateTime(bucket.start).day, 1);
      }
      final aban = snapshot.reviewBuckets.last;
      expect(Jalali.fromDateTime(aban.start).month, 8);
      expect(aban.total, 1, reason: 'only the review on 1 Aban is in Aban');
    });
  });
}
