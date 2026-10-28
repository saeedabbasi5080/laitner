import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/repositories/review_history_repository_impl.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_local_data_source.dart';

/// Local midnight on a Wednesday, so weekday arithmetic is easy to reason about.
final _today = DateTime(2026, 3, 11);
final _yesterday = addDays(_today, -1);

Flashcard _card({
  required String id,
  int box = 1,
  DateTime? lastReviewed,
}) {
  return Flashcard(
    id: id,
    deckId: 'd1',
    front: id,
    back: id,
    box: box,
    lastReviewed: lastReviewed,
    createdAt: lastReviewed ?? _today,
  );
}

ReviewLog _log(
  String id,
  ReviewRating rating,
  DateTime reviewedAt, {
  int boxBefore = 1,
  String spaceId = 'space-1',
}) {
  return ReviewLog(
    id: id,
    spaceId: spaceId,
    cardId: 'card-$id',
    deckId: 'd1',
    rating: rating,
    boxBefore: boxBefore,
    boxAfter: rating == ReviewRating.know ? boxBefore + 1 : 1,
    reviewedAt: reviewedAt,
  );
}

StatisticsAggregator _aggregator({
  List<Flashcard> cards = const [],
  List<ReviewLog> logs = const [],
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
  DateTime? now,
  int calendarDays = 365,
}) {
  return StatisticsAggregator(
    cards: cards,
    logs: logs,
    boxes: boxes,
    now: now ?? _today,
    calendarDays: calendarDays,
  );
}

void main() {
  group('card distribution', () {
    test('counts every card, including graduated ones', () {
      // A card in the learned box used to be missing from the chart entirely,
      // so the parts never added up to the collection size.
      final snapshot = _aggregator(
        cards: [
          _card(id: 'a', box: 1),
          _card(id: 'b', box: 3),
          _card(id: 'c', box: 5),
          _card(id: 'd', box: 6),
        ],
      ).build();

      final distribution = snapshot.distribution;
      expect(distribution.freshCount, 1);
      expect(distribution.learningCount, 2);
      expect(distribution.learnedCount, 1);
      expect(distribution.total, snapshot.totalCards);
      expect(snapshot.totalCards, 4);
    });

    test('honours extra houses instead of assuming house 5', () {
      const sixHouses = LeitnerBoxConfig(box6Enabled: true);

      final snapshot = _aggregator(
        cards: [_card(id: 'a', box: 6)],
        boxes: sixHouses,
      ).build();

      // Box 6 is still a learning house when the space enables it.
      expect(snapshot.maxBox, 6);
      expect(snapshot.distribution.learnedCount, 0);
      expect(snapshot.distribution.learningCount, 1);
      expect(snapshot.masteredCards, 0);
    });
  });

  group('future due forecast', () {
    test('keeps cards scheduled beyond the first week', () {
      // House 8 can hold a 25 day gap, so a card reviewed ten days ago is due
      // fifteen days out. The old chart cut off at seven days and dropped it.
      const deepHouses = LeitnerBoxConfig(
        box6Enabled: true,
        box7Enabled: true,
        box8Enabled: true,
        box8Days: 25,
      );

      final snapshot = _aggregator(
        cards: [
          _card(id: 'a', box: 8, lastReviewed: addDays(_today, -10)),
        ],
        boxes: deepHouses,
      ).build();

      expect(snapshot.overdueCount, 0);
      expect(snapshot.forecast, hasLength(30));
      expect(snapshot.forecast[15].dueCount, 1);
      // Nothing lands in the first week, which is what used to hide it.
      expect(
        snapshot.forecast.take(7).fold<int>(0, (sum, day) => sum + day.dueCount),
        0,
      );
    });

    test('excludes overdue cards, matching how Anki reads its forecast', () {
      final snapshot = _aggregator(
        cards: [_card(id: 'a', box: 1, lastReviewed: addDays(_today, -10))],
      ).build();

      expect(snapshot.overdueCount, 1);
      expect(snapshot.forecast.first.dueCount, 0);
    });

    test('cumulative column is the running total of the bars', () {
      final snapshot = _aggregator(
        cards: [
          _card(id: 'a', box: 1, lastReviewed: addDays(_today, -2)),
          _card(id: 'b', box: 2, lastReviewed: addDays(_today, -1)),
        ],
      ).build();

      var running = 0;
      for (final day in snapshot.forecast) {
        running += day.dueCount;
        expect(day.cumulativeIfIdle, running);
      }
    });

    test('daily load sums 1/interval and ignores graduated cards', () {
      final snapshot = _aggregator(
        cards: [
          // Interval 1 day.
          _card(id: 'a', box: 1),
          // Interval 10 days from a house-5 card (boxIntervalsDays[5] = 16).
          _card(id: 'b', box: 5),
          // Graduated: never scheduled again, so it must not contribute.
          _card(id: 'c', box: 6),
        ],
      ).build();

      expect(snapshot.dailyLoad, closeTo(1 + 1 / 16, 1e-9));
    });
  });

  group('review history', () {
    test('splits buckets by the state the card was in when answered', () {
      final snapshot = _aggregator(
        logs: [
          _log('a', ReviewRating.know, _today, boxBefore: 1),
          _log('b', ReviewRating.know, _today, boxBefore: 3),
          _log('c', ReviewRating.dontKnow, _today, boxBefore: 7),
        ],
      ).build();

      final todayBucket = snapshot.reviewBuckets.last;
      expect(todayBucket.freshCount, 1);
      expect(todayBucket.learningCount, 1);
      expect(todayBucket.learnedCount, 1);
      expect(todayBucket.total, 3);
      expect(todayBucket.answered, 3);
      expect(todayBucket.passRate, closeTo(2 / 3, 1e-9));
    });

    test('cumulative pass rate matches the running totals', () {
      final snapshot = _aggregator(
        logs: [
          _log('a', ReviewRating.know, addDays(_today, -2)),
          _log('b', ReviewRating.dontKnow, addDays(_today, -1)),
          _log('c', ReviewRating.know, _today),
        ],
      ).build(range: StatisticsRange.week);

      expect(snapshot.cumulativeAnswered.last, 3);
      expect(snapshot.cumulativeKnow.last, 2);
    });

    test('honours the selected range', () {
      final logs = [
        _log('old', ReviewRating.know, addDays(_today, -40)),
        _log('new', ReviewRating.know, _today),
      ];

      final week = _aggregator(logs: logs).build(range: StatisticsRange.week);
      final all = _aggregator(logs: logs).build(range: StatisticsRange.all);

      expect(week.totalReviews, 1);
      expect(all.totalReviews, 2);
    });

    test('widens the bucket unit as the range grows', () {
      final logs = [
        for (var offset = 0; offset < 200; offset++)
          _log('l$offset', ReviewRating.know, addDays(_today, -offset)),
      ];

      expect(
        _aggregator(logs: logs).build(range: StatisticsRange.week).unit,
        BucketUnit.day,
      );
      expect(
        _aggregator(logs: logs).build(range: StatisticsRange.year).unit,
        BucketUnit.week,
      );
    });

    test('buckets stay inside the requested window', () {
      final snapshot = _aggregator(
        logs: [_log('a', ReviewRating.know, _today)],
      ).build(range: StatisticsRange.week);

      expect(snapshot.reviewBuckets, hasLength(7));
      expect(
        snapshot.reviewBuckets.first.start,
        dateFromDayNumber(snapshot.rangeStartDay),
      );
      expect(
        snapshot.reviewBuckets.last.start.isAfter(snapshot.today),
        isFalse,
      );
      for (final bucket in snapshot.reviewBuckets) {
        expect(bucket.start.isBefore(dateFromDayNumber(snapshot.rangeStartDay)),
            isFalse);
      }
    });
  });

  group('resilience', () {
    test('reviews dated in the future are clamped instead of discarded', () {
      final snapshot = _aggregator(
        logs: [
          _log('a', ReviewRating.know, _today),
          _log('b', ReviewRating.know, addDays(_today, 5)),
        ],
      ).build();

      expect(snapshot.totalReviews, 2);
      expect(snapshot.reviewBuckets.last.total, 2);
    });

    test('an empty collection produces an empty, non-crashing snapshot', () {
      final snapshot = _aggregator().build();

      expect(snapshot.totalCards, 0);
      expect(snapshot.totalReviews, 0);
      expect(snapshot.masteryProgress, 0);
      expect(snapshot.knowRate, 0);
      expect(snapshot.dailyLoad, 0);
      expect(snapshot.currentStreak, 0);
      expect(snapshot.hasHistory, isFalse);
      expect(snapshot.reviewBuckets.every((bucket) => bucket.total == 0), isTrue);
    });
  });

  group('streaks', () {
    test('counts consecutive days up to today', () {
      final snapshot = _aggregator(
        logs: [
          _log('a', ReviewRating.know, _today),
          _log('b', ReviewRating.know, _yesterday),
          _log('c', ReviewRating.know, addDays(_today, -2)),
        ],
      ).build();

      expect(snapshot.currentStreak, 3);
      expect(snapshot.bestStreak, 3);
    });

    test('survives a rest day only if the last study was today or yesterday', () {
      final twoDaysAgo = _aggregator(
        logs: [_log('a', ReviewRating.know, addDays(_today, -2))],
      ).build();
      expect(twoDaysAgo.currentStreak, 0);
      expect(twoDaysAgo.bestStreak, 1);

      final yesterdayOnly = _aggregator(
        logs: [_log('a', ReviewRating.know, _yesterday)],
      ).build();
      expect(yesterdayOnly.currentStreak, 1);
    });

    test('best streak survives a later break', () {
      final snapshot = _aggregator(
        logs: [
          _log('a', ReviewRating.know, addDays(_today, -10)),
          _log('b', ReviewRating.know, addDays(_today, -9)),
          _log('c', ReviewRating.know, addDays(_today, -8)),
          _log('d', ReviewRating.know, _today),
        ],
      ).build();

      expect(snapshot.currentStreak, 1);
      expect(snapshot.bestStreak, 3);
    });
  });

  group('hourly breakdown', () {
    test('buckets reviews by local hour', () {
      final snapshot = _aggregator(
        logs: [
          _log('a', ReviewRating.know, DateTime(2026, 3, 11, 9, 30)),
          _log('b', ReviewRating.dontKnow, DateTime(2026, 3, 11, 9, 45)),
          _log('c', ReviewRating.know, DateTime(2026, 3, 11, 21, 5)),
        ],
      ).build();

      expect(snapshot.hourly, hasLength(24));
      expect(snapshot.hourly[9].total, 2);
      expect(snapshot.hourly[9].passRate, closeTo(0.5, 1e-9));
      expect(snapshot.hourly[21].total, 1);
      expect(snapshot.hourly[0].total, 0);
    });
  });

  group('activity calendar', () {
    test('covers one year and marks today', () {
      final snapshot = _aggregator(
        logs: [_log('a', ReviewRating.know, _today)],
      ).build();

      expect(snapshot.calendar, hasLength(365));
      expect(snapshot.calendar.last.day, _today);
      expect(snapshot.calendar.last.count, 1);
      expect(
        snapshot.calendar
            .where((cell) => cell.count > 0)
            .length,
        1,
      );
    });
  });

  group('StatisticsCubit', () {
    late InMemoryLocalDataSource local;
    late SpaceSettingsStore settingsStore;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      local = InMemoryLocalDataSource();
      settingsStore = SpaceSettingsStore(prefs);
    });

    test('loads a snapshot and reports total history independently of range',
        () async {
      // The cubit reads the real clock, so anchor the fixtures to it.
      final now = DateTime.now();
      local.reviewLogs.addAll([
        _log('old', ReviewRating.know, addDays(now, -40)),
        _log('new', ReviewRating.dontKnow, addDays(now, -1)),
      ]);

      final cubit = StatisticsCubit(
        _FakeFlashcardRepository([_card(id: 'a')]),
        ReviewHistoryRepositoryImpl(local),
        'space-1',
        settingsStore,
      );

      await cubit.load();
      expect(cubit.state.status, StatisticsStatus.loaded);
      expect(cubit.state.snapshot!.totalReviews, 1);
      expect(cubit.state.historyCount, 2);
      expect(cubit.state.hasHistory, isTrue);

      // Widening the range must pick up the older review.
      await cubit.setRange(StatisticsRange.all);
      expect(cubit.state.snapshot!.totalReviews, 2);
      expect(cubit.state.historyCount, 2);

      await cubit.close();
    });

    test('an error keeps the cubit recoverable on retry', () async {
      final cubit = StatisticsCubit(
        _ThrowingFlashcardRepository(),
        ReviewHistoryRepositoryImpl(local),
        'space-1',
        settingsStore,
      );

      await cubit.load();
      expect(cubit.state.status, StatisticsStatus.error);
      expect(cubit.state.errorMessage, isNotNull);

      await cubit.close();
    });
  });
}

class _FakeFlashcardRepository implements IFlashcardRepository {
  _FakeFlashcardRepository(this.cards);

  final List<Flashcard> cards;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => cards;

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;
}

class _ThrowingFlashcardRepository implements IFlashcardRepository {
  @override
  Future<List<Flashcard>> getAllCards() async => throw StateError('boom');

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async =>
      throw StateError('boom');

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      throw StateError('boom');

  @override
  Future<Flashcard> addCard(Flashcard card) async => throw StateError('boom');

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<Flashcard> updateCard(Flashcard card) async => throw StateError('boom');
}