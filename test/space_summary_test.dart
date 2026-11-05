import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/repositories/deck_repository_impl.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/data/repositories/review_history_repository_impl.dart';
import 'package:recall/data/repositories/space_repository_impl.dart';
import 'package:recall/data/utils/uuid_id_generator.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';
import 'package:recall/domain/usecases/delete_space_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/update_space_usecase.dart';
import 'package:recall/presentation/blocs/space_list/space_list_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_local_data_source.dart';

void main() {
  test('the home figures count learned, learning and due separately', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final longAgo = now.subtract(const Duration(days: 60));

    Flashcard card(String id, int box, DateTime reviewed) => Flashcard(
      id: id,
      deckId: 'd1',
      front: id,
      back: 'x',
      box: box,
      lastReviewed: reviewed,
      createdAt: longAgo,
    );

    final local = InMemoryLocalDataSource(
      spaces: [
        LearningSpace(
          id: 's1',
          name: 'English',
          color: DeckColor.mint,
          createdAt: longAgo,
        ),
      ],
      decks: [
        Deck(
          id: 'd1',
          spaceId: 's1',
          name: 'd',
          color: DeckColor.mint,
          createdAt: longAgo,
        ),
      ],
      cards: [
        card('due', 1, longAgo), // in a house, due
        card('waiting', 3, now), // in a house, not due
        card('learned1', 6, now), // past house 5
        card('learned2', 6, longAgo), // past house 5, never due again
      ],
    );
    final spaces = SpaceRepositoryImpl(local);
    final decks = DeckRepositoryImpl(local);
    final cards = FlashcardRepositoryImpl(local);
    final settings = SpaceSettingsStore(prefs);
    final cubit = SpaceListCubit(
      getSpacesUseCase: GetSpacesUseCase(spaces),
      getDecksUseCase: GetDecksUseCase(decks),
      getDueCardsUseCase: GetDueCardsUseCase(cards),
      getCardsByDeckUseCase: GetCardsByDeckUseCase(cards),
      addSpaceUseCase: AddSpaceUseCase(spaces),
      updateSpaceUseCase: UpdateSpaceUseCase(spaces),
      deleteSpaceUseCase: DeleteSpaceUseCase(
        spaces,
        ReviewHistoryRepositoryImpl(local),
        ExcelImportStore(prefs),
        settings,
        decks,
      ),
      idGenerator: const UuidIdGenerator(),
      spaceSettingsStore: settings,
    );

    await cubit.load();
    final summary = cubit.state.summaries.single;

    expect(summary.totalCards, 4);
    expect(summary.learnedCards, 2);
    expect(summary.learningCards, 2);
    expect(summary.dueCards, 1);
    await cubit.close();
  });
}
