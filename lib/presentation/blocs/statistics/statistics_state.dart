part of 'statistics_cubit.dart';

enum StatisticsStatus { initial, loading, loaded, error }

class StatisticsState extends Equatable {
  const StatisticsState({
    this.status = StatisticsStatus.initial,
    this.range = StatisticsRange.month,
    this.snapshot,
    this.historyCount = 0,
    this.errorMessage,
  });

  final StatisticsStatus status;

  /// The selected time scope, mirroring Anki's "History" selector.
  final StatisticsRange range;

  /// Everything the charts render, or `null` before the first load finishes.
  final StatisticsSnapshot? snapshot;

  /// Total reviews ever recorded for this space, independent of [range].
  ///
  /// Kept separately so the empty-state hint can tell "no reviews in this
  /// window" apart from "this space has never been studied".
  final int historyCount;

  final String? errorMessage;

  bool get isLoading => status == StatisticsStatus.loading;

  /// True when the space has review history at all.
  bool get hasHistory => historyCount > 0;

  /// True when the loaded [range] has nothing to show.
  bool get isRangeEmpty => snapshot?.reviewBuckets.every((b) => b.total == 0) ?? false;

  double get masteryProgress => snapshot?.masteryProgress ?? 0;

  double get knowRate => snapshot?.knowRate ?? 0;

  StatisticsState copyWith({
    StatisticsStatus? status,
    StatisticsRange? range,
    StatisticsSnapshot? snapshot,
    int? historyCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      range: range ?? this.range,
      snapshot: snapshot ?? this.snapshot,
      historyCount: historyCount ?? this.historyCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, range, snapshot, historyCount, errorMessage];
}