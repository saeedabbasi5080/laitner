import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';

part 'deck_list_event.dart';
part 'deck_list_state.dart';

class DeckListCubit extends Cubit<DeckListState> {
  DeckListCubit({
    required String spaceId,
    required GetDecksUseCase getDecksUseCase,
    required GetDueCardsUseCase getDueCardsUseCase,
    required GetCardsByDeckUseCase getCardsByDeckUseCase,
    required AddDeckUseCase addDeckUseCase,
    required UpdateDeckUseCase updateDeckUseCase,
    required DeleteDeckUseCase deleteDeckUseCase,
    required IFlashcardRepository flashcardRepository,
    required LocalDataSource localDataSource,
  })  : _spaceId = spaceId,
        _getDecksUseCase = getDecksUseCase,
        _getDueCardsUseCase = getDueCardsUseCase,
        _getCardsByDeckUseCase = getCardsByDeckUseCase,
        _addDeckUseCase = addDeckUseCase,
        _updateDeckUseCase = updateDeckUseCase,
        _deleteDeckUseCase = deleteDeckUseCase,
        _flashcardRepository = flashcardRepository,
        _localDataSource = localDataSource,
        super(const DeckListState());

  final String _spaceId;
  final GetDecksUseCase _getDecksUseCase;
  final GetDueCardsUseCase _getDueCardsUseCase;
  final GetCardsByDeckUseCase _getCardsByDeckUseCase;
  final AddDeckUseCase _addDeckUseCase;
  final UpdateDeckUseCase _updateDeckUseCase;
  final DeleteDeckUseCase _deleteDeckUseCase;
  final IFlashcardRepository _flashcardRepository;
  final LocalDataSource _localDataSource;

  String get spaceId => _spaceId;

  Future<void> load() async {
    emit(state.copyWith(status: DeckListStatus.loading));
    try {
      final decks = await _getDecksUseCase(_spaceId);
      final dueCounts = <String, int>{};
      final totalCounts = <String, int>{};

      for (final deck in decks) {
        final due = await _getDueCardsUseCase(deck.id);
        final all = await _getCardsByDeckUseCase(deck.id);
        dueCounts[deck.id] = due.length;
        totalCounts[deck.id] = all.length;
      }

      final allCards = await _flashcardRepository.getCardsBySpaceId(_spaceId);
      final boxCounts = {for (var i = 1; i <= maxBox; i++) i: 0};
      for (final card in allCards) {
        if (card.box >= 1 && card.box <= maxBox) {
          boxCounts[card.box] = (boxCounts[card.box] ?? 0) + 1;
        }
      }

      final totalDue =
          dueCounts.values.fold<int>(0, (sum, count) => sum + count);

      emit(
        state.copyWith(
          status: DeckListStatus.loaded,
          decks: decks,
          dueCounts: dueCounts,
          totalCounts: totalCounts,
          boxCounts: boxCounts,
          totalDue: totalDue,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DeckListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> addDeck(String name, DeckColor color) async {
    final deck = Deck(
      id: _localDataSource.generateId(),
      spaceId: _spaceId,
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
    );
    await _addDeckUseCase(deck);
    await load();
  }

  Future<void> updateDeck(Deck deck) async {
    await _updateDeckUseCase(deck);
    await load();
  }

  Future<void> deleteDeck(String id) async {
    await _deleteDeckUseCase(id);
    await load();
  }
}
