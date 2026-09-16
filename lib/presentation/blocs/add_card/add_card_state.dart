part of 'add_card_cubit.dart';

enum AddCardStatus { initial, saving, saved, duplicate, error }

class AddCardState extends Equatable {
  const AddCardState({
    required this.deckId,
    this.decks = const [],
    this.front = '',
    this.back = '',
    this.status = AddCardStatus.initial,
    this.errorMessage,
  });

  final String deckId;
  final List<Deck> decks;
  final String front;
  final String back;
  final AddCardStatus status;
  final String? errorMessage;

  bool get canSave =>
      deckId.isNotEmpty &&
      front.trim().isNotEmpty &&
      back.trim().isNotEmpty &&
      status != AddCardStatus.saving;

  AddCardState copyWith({
    String? deckId,
    List<Deck>? decks,
    String? front,
    String? back,
    AddCardStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddCardState(
      deckId: deckId ?? this.deckId,
      decks: decks ?? this.decks,
      front: front ?? this.front,
      back: back ?? this.back,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [deckId, decks, front, back, status, errorMessage];
}
