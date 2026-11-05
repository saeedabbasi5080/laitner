import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/repositories/deck_repository_impl.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/data/utils/uuid_id_generator.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_todays_mistakes_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';
import 'package:recall/presentation/blocs/deck_list/deck_list_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_review_history_repository.dart';
import 'support/in_memory_local_data_source.dart';

void main() {
  test(
    'the space page counts the cards answered wrong today, once each',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final local = InMemoryLocalDataSource(
        decks: [
          for (final id in ['d1', 'd2'])
            Deck(
              id: id,
              spaceId: 's1',
              name: id,
              color: DeckColor.mint,
              createdAt: now,
            ),
        ],
        cards: [
          for (final (id, deck) in [('c1', 'd1'), ('c2', 'd1'), ('c3', 'd2')])
            Flashcard(
              id: id,
              deckId: deck,
              front: id,
              back: 'x',
              box: 1,
              createdAt: now,
            ),
        ],
      );
      final history = FakeReviewHistoryRepository();
      ReviewLog log(
        String card,
        String deck,
        ReviewRating rating,
        int minutes,
      ) => ReviewLog(
        id: '$card-$minutes',
        spaceId: 's1',
        cardId: card,
        deckId: deck,
        rating: rating,
        boxBefore: 1,
        boxAfter: 1,
        reviewedAt: now.subtract(Duration(minutes: minutes)),
      );
      history.logs.addAll([
        log('c1', 'd1', ReviewRating.dontKnow, 30),
        log('c1', 'd1', ReviewRating.dontKnow, 20), // same card twice: one
        log('c2', 'd1', ReviewRating.know, 10), // right: not a mistake
        log('c3', 'd2', ReviewRating.dontKnow, 5),
      ]);

      final cards = FlashcardRepositoryImpl(local);
      final decks = DeckRepositoryImpl(local);
      final cubit = DeckListCubit(
        spaceId: 's1',
        getDecksUseCase: GetDecksUseCase(decks),
        getDueCardsUseCase: GetDueCardsUseCase(cards),
        getCardsByDeckUseCase: GetCardsByDeckUseCase(cards),
        addDeckUseCase: AddDeckUseCase(decks),
        updateDeckUseCase: UpdateDeckUseCase(decks),
        deleteDeckUseCase: DeleteDeckUseCase(decks, cards),
        flashcardRepository: cards,
        idGenerator: const UuidIdGenerator(),
        spaceSettingsStore: SpaceSettingsStore(prefs),
        getTodaysMistakesUseCase: GetTodaysMistakesUseCase(cards, history),
      );

      await cubit.load();

      expect(cubit.state.todaysMistakes, 2);
      await cubit.close();
    },
  );
}
