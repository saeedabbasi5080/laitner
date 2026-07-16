part of 'statistics_cubit.dart';

enum StatisticsStatus { initial, loading, loaded, error }

class StatisticsState extends Equatable {
  const StatisticsState({
    this.status = StatisticsStatus.initial,
    this.boxCounts = const {},
    this.dailyReviewCounts = const [],
    this.futureDueCounts = const [],
    this.totalCards = 0,
    this.masteredCards = 0,
    this.totalReviews = 0,
    this.knowCount = 0,
    this.dontKnowCount = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.errorMessage,
  });

  final StatisticsStatus status;
  final Map<int, int> boxCounts;
  final List<int> dailyReviewCounts;
  final List<int> futureDueCounts;
  final int totalCards;
  final int masteredCards;
  final int totalReviews;
  final int knowCount;
  final int dontKnowCount;
  final int currentStreak;
  final int bestStreak;
  final String? errorMessage;

  double get masteryProgress =>
      totalCards == 0 ? 0 : masteredCards / totalCards;

  double get knowRate => totalReviews == 0 ? 0 : knowCount / totalReviews;

  StatisticsState copyWith({
    StatisticsStatus? status,
    Map<int, int>? boxCounts,
    List<int>? dailyReviewCounts,
    List<int>? futureDueCounts,
    int? totalCards,
    int? masteredCards,
    int? totalReviews,
    int? knowCount,
    int? dontKnowCount,
    int? currentStreak,
    int? bestStreak,
    String? errorMessage,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      boxCounts: boxCounts ?? this.boxCounts,
      dailyReviewCounts: dailyReviewCounts ?? this.dailyReviewCounts,
      futureDueCounts: futureDueCounts ?? this.futureDueCounts,
      totalCards: totalCards ?? this.totalCards,
      masteredCards: masteredCards ?? this.masteredCards,
      totalReviews: totalReviews ?? this.totalReviews,
      knowCount: knowCount ?? this.knowCount,
      dontKnowCount: dontKnowCount ?? this.dontKnowCount,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    boxCounts,
    dailyReviewCounts,
    futureDueCounts,
    totalCards,
    masteredCards,
    totalReviews,
    knowCount,
    dontKnowCount,
    currentStreak,
    bestStreak,
    errorMessage,
  ];
}
