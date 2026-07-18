import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/due_day_utils.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';

void main() {
  test('free review answer does not reschedule or log card', () async {
    final now = DateTime.now();
    final card = Flashcard(
      id: 'c1',
      deckId: 'd1',
      front: 'hello',
      back: 'سلام',
      box: 3,
      lastReviewed: now,
      createdAt: now,
    );
    final repository = _FakeFlashcardRepository([card]);
    final history = _FakeReviewHistoryRepository();
    final cubit = StudyCubit(
      config: const StudyConfig.byBox(3),
      getDueCardsUseCase: GetDueCardsUseCase(repository),
      getAllDueCardsUseCase: GetAllDueCardsUseCase(repository),
      getCardsByBoxUseCase: GetCardsByBoxUseCase(repository),
      reviewCardUseCase: ReviewCardUseCase(repository, history),
      updateCardUseCase: UpdateCardUseCase(repository),
      deleteCardUseCase: DeleteCardUseCase(repository),
    );

    await cubit.load();
    cubit.flipCard();
    await cubit.rateCard(ReviewRating.know);

    expect(repository.updateCount, 0);
    expect(history.logs, isEmpty);
    expect(cubit.state.isFinished, isTrue);
    expect(card.box, 3);
    expect(card.lastReviewed, now);

    await cubit.close();
  });

  test('cards are grouped into overdue, today, and future due days', () {
    final today = DateTime(2026, 7, 15);
    final cards = [
      _card(
        'overdue',
        box: 1,
        reviewedAt: today.subtract(const Duration(days: 2)),
      ),
      _card(
        'today',
        box: 1,
        reviewedAt: today.subtract(const Duration(days: 1)),
      ),
      _card('tomorrow', box: 1, reviewedAt: today),
    ];

    final buckets = groupCardsByDueDay(cards, now: today);

    expect(buckets, hasLength(3));
    expect(buckets[0].isOverdue, isTrue);
    expect(dueDayLabel(buckets[1], now: today), 'امروز');
    expect(dueDayLabel(buckets[2], now: today), 'فردا');
    expect(
      filterCardsByDueDay(cards, dueDay: today, now: today).single.id,
      'today',
    );
  });

  test('random order shuffles the complete free-review queue once', () async {
    final now = DateTime.now();
    final cards = List.generate(
      8,
      (index) => _card('card-$index', box: 3, reviewedAt: now),
    );
    final repository = _FakeFlashcardRepository(cards);
    final history = _FakeReviewHistoryRepository();
    final cubit = StudyCubit(
      config: StudyConfig.byBox(3).withRandomOrder(true),
      getDueCardsUseCase: GetDueCardsUseCase(repository),
      getAllDueCardsUseCase: GetAllDueCardsUseCase(repository),
      getCardsByBoxUseCase: GetCardsByBoxUseCase(repository),
      reviewCardUseCase: ReviewCardUseCase(repository, history),
      updateCardUseCase: UpdateCardUseCase(repository),
      deleteCardUseCase: DeleteCardUseCase(repository),
      random: Random(42),
    );

    await cubit.load();

    final originalIds = cards.map((card) => card.id).toList();
    final shuffledIds = cubit.state.queue.map((card) => card.id).toList();
    expect(shuffledIds, isNot(originalIds));
    expect(shuffledIds.toSet(), originalIds.toSet());

    await cubit.close();
  });
}

Flashcard _card(String id, {required int box, required DateTime reviewedAt}) {
  return Flashcard(
    id: id,
    deckId: 'd1',
    front: id,
    back: id,
    box: box,
    lastReviewed: reviewedAt,
    createdAt: reviewedAt,
  );
}

class _FakeFlashcardRepository implements IFlashcardRepository {
  _FakeFlashcardRepository(this.cards);

  final List<Flashcard> cards;
  int updateCount = 0;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((card) => card.deckId == deckId).toList();

  @override
  Future<Flashcard?> getCardById(String id) async =>
      cards.where((card) => card.id == id).firstOrNull;

  @override
  Future<Flashcard> addCard(Flashcard card) async {
    cards.add(card);
    return card;
  }

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    updateCount++;
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {}
}

class _FakeReviewHistoryRepository implements IReviewHistoryRepository {
  final List<ReviewLog> logs = [];

  @override
  Future<void> add(ReviewLog log) async => logs.add(log);

  @override
  Future<List<ReviewLog>> getAll() async => logs;
}
