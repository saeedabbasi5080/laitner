import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_todays_mistakes_usecase.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';

part 'mistakes_state.dart';

/// Groups today's wrong answers by deck, so a retry can be started for any one
/// of them without hunting through the deck list.
class MistakesCubit extends Cubit<MistakesState> {
  MistakesCubit({
    required GetTodaysMistakesUseCase getMistakesUseCase,
    required GetDecksUseCase getDecksUseCase,
    required String spaceId,
  })  : _getMistakesUseCase = getMistakesUseCase,
        _getDecksUseCase = getDecksUseCase,
        _spaceId = spaceId,
        super(const MistakesState());

  final GetTodaysMistakesUseCase _getMistakesUseCase;
  final GetDecksUseCase _getDecksUseCase;
  final String _spaceId;

  Future<void> load() async {
    emit(state.copyWith(status: MistakesStatus.loading));
    try {
      final decks = await _getDecksUseCase(_spaceId);
      final mistakesByDeck = <String, List<MistakeCard>>{};

      for (final deck in decks) {
        final mistakes = await _getMistakesUseCase(
          spaceId: _spaceId,
          deckId: deck.id,
        );
        if (mistakes.isEmpty) continue;
        mistakesByDeck[deck.id] = mistakes;
      }

      emit(
        state.copyWith(
          status: MistakesStatus.loaded,
          decks: decks,
          mistakesByDeck: mistakesByDeck,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: MistakesStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Card ids for a deck, ordered so the worst-known cards come first.
  List<String> cardIdsFor(String deckId) => [
        for (final mistake in state.mistakesFor(deckId)) mistake.card.id,
      ];

  /// A ready-to-open session that retries one deck's mistakes.
  ///
  /// Carries the space's own Leitner layout and review preferences, so a retry
  /// reschedules exactly as a normal session would.
  StudyConfig retryConfig(String deckId) => StudyConfig.deck(
        spaceId: _spaceId,
        deckId: deckId,
      ).withMistakeRetry(cardIdsFor(deckId));
}

class MistakesByDeck extends Equatable {
  const MistakesByDeck({required this.deck, required this.mistakes});

  final Deck deck;
  final List<MistakeCard> mistakes;

  int get count => mistakes.length;

  @override
  List<Object?> get props => [deck, mistakes];
}