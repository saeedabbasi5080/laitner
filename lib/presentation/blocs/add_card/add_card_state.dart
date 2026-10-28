part of 'add_card_cubit.dart';

enum AddCardStatus { initial, saving, saved, duplicate, error }

class AddCardState extends Equatable {
  const AddCardState({
    required this.draftId,
    required this.deckId,
    this.decks = const [],
    this.front = '',
    this.back = '',
    this.frontStyle = '',
    this.backStyle = '',
    this.tags = const [],
    this.media = const [],
    this.status = AddCardStatus.initial,
    this.errorMessage,
  });

  final String draftId;
  final String deckId;
  final List<Deck> decks;
  final String front;
  final String back;
  final String frontStyle;
  final String backStyle;
  final List<String> tags;
  final List<CardMedia> media;
  final AddCardStatus status;
  final String? errorMessage;

  bool get canSave =>
      deckId.isNotEmpty &&
      front.trim().isNotEmpty &&
      back.trim().isNotEmpty &&
      status != AddCardStatus.saving;

  List<CardMedia> mediaFor(CardMediaSide side) =>
      media.where((item) => item.side == side).toList();

  AddCardState copyWith({
    String? draftId,
    String? deckId,
    List<Deck>? decks,
    String? front,
    String? back,
    String? frontStyle,
    String? backStyle,
    List<String>? tags,
    List<CardMedia>? media,
    AddCardStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AddCardState(
      draftId: draftId ?? this.draftId,
      deckId: deckId ?? this.deckId,
      decks: decks ?? this.decks,
      front: front ?? this.front,
      back: back ?? this.back,
      frontStyle: frontStyle ?? this.frontStyle,
      backStyle: backStyle ?? this.backStyle,
      tags: tags ?? this.tags,
      media: media ?? this.media,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        draftId,
        deckId,
        decks,
        front,
        back,
        frontStyle,
        backStyle,
        tags,
        media,
        status,
        errorMessage,
      ];
}
