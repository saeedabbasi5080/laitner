import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
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
      5,
    );
  });

  test('ReviewCardUseCase persists a review log', () async {
    final history = _FakeReviewHistoryRepository();
    final useCase = ReviewCardUseCase(_FakeFlashcardRepository(), history);
    final now = DateTime(2026, 7, 13);
    final card = Flashcard(
      id: '1',
      deckId: 'd1',
      front: 'Test',
      back: 'Answer',
      box: 2,
      createdAt: now,
    );

    await useCase(card, ReviewRating.know, now: now);

    expect(history.logs, hasLength(1));
    expect(history.logs.single.boxBefore, 2);
    expect(history.logs.single.boxAfter, 3);
    expect(history.logs.single.rating, ReviewRating.know);
  });
}

class _FakeFlashcardRepository implements IFlashcardRepository {
  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<List<Flashcard>> getAllCards() async => [];

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => [];

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;
}

class _FakeReviewHistoryRepository implements IReviewHistoryRepository {
  final List<ReviewLog> logs = [];

  @override
  Future<void> add(ReviewLog log) async => logs.add(log);

  @override
  Future<List<ReviewLog>> getAll() async => logs;
}
