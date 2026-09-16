import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/move_cards_to_deck_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';

part 'deck_detail_state.dart';

class DeckDetailCubit extends Cubit<DeckDetailState> {
  DeckDetailCubit({
    required String deckId,
    required String spaceId,
    required GetDeckUseCase getDeckUseCase,
    required GetDecksUseCase getDecksUseCase,
    required GetCardsByDeckUseCase getCardsByDeckUseCase,
    required GetDueCardsUseCase getDueCardsUseCase,
    required UpdateDeckUseCase updateDeckUseCase,
    required DeleteDeckUseCase deleteDeckUseCase,
    required UpdateCardUseCase updateCardUseCase,
    required DeleteCardUseCase deleteCardUseCase,
    required MoveCardsToDeckUseCase moveCardsToDeckUseCase,
    required SpaceSettingsStore spaceSettingsStore,
  })  : _deckId = deckId,
        _spaceId = spaceId,
        _getDeckUseCase = getDeckUseCase,
        _getDecksUseCase = getDecksUseCase,
        _getCardsByDeckUseCase = getCardsByDeckUseCase,
        _getDueCardsUseCase = getDueCardsUseCase,
        _updateDeckUseCase = updateDeckUseCase,
        _deleteDeckUseCase = deleteDeckUseCase,
        _updateCardUseCase = updateCardUseCase,
        _deleteCardUseCase = deleteCardUseCase,
        _moveCardsToDeckUseCase = moveCardsToDeckUseCase,
        _spaceSettingsStore = spaceSettingsStore,
        super(const DeckDetailState());

  final String _deckId;
  final String _spaceId;
  final GetDeckUseCase _getDeckUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final GetCardsByDeckUseCase _getCardsByDeckUseCase;
  final GetDueCardsUseCase _getDueCardsUseCase;
  final UpdateDeckUseCase _updateDeckUseCase;
  final DeleteDeckUseCase _deleteDeckUseCase;
  final UpdateCardUseCase _updateCardUseCase;
  final DeleteCardUseCase _deleteCardUseCase;
  final MoveCardsToDeckUseCase _moveCardsToDeckUseCase;
  final SpaceSettingsStore _spaceSettingsStore;

  Future<void> load() async {
    emit(state.copyWith(status: DeckDetailStatus.loading));
    try {
      final deck = await _getDeckUseCase(_deckId);
      if (deck == null) {
        emit(state.copyWith(status: DeckDetailStatus.notFound));
        return;
      }
      final boxes = (await _spaceSettingsStore.load(_spaceId)).leitnerBoxes;
      final cards = await _getCardsByDeckUseCase(_deckId);
      final due = await _getDueCardsUseCase(_deckId, boxes: boxes);
      final decks = await _getDecksUseCase(_spaceId);
      emit(
        state.copyWith(
          status: DeckDetailStatus.loaded,
          deck: deck,
          cards: cards,
          dueCount: due.length,
          otherDecks: decks.where((d) => d.id != _deckId).toList(),
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

  Future<void> deleteDeck({String? transferToDeckId}) async {
    await _deleteDeckUseCase(_deckId, transferToDeckId: transferToDeckId);
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

  Future<int> moveCards(List<String> cardIds, String targetDeckId) async {
    final moved = await _moveCardsToDeckUseCase(
      cardIds: cardIds,
      targetDeckId: targetDeckId,
    );
    await load();
    return moved;
  }
}
