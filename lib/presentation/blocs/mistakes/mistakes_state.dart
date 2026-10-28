part of 'mistakes_cubit.dart';

enum MistakesStatus { initial, loading, loaded, error }

class MistakesState extends Equatable {
  const MistakesState({
    this.status = MistakesStatus.initial,
    this.decks = const [],
    this.mistakesByDeck = const {},
    this.errorMessage,
  });

  final MistakesStatus status;
  final List<Deck> decks;

  /// Wrong answers today, keyed by deck id. Decks with none are left out so
  /// the list only shows where there is something to do.
  final Map<String, List<MistakeCard>> mistakesByDeck;

  final String? errorMessage;

  List<MistakeCard> mistakesFor(String deckId) =>
      mistakesByDeck[deckId] ?? const [];

  /// Decks that have at least one mistake, in the order the user sees them.
  List<Deck> get decksWithMistakes => [
        for (final deck in decks)
          if (mistakesByDeck.containsKey(deck.id)) deck,
      ];

  int get totalMistakes => mistakesByDeck.values.fold(
        0,
        (sum, mistakes) => sum + mistakes.length,
      );

  MistakesState copyWith({
    MistakesStatus? status,
    List<Deck>? decks,
    Map<String, List<MistakeCard>>? mistakesByDeck,
    String? errorMessage,
  }) {
    return MistakesState(
      status: status ?? this.status,
      decks: decks ?? this.decks,
      mistakesByDeck: mistakesByDeck ?? this.mistakesByDeck,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, decks, mistakesByDeck, errorMessage];
}