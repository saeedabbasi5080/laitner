import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';

part 'add_card_state.dart';

class AddCardCubit extends Cubit<AddCardState> {
  AddCardCubit({
    required String deckId,
    required AddCardUseCase addCardUseCase,
    required LocalDataSource localDataSource,
  })  : _deckId = deckId,
        _addCardUseCase = addCardUseCase,
        _localDataSource = localDataSource,
        super(const AddCardState());

  final String _deckId;
  final AddCardUseCase _addCardUseCase;
  final LocalDataSource _localDataSource;

  void updateFront(String value) {
    emit(state.copyWith(front: value));
  }

  void updateBack(String value) {
    emit(state.copyWith(back: value));
  }

  Future<bool> save() async {
    if (!state.canSave) return false;

    emit(state.copyWith(status: AddCardStatus.saving));
    try {
      final card = Flashcard(
        id: _localDataSource.generateId(),
        deckId: _deckId,
        front: state.front.trim(),
        back: state.back.trim(),
        box: 1,
        createdAt: DateTime.now(),
      );
      await _addCardUseCase(card);
      emit(state.copyWith(status: AddCardStatus.saved));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          status: AddCardStatus.error,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }
}
