import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';

void main() {
  test('ReviewCardUseCase applies know/dontKnow rules', () {
    final useCase = ReviewCardUseCase(
      _FakeFlashcardRepository(),
      _FakeReviewHistoryRepository(),
    );
    final now = DateTime(2026, 7, 13);

    final card = Flashcard(
      id: '1',
      deckId: 'd1',
      front: 'Test',
      back: 'Answer',
      box: 2,
      createdAt: now,
    );

    expect(useCase.applyReview(card, ReviewRating.dontKnow, now: now).box, 1);
    expect(useCase.applyReview(card, ReviewRating.know, now: now).box, 3);
    expect(
      useCase
          .applyReview(card.copyWith(box: 5), ReviewRating.know, now: now)
          .box,
      6,
    );
  });

  test('ReviewCardUseCase persists a review log', () async {
    final history = _FakeReviewHistoryRepository();
    final repository = _FakeFlashcardRepository();
    final useCase = ReviewCardUseCase(repository, history);
    final now = DateTime(2026, 7, 13);
    final card = Flashcard(
      id: '1',
      deckId: 'd1',
      front: 'Test',
      back: 'Answer',
      box: 2,
      createdAt: now,
    );

    await useCase(card, ReviewRating.know, spaceId: 'space-1', now: now);

    expect(history.logs, hasLength(1));
    expect(history.logs.single.boxBefore, 2);
    expect(history.logs.single.boxAfter, 3);
    expect(history.logs.single.rating, ReviewRating.know);
    expect(repository.updatedCard?.box, 3);
    expect(repository.updatedCard?.lastReviewed, now);
  });

  test('new Box 1 card becomes due at next local midnight', () {
    final card = Flashcard(
      id: 'midnight',
      deckId: 'd1',
      front: 'Test',
      back: 'Answer',
      box: 1,
      createdAt: DateTime(2026, 7, 16, 22),
    );

    expect(isCardDue(card, DateTime(2026, 7, 16, 23, 59)), isFalse);
    expect(isCardDue(card, DateTime(2026, 7, 17)), isTrue);
    expect(nextReviewDate(card), DateTime(2026, 7, 17));
  });
}

class _FakeFlashcardRepository implements IFlashcardRepository {
  Flashcard? updatedCard;

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<List<Flashcard>> getAllCards() async => [];

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => [];

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => [];

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    updatedCard = card;
    return card;
  }
}

class _FakeReviewHistoryRepository implements IReviewHistoryRepository {
  final List<ReviewLog> logs = [];

  @override
  Future<void> add(ReviewLog log) async => logs.add(log);

  @override
  Future<List<ReviewLog>> getAll() async => logs;

  @override
  Future<List<ReviewLog>> getBySpaceId(String spaceId) async => logs;
}
