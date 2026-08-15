part of 'deck_list_cubit.dart';

enum DeckListStatus { initial, loading, loaded, error }

class DeckListState extends Equatable {
  const DeckListState({
    this.status = DeckListStatus.initial,
    this.decks = const [],
    this.dueCounts = const {},
    this.totalCounts = const {},
    this.boxCounts = const {},
    this.totalDue = 0,
    this.learnedCount = 0,
    this.errorMessage,
  });

  final DeckListStatus status;
  final List<Deck> decks;
  final Map<String, int> dueCounts;
  final Map<String, int> totalCounts;
  final Map<int, int> boxCounts;
  final int totalDue;
  final int learnedCount;
  final String? errorMessage;

  DeckListState copyWith({
    DeckListStatus? status,
    List<Deck>? decks,
    Map<String, int>? dueCounts,
    Map<String, int>? totalCounts,
    Map<int, int>? boxCounts,
    int? totalDue,
    int? learnedCount,
    String? errorMessage,
  }) {
    return DeckListState(
      status: status ?? this.status,
      decks: decks ?? this.decks,
      dueCounts: dueCounts ?? this.dueCounts,
      totalCounts: totalCounts ?? this.totalCounts,
      boxCounts: boxCounts ?? this.boxCounts,
      totalDue: totalDue ?? this.totalDue,
      learnedCount: learnedCount ?? this.learnedCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, decks, dueCounts, totalCounts, boxCounts, totalDue, learnedCount, errorMessage];
}
