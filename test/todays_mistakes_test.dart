import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/get_todays_mistakes_usecase.dart';

import 'support/fake_review_history_repository.dart';

Flashcard _card(String id) => Flashcard(
      id: id,
      deckId: 'd1',
      front: 'Word-$id',
      back: 'x',
      box: 1,
      createdAt: DateTime(2026, 3, 1),
    );

ReviewLog _log(
  String id,
  String cardId,
  ReviewRating rating, {
  required DateTime at,
  String deckId = 'd1',
  String spaceId = 's1',
}) {
  return ReviewLog(
    id: id,
    spaceId: spaceId,
    cardId: cardId,
    deckId: deckId,
    rating: rating,
    boxBefore: 1,
    boxAfter: 2,
    reviewedAt: at,
  );
}

void main() {
  final today = DateTime(2026, 3, 11, 10);
  late FakeReviewHistoryRepository history;
  late _Repo cards;
  late GetTodaysMistakesUseCase useCase;

  setUp(() {
    history = FakeReviewHistoryRepository();
    cards = _Repo([_card('c1'), _card('c2'), _card('c3')]);
    useCase = GetTodaysMistakesUseCase(cards, history);
  });

  Future<List<MistakeCard>> run({String deckId = 'd1'}) =>
      useCase(spaceId: 's1', deckId: deckId, now: today);

  test('a card answered wrong today is a mistake', () async {
    history.logs.add(
      _log('l1', 'c1', ReviewRating.dontKnow, at: today),
    );

    final mistakes = await run();
    expect(mistakes.map((m) => m.front), ['Word-c1']);
    expect(mistakes.single.wrongCount, 1);
  });

  test('a card answered correctly today is not a mistake', () async {
    history.logs.add(_log('l1', 'c1', ReviewRating.know, at: today));

    expect(await run(), isEmpty);
  });

  test('yesterday’s mistakes do not leak into today', () async {
    history.logs.add(
      _log('l1', 'c1', ReviewRating.dontKnow, at: addDays(today, -1)),
    );

    expect(await run(), isEmpty);
  });

  test('a late-evening review still counts as today', () async {
    history.logs.add(
      _log('l1', 'c1', ReviewRating.dontKnow, at: DateTime(2026, 3, 11, 23, 59)),
    );

    expect(await run(), hasLength(1));
  });

  test('a review just after midnight belongs to the new day', () async {
    history.logs.add(
      _log('l1', 'c1', ReviewRating.dontKnow, at: DateTime(2026, 3, 12, 0, 5)),
    );

    // Asking for the 11th must not see it; asking for the 12th must.
    expect(await run(), isEmpty);
    final next = await useCase(
      spaceId: 's1',
      deckId: 'd1',
      now: DateTime(2026, 3, 12, 9),
    );
    expect(next, hasLength(1));
  });

  test('a card wrong then right still counts', () async {
    history.logs
      ..add(_log('l1', 'c1', ReviewRating.dontKnow, at: today))
      ..add(_log('l2', 'c1', ReviewRating.know, at: today));

    // The point is to drill what actually caused trouble today.
    expect(await run(), hasLength(1));
  });

  test('counts repeat wrongs so the worst cards come first', () async {
    history.logs
      ..add(_log('l1', 'c1', ReviewRating.dontKnow, at: today))
      ..add(_log('l2', 'c1', ReviewRating.dontKnow, at: today))
      ..add(_log('l3', 'c2', ReviewRating.dontKnow, at: today));

    final mistakes = await run();
    expect(mistakes.first.front, 'Word-c1');
    expect(mistakes.first.wrongCount, 2);
    expect(mistakes.last.wrongCount, 1);
  });

  test('mistakes in another deck are ignored', () async {
    history.logs.add(
      _log(
        'l1',
        'c1',
        ReviewRating.dontKnow,
        at: today,
        deckId: 'other-deck',
      ),
    );

    expect(await run(), isEmpty);
  });

  test('mistakes in another space are ignored', () async {
    history.logs.add(
      _log(
        'l1',
        'c1',
        ReviewRating.dontKnow,
        at: today,
        spaceId: 'other-space',
      ),
    );

    expect(await run(), isEmpty);
  });

  test('a deleted card is not offered for review', () async {
    history.logs.add(
      _log('l1', 'gone', ReviewRating.dontKnow, at: today),
    );

    // c3 is the only id absent from the repository in this test's card list.
    expect(await run(), isEmpty);
  });

  test('no history means no mistakes', () async {
    expect(await run(), isEmpty);
  });

  test('a day boundary shifts what counts as today', () async {
    // Anki treats "the day" as starting at 04:00 by default.
    history.logs.add(
      _log('l1', 'c1', ReviewRating.dontKnow, at: DateTime(2026, 3, 11, 3, 30)),
    );

    // At 10:00 with a 04:00 boundary, 03:30 already belongs to the previous
    // day, so the mistake is not in today's list.
    final at10 = await useCase(
      spaceId: 's1',
      deckId: 'd1',
      now: today,
      dayBoundary: const Duration(hours: 4),
    );
    expect(at10, isEmpty);

    // At 02:00 that same morning it is still "today".
    final at2 = await useCase(
      spaceId: 's1',
      deckId: 'd1',
      now: DateTime(2026, 3, 11, 2),
      dayBoundary: const Duration(hours: 4),
    );
    expect(at2, hasLength(1));
  });
}

class _Repo implements IFlashcardRepository {
  _Repo(this.cards);

  final List<Flashcard> cards;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => cards;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

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
  Future<Flashcard> updateCard(Flashcard card) async => card;
}