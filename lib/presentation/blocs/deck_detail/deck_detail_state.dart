part of 'deck_detail_cubit.dart';

enum DeckDetailStatus { initial, loading, loaded, notFound, error }

class DeckDetailState extends Equatable {
  const DeckDetailState({
    this.status = DeckDetailStatus.initial,
    this.deck,
    this.cards = const [],
    this.dueCount = 0,
    this.errorMessage,
  });

  final DeckDetailStatus status;
  final Deck? deck;
  final List<Flashcard> cards;
  final int dueCount;
  final String? errorMessage;

  DeckDetailState copyWith({
    DeckDetailStatus? status,
    Deck? deck,
    List<Flashcard>? cards,
    int? dueCount,
    String? errorMessage,
  }) {
    return DeckDetailState(
      status: status ?? this.status,
      deck: deck ?? this.deck,
      cards: cards ?? this.cards,
      dueCount: dueCount ?? this.dueCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, deck, cards, dueCount, errorMessage];
}
