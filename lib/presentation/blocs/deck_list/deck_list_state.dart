part of 'deck_list_cubit.dart';

enum DeckListStatus { initial, loading, loaded, error }

class DeckListState extends Equatable {
  const DeckListState({
    this.status = DeckListStatus.initial,
    this.decks = const [],
    this.dueCounts = const {},
    this.totalCounts = const {},
    this.boxCounts = const {},
    this.maxBox = 5,
    this.boxes = LeitnerBoxConfig.classic,
    this.totalDue = 0,
    this.learnedCount = 0,
    this.errorMessage,
  });

  final DeckListStatus status;
  final List<Deck> decks;
  final Map<String, int> dueCounts;
  final Map<String, int> totalCounts;
  final Map<int, int> boxCounts;
  final int maxBox;
  final LeitnerBoxConfig boxes;
  final int totalDue;
  final int learnedCount;
  final String? errorMessage;

  DeckListState copyWith({
    DeckListStatus? status,
    List<Deck>? decks,
    Map<String, int>? dueCounts,
    Map<String, int>? totalCounts,
    Map<int, int>? boxCounts,
    int? maxBox,
    LeitnerBoxConfig? boxes,
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
      maxBox: maxBox ?? this.maxBox,
      boxes: boxes ?? this.boxes,
      totalDue: totalDue ?? this.totalDue,
      learnedCount: learnedCount ?? this.learnedCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        decks,
        dueCounts,
        totalCounts,
        boxCounts,
        maxBox,
        boxes,
        totalDue,
        learnedCount,
        errorMessage,
      ];
}
