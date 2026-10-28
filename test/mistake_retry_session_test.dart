import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
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

final _past = DateTime.now().subtract(const Duration(days: 3));

Flashcard _card(String id, {String deckId = 'd1', int box = 2}) => Flashcard(
      id: id,
      deckId: deckId,
      front: 'Word-$id',
      back: 'x',
      box: box,
      lastReviewed: _past,
      createdAt: _past,
    );

class _Repo implements IFlashcardRepository {
  _Repo(this.cards);

  final List<Flashcard> cards;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((c) => c.deckId == deckId).toList();

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

void main() {
  late _Repo repo;
  late _Decks decks;

  StudyCubit build(StudyConfig config, List<Flashcard> cards) {
    repo = _Repo(cards);
    decks = _Decks([
      Deck(
        id: 'd1',
        spaceId: 's1',
        name: 'Deck',
        color: DeckColor.mint,
        createdAt: _past,
      ),
    ]);
    return StudyCubit(
      config: config,
      getDueCardsUseCase: GetDueCardsUseCase(repo),
      getAllDueCardsUseCase: GetAllDueCardsUseCase(repo),
      getSpaceCardsUseCase: GetSpaceCardsUseCase(repo),
      getCardsByBoxUseCase: GetCardsByBoxUseCase(repo),
      getCardsByDeckUseCase: GetCardsByDeckUseCase(repo),
      getDecksUseCase: GetDecksUseCase(decks),
      reviewCardUseCase: ReviewCardUseCase(repo, FakeReviewHistoryRepository()),
      updateCardUseCase: UpdateCardUseCase(repo),
      deleteCardUseCase: DeleteCardUseCase(repo),
    );
  }

  /// Runs a whole session, failing every card, and returns the missed ids.
  Future<List<String>> runAndFail(StudyCubit cubit) async {
    await cubit.load();
    while (!cubit.state.isFinished && cubit.state.queue.isNotEmpty) {
      cubit.flipCard();
      await cubit.rateCard(ReviewRating.dontKnow);
    }
    return cubit.state.mistakeCardIds;
  }

  group('retrying the mistakes of a deck session', () {
    test('brings back exactly the cards that were missed', () async {
      final first = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
        [_card('c1'), _card('c2'), _card('c3')],
      );

      final missed = await runAndFail(first);
      expect(missed, hasLength(3));
      await first.close();

      // This is the path the finished screen's button takes.
      final retry = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1').withMistakeRetry(missed),
        List.of(repo.cards),
      );
      await retry.load();

      expect(retry.state.queue, hasLength(3));
      expect(
        retry.state.queue.map((c) => c.id).toSet(),
        missed.toSet(),
      );

      await retry.close();
    });

    test('the missed cards are no longer due, and it does not matter',
        () async {
      final first = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
        [_card('c1'), _card('c2')],
      );
      final missed = await runAndFail(first);
      await first.close();

      // Failing a card sends it back to the first house with a fresh date, so
      // the ordinary due-card query genuinely returns nothing. The retry has to
      // work anyway, because retrying is the whole point of the button.
      final dueNow = await GetDueCardsUseCase(repo)('d1');
      expect(
        dueNow.map((c) => c.id).toSet().intersection(missed.toSet()),
        isEmpty,
        reason: 'a just-failed card is not due',
      );

      final retry = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1').withMistakeRetry(missed),
        List.of(repo.cards),
      );
      await retry.load();

      expect(retry.state.queue, hasLength(2));
      await retry.close();
    });
  });

  group('retrying the mistakes of a whole-space session', () {
    test('brings the cards back even though no deck was in play', () async {
      // A space-wide session carries no deck id, which used to send the retry
      // through the due-cards query and come back empty — the button reported
      // "nothing to review" on exactly the session most likely to have
      // mistakes.
      final first = build(
        StudyConfig.allDue(spaceId: 's1'),
        [_card('c1'), _card('c2'), _card('c3')],
      );

      final missed = await runAndFail(first);
      expect(missed, hasLength(3));
      await first.close();

      final retry = build(
        StudyConfig.allDue(spaceId: 's1')
            .withMistakeRetry(missed),
        List.of(repo.cards),
      );
      await retry.load();

      expect(retry.state.queue, hasLength(3));
      await retry.close();
    });

    test('still leaves cards from other decks alone', () async {
      repo = _Repo([_card('c1', deckId: 'd1'), _card('c2', deckId: 'd2')]);
      final retry = build(
        StudyConfig.allDue(spaceId: 's1')
            .withMistakeRetry(const ['c1']),
        List.of(repo.cards),
      );

      await retry.load();

      expect(retry.state.queue.map((c) => c.id), ['c1']);
      await retry.close();
    });
  });

  group('the retry run is still a normal session', () {
    test('answers reschedule the cards as usual', () async {
      final first = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
        [_card('c1')],
      );
      final missed = await runAndFail(first);
      await first.close();

      final cards = List.of(repo.cards);
      final retry = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1').withMistakeRetry(missed),
        cards,
      );
      await retry.load();

      retry.flipCard();
      await retry.rateCard(ReviewRating.know);

      // It went from house 1 (after failing) up to house 2.
      expect(cards.single.box, 2);
      await retry.close();
    });

    test('a retry that misses again keeps the card on the list', () async {
      final first = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
        [_card('c1')],
      );
      final missed = await runAndFail(first);
      await first.close();

      final cards = List.of(repo.cards);
      final retry = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1').withMistakeRetry(missed),
        cards,
      );
      await retry.load();

      retry.flipCard();
      await retry.rateCard(ReviewRating.dontKnow);

      expect(retry.state.mistakeCardIds, ['c1']);
      await retry.close();
    });

    test('an empty mistake list is not treated as a retry', () async {
      // Guards the opposite mistake: a normal session must not silently become
      // an empty retry.
      final cubit = build(
        StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
        [_card('c1'), _card('c2')],
      );

      await cubit.load();
      expect(cubit.state.queue, hasLength(2));
      expect(cubit.config.isMistakeRetry, isFalse);

      await cubit.close();
    });
  });
}