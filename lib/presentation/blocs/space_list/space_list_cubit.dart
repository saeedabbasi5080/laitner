import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';
import 'package:recall/domain/usecases/delete_space_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/update_space_usecase.dart';
import 'package:recall/presentation/blocs/space_list/space_list_state.dart';

class SpaceListCubit extends Cubit<SpaceListState> {
  SpaceListCubit({
    required GetSpacesUseCase getSpacesUseCase,
    required GetDecksUseCase getDecksUseCase,
    required GetDueCardsUseCase getDueCardsUseCase,
    required GetCardsByDeckUseCase getCardsByDeckUseCase,
    required AddSpaceUseCase addSpaceUseCase,
    required UpdateSpaceUseCase updateSpaceUseCase,
    required DeleteSpaceUseCase deleteSpaceUseCase,
    required LocalDataSource localDataSource,
  })  : _getSpacesUseCase = getSpacesUseCase,
        _getDecksUseCase = getDecksUseCase,
        _getDueCardsUseCase = getDueCardsUseCase,
        _getCardsByDeckUseCase = getCardsByDeckUseCase,
        _addSpaceUseCase = addSpaceUseCase,
        _updateSpaceUseCase = updateSpaceUseCase,
        _deleteSpaceUseCase = deleteSpaceUseCase,
        _localDataSource = localDataSource,
        super(const SpaceListState());

  final GetSpacesUseCase _getSpacesUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final GetDueCardsUseCase _getDueCardsUseCase;
  final GetCardsByDeckUseCase _getCardsByDeckUseCase;
  final AddSpaceUseCase _addSpaceUseCase;
  final UpdateSpaceUseCase _updateSpaceUseCase;
  final DeleteSpaceUseCase _deleteSpaceUseCase;
  final LocalDataSource _localDataSource;

  Future<void> load() async {
    emit(state.copyWith(status: SpaceListStatus.loading));
    try {
      final spaces = await _getSpacesUseCase();
      final summaries = <SpaceSummary>[];

      for (final space in spaces) {
        final decks = await _getDecksUseCase(space.id);
        var totalCards = 0;
        var dueCards = 0;
        for (final deck in decks) {
          totalCards += (await _getCardsByDeckUseCase(deck.id)).length;
          dueCards += (await _getDueCardsUseCase(deck.id)).length;
        }
        summaries.add(
          SpaceSummary(
            space: space,
            deckCount: decks.length,
            totalCards: totalCards,
            dueCards: dueCards,
          ),
        );
      }

      emit(
        state.copyWith(
          status: SpaceListStatus.loaded,
          summaries: summaries,
          canAddSpace: spaces.length < maxLearningSpaces,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: SpaceListStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> addSpace(String name, DeckColor color) async {
    final spaces = await _getSpacesUseCase();
    final space = LearningSpace(
      id: _localDataSource.generateId(),
      name: name.trim(),
      color: color,
      createdAt: DateTime.now(),
      sortOrder: spaces.length,
    );
    await _addSpaceUseCase(space);
    await load();
  }

  Future<void> updateSpace(LearningSpace space) async {
    await _updateSpaceUseCase(space);
    await load();
  }

  Future<bool> deleteSpace(String id) async {
    final spaces = await _getSpacesUseCase();
    if (spaces.length <= 1) return false;

    await _deleteSpaceUseCase(id);
    await load();
    return true;
  }
}
