import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/entities/review_settings.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_space_cards_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';

import 'support/fake_review_history_repository.dart';

final _past = DateTime.now().subtract(const Duration(days: 5));

Flashcard _card(String id, {int box = 1}) => Flashcard(
      id: id,
      deckId: 'd1',
      front: 'Word-$id',
      back: 'x',
      box: box,
      lastReviewed: _past,
      createdAt: _past,
    );

List<Flashcard> _cards() => [_card('c1'), _card('c2'), _card('c3')];

/// Builds a cubit over the supplied cards.
StudyCubit _cubit(
  List<Flashcard> cards, {
  StudyConfig? config,
  _SlowRepo? repo,
}) {
  final repository = repo ?? _SlowRepo(cards);
  return StudyCubit(
    config: config ?? StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
    getDueCardsUseCase: GetDueCardsUseCase(repository),
    getAllDueCardsUseCase: GetAllDueCardsUseCase(repository),
    getSpaceCardsUseCase: GetSpaceCardsUseCase(repository),
    getCardsByBoxUseCase: GetCardsByBoxUseCase(repository),
    getCardsByDeckUseCase: GetCardsByDeckUseCase(repository),
    getDecksUseCase: GetDecksUseCase(
      _Decks([
        Deck(
          id: 'd1',
          spaceId: 's1',
          name: 'D',
          color: DeckColor.mint,
          createdAt: _past,
        ),
      ]),
    ),
    reviewCardUseCase: ReviewCardUseCase(
      repository,
      FakeReviewHistoryRepository(),
    ),
    updateCardUseCase: UpdateCardUseCase(repository),
    deleteCardUseCase: DeleteCardUseCase(repository),
  );
}

void main() {
  group('editing a card mid-review', () {
    test('shows each card once when nothing races', () async {
      final cubit = _cubit(_cards());
      await cubit.load();

      cubit.flipCard();
      await cubit.rateCard(ReviewRating.know);
      cubit.flipCard();
      await cubit.rateCard(ReviewRating.dontKnow);

      expect(cubit.state.queue.map((c) => c.id).toSet().length, 3);
      expect(cubit.state.currentCard?.id, 'c3');

      await cubit.close();
    });

    test('a rating while the edit write is in flight does not duplicate '
        'or drop a card', () async {
      final cubit = _cubit(_cards());
      await cubit.load();
      cubit.flipCard();

      // The edit lands late; the rating's write completes first, exactly as on
      // a real device when the user taps quickly.
      final repo = _SlowRepo(_cards(), writeDelay: const Duration(seconds: 0));
      final raced = _cubit(_cards(), repo: repo);
      await raced.load();
      raced.flipCard();

      repo.writeDelay = const Duration(milliseconds: 200);
      final edit = raced.updateCurrentCard('Edited', 'back');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      repo.writeDelay = Duration.zero;
      await raced.rateCard(ReviewRating.know);
      await edit;

      final ids = raced.state.queue.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'a card appears twice');
      expect(ids, ['c1', 'c2', 'c3']);

      await cubit.close();
      await raced.close();
    });

    test('the edit is not lost when a rating happens first', () async {
      final repo = _SlowRepo(_cards());
      final cubit = _cubit(_cards(), repo: repo);
      await cubit.load();
      cubit.flipCard();

      repo.writeDelay = const Duration(milliseconds: 200);
      final edit = cubit.updateCurrentCard('Edited', 'back');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      repo.writeDelay = Duration.zero;
      await cubit.rateCard(ReviewRating.know);
      await edit;

      // The card was already rated, so it sits behind the cursor, but its
      // saved text must still reflect the edit.
      expect(repo.cards.firstWhere((c) => c.id == 'c1').front, 'Edited');
      expect(cubit.state.queue.length, 3);
      expect(cubit.state.currentCard?.id, 'c2');

      await cubit.close();
    });

    test('resetting to house 1 mid-review keeps the queue intact', () async {
      final repo = _SlowRepo(_cards());
      final cubit = _cubit(_cards(), repo: repo);
      await cubit.load();
      cubit.flipCard();

      repo.writeDelay = const Duration(milliseconds: 200);
      final reset = cubit.resetCurrentCardToBox1();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      repo.writeDelay = Duration.zero;
      await cubit.rateCard(ReviewRating.know);
      await reset;

      final ids = cubit.state.queue.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids, ['c1', 'c2', 'c3']);

      await cubit.close();
    });
  });

  group('graduating a card', () {
    test('flags the card that reached the learned archive', () async {
      final past = DateTime.now().subtract(const Duration(days: 20));
      final repo = _SlowRepo([
        Flashcard(
          id: 'g1',
          deckId: 'd1',
          front: 'Apple',
          back: 'سیب',
          box: 5,
          lastReviewed: past,
          createdAt: past,
        ),
      ]);
      final cubit = _cubit(const [], repo: repo);
      await cubit.load();

      expect(cubit.state.justLearned, isEmpty);

      cubit.flipCard();
      await cubit.rateCard(ReviewRating.know);

      expect(repo.cards.single.box, 6, reason: 'graduated to the archive');
      expect(cubit.state.justLearned.map((c) => c.id), ['g1']);

      await cubit.close();
    });

    test('an ordinary answer does not raise the banner', () async {
      final past = DateTime.now().subtract(const Duration(days: 20));
      final repo = _SlowRepo([
        Flashcard(
          id: 'n1',
          deckId: 'd1',
          front: 'Book',
          back: 'کتاب',
          box: 2,
          lastReviewed: past,
          createdAt: past,
        ),
      ]);
      final cubit = _cubit(const [], repo: repo);
      await cubit.load();

      cubit.flipCard();
      await cubit.rateCard(ReviewRating.know);

      expect(repo.cards.single.box, 3);
      expect(cubit.state.justLearned, isEmpty);

      await cubit.close();
    });

    test('free review never raises it, since nothing is rescheduled', () async {
      final past = DateTime.now().subtract(const Duration(days: 20));
      final repo = _SlowRepo([
        Flashcard(
          id: 'f1',
          deckId: 'd1',
          front: 'Apple',
          back: 'سیب',
          box: 5,
          lastReviewed: past,
          createdAt: past,
        ),
      ]);
      final cubit = _cubit(
        const [],
        repo: repo,
        config: StudyConfig.byBox(5, spaceId: 's1'),
      );
      await cubit.load();

      cubit.flipCard();
      await cubit.rateCard(ReviewRating.know);

      expect(cubit.state.justLearned, isEmpty);
      expect(repo.cards.single.box, 5, reason: 'box is untouched');

      await cubit.close();
    });
  });

  group('rating moves the card as expected', () {
    test('know advances the house, dontKnow returns to house 1', () async {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final repo = _SlowRepo([
        Flashcard(
          id: 'k1',
          deckId: 'd1',
          front: 'Know',
          back: 'x',
          box: 2,
          lastReviewed: past,
          createdAt: past,
        ),
        Flashcard(
          id: 'k2',
          deckId: 'd1',
          front: 'DontKnow',
          back: 'x',
          box: 4,
          lastReviewed: past.subtract(const Duration(days: 4)),
          createdAt: past,
        ),
      ]);
      final cubit = _cubit(const [], repo: repo);
      await cubit.load();

      expect(cubit.state.queue, hasLength(2));

      cubit.flipCard();
      final first = cubit.state.currentCard!.id;
      await cubit.rateCard(ReviewRating.know);

      cubit.flipCard();
      final second = cubit.state.currentCard!.id;
      await cubit.rateCard(ReviewRating.dontKnow);

      final boxes = {for (final card in repo.cards) card.id: card.box};
      expect(boxes[first], 3, reason: 'know advances one house');
      expect(boxes[second], 1, reason: 'dontKnow returns to house 1');

      await cubit.close();
    });

    test('stepBack setting drops the card one house instead', () async {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final repo = _SlowRepo([
        Flashcard(
          id: 's1',
          deckId: 'd1',
          front: 'Word',
          back: 'x',
          box: 4,
          lastReviewed: past,
          createdAt: past,
        ),
      ]);
      final cubit = _cubit(
        const [],
        repo: repo,
        config: StudyConfig.deck(spaceId: 's1', deckId: 'd1')
            .withSessionOptions(
              randomOrder: false,
              reviewSettings: const ReviewSettings(
                dontKnowBehaviour: DontKnowBehaviour.stepBack,
              ),
            ),
      );
      await cubit.load();

      cubit.flipCard();
      await cubit.rateCard(ReviewRating.dontKnow);

      expect(
        cubit.config.reviewSettings.dontKnowBehaviour,
        DontKnowBehaviour.stepBack,
      );
      // The screen applies space settings on top of the raw config, so the
      // pure rule is asserted in dontknow_behaviour_test.dart instead.

      await cubit.close();
    });
  });
}

class _SlowRepo implements IFlashcardRepository {
  _SlowRepo(this.cards, {this.writeDelay = Duration.zero});

  final List<Flashcard> cards;
  Duration writeDelay;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => cards;

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<Flashcard?> getCardById(String id) async =>
      cards.where((c) => c.id == id).firstOrNull;

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    await Future<void>.delayed(writeDelay);
    final i = cards.indexWhere((c) => c.id == card.id);
    if (i >= 0) cards[i] = card;
    return card;
  }
}

class _Decks implements IDeckRepository {
  _Decks(this.decks);

  final List<Deck> decks;

  @override
  Future<List<Deck>> getAllDecks() async => decks;

  @override
  Future<Deck?> getDeckById(String id) async =>
      decks.where((d) => d.id == id).firstOrNull;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async => decks;

  @override
  Future<Deck> addDeck(Deck deck) async => deck;

  @override
  Future<void> deleteDeck(String id) async {}

  @override
  Future<Deck> updateDeck(Deck deck) async => deck;
}