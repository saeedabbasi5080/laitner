import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';

part 'statistics_state.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit(
    this._flashcardRepository,
    this._reviewHistoryRepository,
    this._spaceId,
    this._spaceSettingsStore,
  ) : super(const StatisticsState());

  final IFlashcardRepository _flashcardRepository;
  final IReviewHistoryRepository _reviewHistoryRepository;
  final String _spaceId;
  final SpaceSettingsStore _spaceSettingsStore;

  /// The calendar heatmap always needs a full year of days, so the queried
  /// window is at least that wide regardless of the selected range.
  static const _calendarDays = 365;

  Future<void> load() async {
    emit(state.copyWith(status: StatisticsStatus.loading));

    try {
      final boxes = (await _spaceSettingsStore.load(_spaceId)).leitnerBoxes;
      final now = DateTime.now();

      // A record keeps the three concurrent results statically typed, which
      // `Future.wait` on a heterogeneous list cannot do.
      final (cards, logs, historyCount) = await (
        _flashcardRepository.getCardsBySpaceId(_spaceId),
        _reviewHistoryRepository.getInRange(
          spaceId: _spaceId,
          from: _windowStart(now),
          to: _windowEnd(now),
        ),
        _reviewHistoryRepository.countBySpaceId(_spaceId),
      ).wait;

      final snapshot = StatisticsAggregator(
        cards: cards,
        logs: logs,
        boxes: boxes,
        now: now,
        calendarDays: _calendarDays,
      ).build(range: state.range);

      emit(
        state.copyWith(
          status: StatisticsStatus.loaded,
          snapshot: snapshot,
          historyCount: historyCount,
          clearError: true,
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

  /// Switching ranges only re-reads history; the card set is small by
  /// comparison and is already in the database behind an index.
  Future<void> setRange(StatisticsRange range) async {
    if (range == state.range) return;
    emit(state.copyWith(range: range));
    await load();
  }

  DateTime _windowStart(DateTime now) {
    if (state.range.isAll) return DateTime(2000);
    final days = state.range.days > _calendarDays
        ? state.range.days
        : _calendarDays;
    return addDays(now, -(days - 1));
  }

  /// Exclusive upper bound, set just past midnight so today's reviews are in.
  DateTime _windowEnd(DateTime now) => addDays(now, 1);
}