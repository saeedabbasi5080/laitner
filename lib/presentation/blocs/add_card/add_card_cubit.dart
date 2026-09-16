import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';

part 'add_card_state.dart';

class AddCardCubit extends Cubit<AddCardState> {
  AddCardCubit({
    required String deckId,
    required String spaceId,
    required AddCardUseCase addCardUseCase,
    required AddDeckUseCase addDeckUseCase,
    required GetDecksUseCase getDecksUseCase,
    required LocalDataSource localDataSource,
  }) : _spaceId = spaceId,
       _addCardUseCase = addCardUseCase,
       _addDeckUseCase = addDeckUseCase,
       _getDecksUseCase = getDecksUseCase,
       _localDataSource = localDataSource,
       super(AddCardState(deckId: deckId));

  final String _spaceId;
  final AddCardUseCase _addCardUseCase;
  final AddDeckUseCase _addDeckUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final LocalDataSource _localDataSource;

  Future<void> loadDecks() async {
    final decks = await _getDecksUseCase(_spaceId);
    emit(state.copyWith(decks: decks));
  }

  void selectDeck(String deckId) {
    emit(state.copyWith(deckId: deckId));
  }

  Future<void> createDeck(String name, DeckColor color) async {
    final deck = Deck(
      id: _localDataSource.generateId(),
      spaceId: _spaceId,
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );
    final saved = await _addDeckUseCase(deck);
    final decks = await _getDecksUseCase(_spaceId);
    emit(state.copyWith(decks: decks, deckId: saved.id));
  }

  void updateFront(String value) {
    emit(
      state.copyWith(
        front: value,
        status: AddCardStatus.initial,
        clearError: true,
      ),
    );
  }

  void updateBack(String value) {
    emit(
      state.copyWith(
        back: value,
        status: AddCardStatus.initial,
        clearError: true,
      ),
    );
  }

  Future<bool> save() async {
    if (!state.canSave) return false;

    emit(state.copyWith(status: AddCardStatus.saving, clearError: true));
    try {
      final card = Flashcard(
        id: _localDataSource.generateId(),
        deckId: state.deckId,
        front: state.front.trim(),
        back: state.back.trim(),
        box: 1,
        createdAt: DateTime.now(),
      );
      await _addCardUseCase(card, spaceId: _spaceId);
      emit(state.copyWith(status: AddCardStatus.saved));
      return true;
    } on DuplicateCardException catch (e) {
      emit(
        state.copyWith(
          status: AddCardStatus.duplicate,
          errorMessage: AppStrings.duplicateCardInDeck(e.deckName),
        ),
      );
      return false;
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
