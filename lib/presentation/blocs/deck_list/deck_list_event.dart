part of 'deck_list_cubit.dart';

sealed class DeckListEvent extends Equatable {
  const DeckListEvent();

  @override
  List<Object?> get props => [];
}

class DeckListLoadRequested extends DeckListEvent {
  const DeckListLoadRequested();
}

class DeckListAddDeckRequested extends DeckListEvent {
  const DeckListAddDeckRequested(this.name, this.color);

  final String name;
  final DeckColor color;

  @override
  List<Object?> get props => [name, color];
}
