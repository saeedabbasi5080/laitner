import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/presentation/blocs/statistics/statistics_cubit.dart';

void main() {
  test('StatisticsCubit calculates all learning metrics', () async {
    final now = DateTime.now();
    final cards = [
      Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: '1',
        back: '1',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c2',
        deckId: 'd1',
        front: '2',
        back: '2',
        box: 4,
        lastReviewed: now,
        createdAt: now,
      ),
      Flashcard(
        id: 'c3',
        deckId: 'd1',
        front: '3',
        back: '3',
        box: 5,
        lastReviewed: now.subtract(const Duration(days: 14)),
        createdAt: now,
      ),
    ];
    final logs = [
      _log('l1', ReviewRating.know, now),
      _log('l2', ReviewRating.dontKnow, now.subtract(const Duration(days: 1))),
      _log('l3', ReviewRating.know, now.subtract(const Duration(days: 2))),
      _log('l4', ReviewRating.know, now.subtract(const Duration(days: 4))),
    ];
    final cubit = StatisticsCubit(
      _FakeFlashcardRepository(cards),
      _FakeReviewHistoryRepository(logs),
      'space-1',
    );

    await cubit.load();

    expect(cubit.state.status, StatisticsStatus.loaded);
    expect(cubit.state.boxCounts, {1: 1, 2: 0, 3: 0, 4: 1, 5: 1});
    expect(cubit.state.totalCards, 3);
    expect(cubit.state.masteredCards, 0);
    expect(cubit.state.totalReviews, 4);
    expect(cubit.state.knowCount, 3);
    expect(cubit.state.dontKnowCount, 1);
    expect(cubit.state.currentStreak, 3);
    expect(cubit.state.bestStreak, 3);
    expect(cubit.state.dailyReviewCounts, [0, 0, 1, 0, 1, 1, 1]);
    expect(cubit.state.futureDueCounts.first, 1);
    expect(cubit.state.futureDueCounts[1], 1);

    await cubit.close();
  });
}

ReviewLog _log(String id, ReviewRating rating, DateTime reviewedAt) =>
    ReviewLog(
      id: id,
      spaceId: 'space-1',
      cardId: 'card-$id',
      deckId: 'd1',
      rating: rating,
      boxBefore: 1,
      boxAfter: rating == ReviewRating.know ? 2 : 1,
      reviewedAt: reviewedAt,
    );

class _FakeFlashcardRepository implements IFlashcardRepository {
  _FakeFlashcardRepository(this.cards);

  final List<Flashcard> cards;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => cards;

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;
}

class _FakeReviewHistoryRepository implements IReviewHistoryRepository {
  _FakeReviewHistoryRepository(this.logs);

  final List<ReviewLog> logs;

  @override
  Future<void> add(ReviewLog log) async => logs.add(log);

  @override
  Future<List<ReviewLog>> getAll() async => logs;

  @override
  Future<List<ReviewLog>> getBySpaceId(String spaceId) async => logs;
}
