import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

part 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit(
    this._flashcardRepository,
    this._reviewHistoryRepository,
    this._spaceId,
  ) : super(const StatisticsState());

  final IFlashcardRepository _flashcardRepository;
  final IReviewHistoryRepository _reviewHistoryRepository;
  final String _spaceId;

  Future<void> load() async {
    emit(state.copyWith(status: StatisticsStatus.loading));

    try {
      final results = await Future.wait([
        _flashcardRepository.getCardsBySpaceId(_spaceId),
        _reviewHistoryRepository.getBySpaceId(_spaceId),
      ]);
      final cards = (results[0] as List).cast<Flashcard>();
      final logs = (results[1] as List).cast<ReviewLog>();
      final now = DateTime.now();
      final today = _day(now);

      final boxCounts = {for (var box = 1; box <= maxBox; box++) box: 0};
      final futureDueCounts = List<int>.filled(7, 0);
      var masteredCards = 0;

      for (final card in cards) {
        final box = card.box;
        if (box >= 1 && box <= maxBox) {
          boxCounts[box] = (boxCounts[box] ?? 0) + 1;
        }
        if (box >= 4) masteredCards++;

        final dueDay = _day(nextReviewDate(card));
        final daysAway = dueDay.difference(today).inDays;
        if (daysAway <= 0) {
          futureDueCounts[0]++;
        } else if (daysAway < futureDueCounts.length) {
          futureDueCounts[daysAway]++;
        }
      }

      final dailyReviewCounts = List<int>.filled(7, 0);
      var knowCount = 0;
      var dontKnowCount = 0;

      for (final log in logs) {
        switch (log.rating) {
          case ReviewRating.know:
            knowCount++;
          case ReviewRating.dontKnow:
            dontKnowCount++;
        }

        final daysAgo = today.difference(_day(log.reviewedAt)).inDays;
        if (daysAgo >= 0 && daysAgo < dailyReviewCounts.length) {
          dailyReviewCounts[dailyReviewCounts.length - 1 - daysAgo]++;
        }
      }

      final streaks = _calculateStreaks(logs, today);

      emit(
        StatisticsState(
          status: StatisticsStatus.loaded,
          boxCounts: boxCounts,
          dailyReviewCounts: dailyReviewCounts,
          futureDueCounts: futureDueCounts,
          totalCards: cards.length,
          masteredCards: masteredCards,
          totalReviews: logs.length,
          knowCount: knowCount,
          dontKnowCount: dontKnowCount,
          currentStreak: streaks.current,
          bestStreak: streaks.best,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StatisticsStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  ({int current, int best}) _calculateStreaks(
    List<ReviewLog> logs,
    DateTime today,
  ) {
    if (logs.isEmpty) return (current: 0, best: 0);

    final activeDays = logs.map((log) => _day(log.reviewedAt)).toSet().toList()
      ..sort();

    var best = 1;
    var run = 1;
    for (var i = 1; i < activeDays.length; i++) {
      if (activeDays[i].difference(activeDays[i - 1]).inDays == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }

    final latest = activeDays.last;
    final latestDistance = today.difference(latest).inDays;
    if (latestDistance > 1 || latestDistance < 0) {
      return (current: 0, best: best);
    }

    var current = 1;
    for (var i = activeDays.length - 1; i > 0; i--) {
      if (activeDays[i].difference(activeDays[i - 1]).inDays != 1) break;
      current++;
    }

    return (current: current, best: best);
  }

  DateTime _day(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
