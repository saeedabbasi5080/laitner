part of 'daily_feed_cubit.dart';

enum DailyFeedStatus { initial, loading, ready, error }

class DailyFeedState extends Equatable {
  const DailyFeedState({
    this.status = DailyFeedStatus.initial,
    this.decks = const [],
    this.imports = const [],
    this.running = false,
    this.lastResult,
    this.errorMessage,
  });

  final DailyFeedStatus status;
  final List<Deck> decks;
  final List<ExcelImport> imports;

  /// True while the manual run is in flight, so the button can be disabled.
  final bool running;

  /// Outcome of the last manual run, for the confirmation line.
  final SpaceFeedRun? lastResult;

  final String? errorMessage;

  bool get loading => status == DailyFeedStatus.loading;

  /// How many rows across [importIds] are still waiting to be released.
  int backlogFor(DailyExcelFeedSettings feed) {
    final wanted = feed.importIds.toSet();
    var total = 0;
    for (final import in imports) {
      if (!wanted.contains(import.id)) continue;
      total += import.pendingCount;
    }
    return total;
  }

  Deck? deckNamed(String? deckId) {
    if (deckId == null) return null;
    for (final deck in decks) {
      if (deck.id == deckId) return deck;
    }
    return null;
  }

  DailyFeedState copyWith({
    DailyFeedStatus? status,
    List<Deck>? decks,
    List<ExcelImport>? imports,
    bool? running,
    SpaceFeedRun? lastResult,
    String? errorMessage,
    bool clearLastResult = false,
  }) {
    return DailyFeedState(
      status: status ?? this.status,
      decks: decks ?? this.decks,
      imports: imports ?? this.imports,
      running: running ?? this.running,
      lastResult: clearLastResult ? null : (lastResult ?? this.lastResult),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        decks,
        imports,
        running,
        lastResult,
        errorMessage,
      ];
}