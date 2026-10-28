import 'package:recall/core/utils/day_key.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

/// Time scopes for the statistics screen, mirroring Anki's "History" selector.
enum StatisticsRange {
  week(7),
  month(30),
  quarter(90),
  year(365),
  all(0);

  const StatisticsRange(this.days);

  /// Days covered, or `0` for the whole recorded history.
  final int days;

  bool get isAll => days == 0;
}

/// Granularity of the review-history axis.
///
/// Anki widens the bucket as the selected range grows so a multi-year range
/// stays readable instead of rendering thousands of slivers.
enum BucketUnit { day, week, month }

/// Leitner state a card was in when it was answered.
///
/// Anki has four states; a Leitner deck has three meaningful ones, since there
/// is no separate relearning queue.
enum ReviewCardState {
  /// Never answered before, or still in the first house.
  fresh,

  /// In a learning house (2..maxBox).
  learning,

  /// Already graduated to the learned box.
  learned,
}

/// One bar of the review-history chart.
class ReviewBucket {
  const ReviewBucket({
    required this.start,
    required this.freshCount,
    required this.learningCount,
    required this.learnedCount,
    required this.knowCount,
    required this.dontKnowCount,
  });

  /// Local midnight of the first day in this bucket.
  final DateTime start;

  final int freshCount;
  final int learningCount;
  final int learnedCount;
  final int knowCount;
  final int dontKnowCount;

  int get total => freshCount + learningCount + learnedCount;
  int get answered => knowCount + dontKnowCount;
  int get passedCount => knowCount;

  double get passRate => answered == 0 ? 0 : knowCount / answered;

  ReviewBucket operator +(ReviewBucket other) => ReviewBucket(
        start: start,
        freshCount: freshCount + other.freshCount,
        learningCount: learningCount + other.learningCount,
        learnedCount: learnedCount + other.learnedCount,
        knowCount: knowCount + other.knowCount,
        dontKnowCount: dontKnowCount + other.dontKnowCount,
      );
}

/// One day of the future-due forecast.
class ForecastBucket {
  const ForecastBucket({
    required this.day,
    required this.dueCount,
    required this.cumulativeIfIdle,
  });

  /// Local midnight of the forecast day.
  final DateTime day;

  /// Cards that come due on [day] if everything due before it is reviewed.
  final int dueCount;

  /// Cards due on [day] if nothing at all is studied before then.
  ///
  /// Like Anki, this ignores cards that are overdue right now.
  final int cumulativeIfIdle;
}

/// One cell of the activity calendar.
class CalendarCell {
  const CalendarCell({required this.day, required this.count});

  final DateTime day;
  final int count;
}

/// One hour-of-day column of the hourly breakdown.
class HourBucket {
  const HourBucket({required this.hour, required this.knowCount, required this.dontKnowCount});

  /// Local hour of day, 0..23.
  final int hour;

  final int knowCount;
  final int dontKnowCount;

  int get total => knowCount + dontKnowCount;

  double get passRate => total == 0 ? 0 : knowCount / total;
}

/// How the current collection splits across the three Leitner states.
///
/// Every card lands in exactly one bucket, so the parts always sum to
/// [total] — the previous per-house chart silently dropped graduated cards.
class CardDistribution {
  const CardDistribution({
    required this.freshCount,
    required this.learningCount,
    required this.learnedCount,
  });

  final int freshCount;
  final int learningCount;
  final int learnedCount;

  int get total => freshCount + learningCount + learnedCount;
}

/// Everything the statistics screen renders, computed in one pass.
class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.range,
    required this.unit,
    required this.today,
    required this.rangeStartDay,
    required this.rangeEndDay,
    required this.reviewBuckets,
    required this.cumulativeAnswered,
    required this.cumulativeKnow,
    required this.hourly,
    required this.forecast,
    required this.calendar,
    required this.distribution,
    required this.dailyLoad,
    required this.overdueCount,
    required this.totalCards,
    required this.masteredCards,
    required this.maxBox,
    required this.totalReviews,
    required this.knowCount,
    required this.dontKnowCount,
    required this.currentStreak,
    required this.bestStreak,
    required this.hasHistory,
    this.todayTotal = 0,
    this.todayKnow = 0,
    this.todayDontKnow = 0,
  });

  final StatisticsRange range;
  final BucketUnit unit;

  /// Local midnight of "today", honouring [StatisticsAggregator.dayBoundary].
  final DateTime today;

  /// Inclusive day numbers bounding the review-history series.
  final int rangeStartDay;
  final int rangeEndDay;

  final List<ReviewBucket> reviewBuckets;

  /// Running totals aligned with [reviewBuckets] — the "if you keep going"
  /// shaded region in Anki.
  final List<int> cumulativeAnswered;
  final List<int> cumulativeKnow;

  final List<HourBucket> hourly;
  final List<ForecastBucket> forecast;
  final List<CalendarCell> calendar;
  final CardDistribution distribution;

  /// Anki's daily load: the mean number of reviews due per day, computed as
  /// `1/I₁ + 1/I₂ + …` over every card's interval.
  final double dailyLoad;

  /// Cards already past their due day. Kept out of [forecast] on purpose,
  /// exactly like Anki, because they distort a forward-looking estimate.
  final int overdueCount;

  final int totalCards;
  final int masteredCards;

  /// Highest learning house enabled for the space, so the UI can label the
  /// mastery threshold instead of hardcoding "house 5".
  final int maxBox;

  final int totalReviews;
  final int knowCount;
  final int dontKnowCount;
  final int currentStreak;
  final int bestStreak;
  final bool hasHistory;

  /// Reviews answered today, kept apart from the range series.
  ///
  /// Anki deliberately keeps its "Today" figures outside the selected history
  /// scope, and for the same reason: a 90-day range bundles today into a week
  /// column, so there would be no way to answer "how am I doing right now".
  final int todayTotal;
  final int todayKnow;
  final int todayDontKnow;

  int get todayAnswered => todayKnow + todayDontKnow;

  /// Share of today's answers that were right, or `null` when nothing was
  /// answered yet — a zero there would read as "you got everything wrong".
  double? get todayKnowRate =>
      todayAnswered == 0 ? null : todayKnow / todayAnswered;

  int get answeredReviews => knowCount + dontKnowCount;

  double get knowRate => answeredReviews == 0 ? 0 : knowCount / answeredReviews;

  double get masteryProgress => totalCards == 0 ? 0 : masteredCards / totalCards;

  int get answeredInRange => cumulativeAnswered.isEmpty
      ? 0
      : cumulativeAnswered.last;
}

/// Pure statistics computation — no Flutter, no database.
///
/// Taking the cards, logs and Leitner layout as inputs keeps every derived
/// number in the app traceable to one implementation, so the forecast chart,
/// the due-day chips and the deck list cannot drift apart again.
class StatisticsAggregator {
  const StatisticsAggregator({
    required this.cards,
    required this.logs,
    required this.boxes,
    required this.now,
    this.dayBoundary = Duration.zero,
    this.forecastDays = 30,
    this.calendarDays = 365,
  });

  final List<Flashcard> cards;
  final List<ReviewLog> logs;
  final LeitnerBoxConfig boxes;
  final DateTime now;

  /// Anki's "day starts at"; zero means local midnight.
  final Duration dayBoundary;

  /// How many days the future-due chart projects forward.
  ///
  /// The old chart was hardcoded to 7 days and silently discarded everything
  /// scheduled further out, which is exactly where the 6–8 houses live.
  final int forecastDays;

  /// Length of the activity calendar in days.
  final int calendarDays;

  StatisticsSnapshot build({StatisticsRange range = StatisticsRange.month}) {
    final today = dayStartWithBoundary(now, dayBoundary);
    final todayNum = dayNumber(today);

    final activeDays = _activeLogDays();
    final firstLogDay = activeDays.isEmpty ? todayNum : activeDays.first;

    var startDay = range.isAll ? firstLogDay : todayNum - (range.days - 1);
    if (startDay > todayNum) startDay = todayNum;

    final unit = _unitFor(todayNum - startDay + 1);
    final buckets = _buildReviewBuckets(startDay, todayNum, unit);
    final cumulative = _buildCumulative(buckets);
    final streaks = _calculateStreaks(activeDays, todayNum);
    final totals = _reviewTotals(startDay, todayNum);
    final todayTotals = _reviewTotals(todayNum, todayNum);

    return StatisticsSnapshot(
      range: range,
      unit: unit,
      today: today,
      rangeStartDay: startDay,
      rangeEndDay: todayNum,
      reviewBuckets: buckets,
      cumulativeAnswered: cumulative.answered,
      cumulativeKnow: cumulative.know,
      hourly: _buildHourly(startDay, todayNum),
      forecast: _buildForecast(today),
      calendar: _buildCalendar(today),
      distribution: _buildDistribution(),
      dailyLoad: _dailyLoad(),
      overdueCount: _overdueCount(today),
      totalCards: cards.length,
      masteredCards: cards.where((card) => boxes.isLearnedBox(card.box)).length,
      maxBox: boxes.maxBox,
      totalReviews: totals.total,
      knowCount: totals.know,
      dontKnowCount: totals.dontKnow,
      currentStreak: streaks.current,
      bestStreak: streaks.best,
      hasHistory: activeDays.isNotEmpty,
      todayTotal: todayTotals.total,
      todayKnow: todayTotals.know,
      todayDontKnow: todayTotals.dontKnow,
    );
  }

  BucketUnit _unitFor(int span) {
    if (span <= 62) return BucketUnit.day;
    if (span <= 400) return BucketUnit.week;
    return BucketUnit.month;
  }

  /// Sorted, de-duplicated day numbers that actually contain reviews.
  ///
  /// Timestamps ahead of today are clamped to today rather than dropped: a
  /// backwards clock adjustment should not erase history, and the old code
  /// discarded those reviews without any trace.
  List<int> _activeLogDays() {
    final todayNum = dayNumber(dayStartWithBoundary(now, dayBoundary));
    final days = <int>{};
    for (final log in logs) {
      final day = dayNumberWithBoundary(log.reviewedAt, dayBoundary);
      days.add(day > todayNum ? todayNum : day);
    }
    final sorted = days.toList()..sort();
    return sorted;
  }

  /// The day number a log counts towards, clamped into the past.
  int _effectiveDay(ReviewLog log, int todayNum) {
    final day = dayNumberWithBoundary(log.reviewedAt, dayBoundary);
    return day > todayNum ? todayNum : day;
  }

  List<ReviewBucket> _buildReviewBuckets(int startDay, int todayNum, BucketUnit unit) {
    final weekOrigin = startDay - (weekdayOfDayNumber(startDay) - 1);
    final monthOrigin = _monthIndex(startDay);
    final todayMonth = _monthIndex(todayNum);

    final count = switch (unit) {
      BucketUnit.day => todayNum - startDay + 1,
      BucketUnit.week => (todayNum - weekOrigin) ~/ 7 + 1,
      BucketUnit.month => todayMonth - monthOrigin + 1,
    };

    final buckets = <ReviewBucket>[];
    for (var index = 0; index < count; index++) {
      buckets.add(
        ReviewBucket(
          start: _bucketStart(index, startDay, weekOrigin, unit),
          freshCount: 0,
          learningCount: 0,
          learnedCount: 0,
          knowCount: 0,
          dontKnowCount: 0,
        ),
      );
    }

    for (final log in logs) {
      final day = _effectiveDay(log, todayNum);
      if (day < startDay || day > todayNum) continue;

      final index = switch (unit) {
        BucketUnit.day => day - startDay,
        BucketUnit.week => (day - weekOrigin) ~/ 7,
        BucketUnit.month => _monthIndex(day) - monthOrigin,
      };
      if (index < 0 || index >= buckets.length) continue;

      final current = buckets[index];
      buckets[index] = ReviewBucket(
        start: current.start,
        freshCount:
            current.freshCount + (_stateFor(log.boxBefore) == ReviewCardState.fresh ? 1 : 0),
        learningCount: current.learningCount +
            (_stateFor(log.boxBefore) == ReviewCardState.learning ? 1 : 0),
        learnedCount: current.learnedCount +
            (_stateFor(log.boxBefore) == ReviewCardState.learned ? 1 : 0),
        knowCount: current.knowCount + (log.rating == ReviewRating.know ? 1 : 0),
        dontKnowCount:
            current.dontKnowCount + (log.rating == ReviewRating.dontKnow ? 1 : 0),
      );
    }

    return buckets;
  }

  DateTime _bucketStart(int index, int startDay, int weekOrigin, BucketUnit unit) {
    switch (unit) {
      case BucketUnit.day:
        return dateFromDayNumber(startDay + index);
      case BucketUnit.week:
        return dateFromDayNumber(weekOrigin + index * 7);
      case BucketUnit.month:
        final origin = dateFromDayNumber(startDay);
        return DateTime(origin.year + index ~/ 12, origin.month + index % 12);
    }
  }

  /// Months between year 0 and the month containing [dayNumber].
  int _monthIndex(int dayNumber) {
    final date = dateFromDayNumber(dayNumber);
    return date.year * 12 + date.month;
  }

  ({List<int> answered, List<int> know}) _buildCumulative(
    List<ReviewBucket> buckets,
  ) {
    final answered = List<int>.filled(buckets.length, 0);
    final know = List<int>.filled(buckets.length, 0);
    var runningAnswered = 0;
    var runningKnow = 0;
    for (var index = 0; index < buckets.length; index++) {
      runningAnswered += buckets[index].answered;
      runningKnow += buckets[index].knowCount;
      answered[index] = runningAnswered;
      know[index] = runningKnow;
    }
    return (answered: answered, know: know);
  }

  List<HourBucket> _buildHourly(int startDay, int todayNum) {
    final know = List<int>.filled(24, 0);
    final dontKnow = List<int>.filled(24, 0);

    for (final log in logs) {
      final day = _effectiveDay(log, todayNum);
      if (day < startDay || day > todayNum) continue;
      final hour = _localHour(log.reviewedAt);
      if (log.rating == ReviewRating.know) {
        know[hour]++;
      } else {
        dontKnow[hour]++;
      }
    }

    return [
      for (var hour = 0; hour < 24; hour++)
        HourBucket(hour: hour, knowCount: know[hour], dontKnowCount: dontKnow[hour]),
    ];
  }

  /// Anki measures the day boundary before applying it, so the hour axis
  /// stays on the familiar 0..23 clock the user sees everywhere else.
  int _localHour(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    final hour = local.hour - dayBoundary.inHours;
    return ((hour % 24) + 24) % 24;
  }

  List<ForecastBucket> _buildForecast(DateTime today) {
    final perDay = List<int>.filled(forecastDays, 0);

    for (final card in cards) {
      if (boxes.isLearnedBox(card.box)) continue;
      final daysAway = daysBetween(today, nextReviewDate(card, boxes: boxes));
      if (daysAway <= 0) continue;
      if (daysAway >= forecastDays) continue;
      perDay[daysAway]++;
    }

    var cumulative = 0;
    return [
      for (var offset = 0; offset < forecastDays; offset++)
        () {
          cumulative += perDay[offset];
          return ForecastBucket(
            day: addDays(today, offset),
            dueCount: perDay[offset],
            cumulativeIfIdle: cumulative,
          );
        }(),
    ];
  }

  int _overdueCount(DateTime today) {
    var overdue = 0;
    for (final card in cards) {
      if (boxes.isLearnedBox(card.box)) continue;
      if (nextReviewDate(card, boxes: boxes).isBefore(today)) overdue++;
    }
    return overdue;
  }

  /// Anki's daily load: `1/I₁ + 1/I₂ + …`, where terms shorter than a day
  /// count as 1 so that fresh cards cannot dominate the average.
  ///
  /// Graduated cards are excluded because this app never reschedules them.
  double _dailyLoad() {
    var load = 0.0;
    for (final card in cards) {
      if (boxes.isLearnedBox(card.box)) continue;
      final interval = boxes.intervalDays(card.box);
      load += interval < 1 ? 1 : 1 / interval;
    }
    return load;
  }

  List<CalendarCell> _buildCalendar(DateTime today) {
    final todayNum = dayNumber(today);
    final counts = List<int>.filled(calendarDays, 0);

    for (final log in logs) {
      final day = _effectiveDay(log, todayNum);
      final offset = todayNum - day;
      if (offset < 0 || offset >= calendarDays) continue;
      counts[calendarDays - 1 - offset]++;
    }

    return [
      for (var offset = 0; offset < calendarDays; offset++)
        CalendarCell(
          day: addDays(today, -(calendarDays - 1 - offset)),
          count: counts[offset],
        ),
    ];
  }

  CardDistribution _buildDistribution() {
    var fresh = 0;
    var learning = 0;
    var learned = 0;

    for (final card in cards) {
      switch (_stateFor(card.box)) {
        case ReviewCardState.fresh:
          fresh++;
        case ReviewCardState.learning:
          learning++;
        case ReviewCardState.learned:
          learned++;
      }
    }

    return CardDistribution(
      freshCount: fresh,
      learningCount: learning,
      learnedCount: learned,
    );
  }

  ReviewCardState _stateFor(int box) {
    if (box > boxes.maxBox) return ReviewCardState.learned;
    if (box <= 1) return ReviewCardState.fresh;
    return ReviewCardState.learning;
  }

  ({int total, int know, int dontKnow}) _reviewTotals(int startDay, int todayNum) {
    var total = 0;
    var know = 0;
    var dontKnow = 0;
    for (final log in logs) {
      final day = _effectiveDay(log, todayNum);
      if (day < startDay || day > todayNum) continue;
      total++;
      if (log.rating == ReviewRating.know) {
        know++;
      } else {
        dontKnow++;
      }
    }
    return (total: total, know: know, dontKnow: dontKnow);
  }

  ({int current, int best}) _calculateStreaks(List<int> activeDays, int todayNum) {
    if (activeDays.isEmpty) return (current: 0, best: 0);

    var best = 1;
    var run = 1;
    for (var index = 1; index < activeDays.length; index++) {
      if (activeDays[index] - activeDays[index - 1] == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }

    final latestDistance = todayNum - activeDays.last;
    // A streak stays alive if the last study day was today or yesterday.
    if (latestDistance > 1 || latestDistance < 0) return (current: 0, best: best);

    var current = 1;
    for (var index = activeDays.length - 1; index > 0; index--) {
      if (activeDays[index] - activeDays[index - 1] != 1) break;
      current++;
    }

    return (current: current, best: best);
  }
}