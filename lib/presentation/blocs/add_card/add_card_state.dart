part of 'add_card_cubit.dart';

enum AddCardStatus { initial, saving, saved, error }

class AddCardState extends Equatable {
  const AddCardState({
    this.front = '',
    this.back = '',
    this.status = AddCardStatus.initial,
    this.errorMessage,
  });

  final String front;
  final String back;
  final AddCardStatus status;
  final String? errorMessage;

  bool get canSave => front.trim().isNotEmpty && back.trim().isNotEmpty;

  AddCardState copyWith({
    String? front,
    String? back,
    AddCardStatus? status,
    String? errorMessage,
  }) {
    return AddCardState(
      front: front ?? this.front,
      back: back ?? this.back,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [front, back, status, errorMessage];
}
