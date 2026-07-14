import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';

part 'deck_detail_state.dart';

class DeckDetailCubit extends Cubit<DeckDetailState> {
  DeckDetailCubit({
    required String deckId,
    required GetDeckUseCase getDeckUseCase,
    required GetCardsByDeckUseCase getCardsByDeckUseCase,
    required GetDueCardsUseCase getDueCardsUseCase,
    required UpdateDeckUseCase updateDeckUseCase,
    required DeleteDeckUseCase deleteDeckUseCase,
    required UpdateCardUseCase updateCardUseCase,
    required DeleteCardUseCase deleteCardUseCase,
  })  : _deckId = deckId,
        _getDeckUseCase = getDeckUseCase,
        _getCardsByDeckUseCase = getCardsByDeckUseCase,
        _getDueCardsUseCase = getDueCardsUseCase,
        _updateDeckUseCase = updateDeckUseCase,
        _deleteDeckUseCase = deleteDeckUseCase,
        _updateCardUseCase = updateCardUseCase,
        _deleteCardUseCase = deleteCardUseCase,
        super(const DeckDetailState());

  final String _deckId;
  final GetDeckUseCase _getDeckUseCase;
  final GetCardsByDeckUseCase _getCardsByDeckUseCase;
  final GetDueCardsUseCase _getDueCardsUseCase;
  final UpdateDeckUseCase _updateDeckUseCase;
  final DeleteDeckUseCase _deleteDeckUseCase;
  final UpdateCardUseCase _updateCardUseCase;
  final DeleteCardUseCase _deleteCardUseCase;

  Future<void> load() async {
    emit(state.copyWith(status: DeckDetailStatus.loading));
    try {
      final deck = await _getDeckUseCase(_deckId);
      if (deck == null) {
        emit(state.copyWith(status: DeckDetailStatus.notFound));
        return;
      }
      final cards = await _getCardsByDeckUseCase(_deckId);
      final due = await _getDueCardsUseCase(_deckId);
      emit(
        state.copyWith(
          status: DeckDetailStatus.loaded,
          deck: deck,
          cards: cards,
          dueCount: due.length,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckDetailStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> updateDeck(Deck deck) async {
    await _updateDeckUseCase(deck);
    await load();
  }

  Future<void> deleteDeck() async {
    await _deleteDeckUseCase(_deckId);
  }

  Future<void> updateCard(String id, String front, String back) async {
    final card = state.cards.firstWhere((c) => c.id == id);
    await _updateCardUseCase(
      card.copyWith(front: front.trim(), back: back.trim()),
    );
    await load();
  }

  Future<void> deleteCard(String id) async {
    await _deleteCardUseCase(id);
    await load();
  }
}
