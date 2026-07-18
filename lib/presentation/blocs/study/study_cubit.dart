import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/utils/due_day_utils.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';

part 'study_state.dart';

class StudyCubit extends Cubit<StudyState> {
  StudyCubit({
    required StudyConfig config,
    required GetDueCardsUseCase getDueCardsUseCase,
    required GetAllDueCardsUseCase getAllDueCardsUseCase,
    required GetCardsByBoxUseCase getCardsByBoxUseCase,
    required ReviewCardUseCase reviewCardUseCase,
    required UpdateCardUseCase updateCardUseCase,
    required DeleteCardUseCase deleteCardUseCase,
    Random? random,
  }) : _config = config,
       _getDueCardsUseCase = getDueCardsUseCase,
       _getAllDueCardsUseCase = getAllDueCardsUseCase,
       _getCardsByBoxUseCase = getCardsByBoxUseCase,
       _reviewCardUseCase = reviewCardUseCase,
       _updateCardUseCase = updateCardUseCase,
       _deleteCardUseCase = deleteCardUseCase,
       _random = random ?? Random(),
       super(const StudyState());

  final StudyConfig _config;
  final GetDueCardsUseCase _getDueCardsUseCase;
  final GetAllDueCardsUseCase _getAllDueCardsUseCase;
  final GetCardsByBoxUseCase _getCardsByBoxUseCase;
  final ReviewCardUseCase _reviewCardUseCase;
  final UpdateCardUseCase _updateCardUseCase;
  final DeleteCardUseCase _deleteCardUseCase;
  final Random _random;
  bool _isRating = false;

  Future<void> load() async {
    emit(state.copyWith(status: StudyStatus.loading));
    try {
      final List<Flashcard> cards;

      if (_config.boxNumber != null) {
        final boxCards = await _getCardsByBoxUseCase(
          _config.boxNumber!,
          deckId: _config.deckId,
        );
        cards = filterCardsByDueDay(
          boxCards,
          dueDay: _config.dueDay,
          overdueOnly: _config.overdueOnly,
        );
      } else if (_config.allDue) {
        cards = await _getAllDueCardsUseCase();
      } else {
        cards = await _getDueCardsUseCase(_config.deckId!);
      }

      final queue = List<Flashcard>.of(cards);
      if (_config.randomOrder) {
        queue.shuffle(_random);
      }

      emit(
        state.copyWith(
          status: StudyStatus.ready,
          queue: queue,
          currentIndex: 0,
          isFlipped: false,
          isAllDue: _config.allDue,
          boxNumber: _config.boxNumber,
          reversed: _config.reversed,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: StudyStatus.error, errorMessage: e.toString()),
      );
    }
  }

  void flipCard() {
    if (state.currentCard == null || state.isFinished) return;
    emit(state.copyWith(isFlipped: !state.isFlipped));
  }

  void toggleReversed() {
    if (!state.isFreeReview) return;
    emit(state.copyWith(isFlipped: false, reversed: !state.reversed));
  }

  Future<void> resetCurrentCardToBox1() async {
    if (!state.isFreeReview) return;
    final card = state.currentCard;
    if (card == null || card.box == 1) return;

    final updated = await _updateCardUseCase(card.copyWith(box: 1));
    final queue = List<Flashcard>.from(state.queue);
    queue[state.currentIndex] = updated;
    emit(state.copyWith(queue: queue));
  }

  Future<void> rateCard(ReviewRating rating) async {
    final card = state.currentCard;
    if (_isRating || card == null || !state.isFlipped) return;

    _isRating = true;
    try {
      // Free review is a preview session: answers must not change the card's
      // box, last-reviewed date, normal schedule, or review statistics.
      if (!state.isFreeReview) {
        await _reviewCardUseCase(card, rating);
      }
      emit(
        state.copyWith(currentIndex: state.currentIndex + 1, isFlipped: false),
      );
    } finally {
      _isRating = false;
    }
  }

  Future<void> updateCurrentCard(String front, String back) async {
    final card = state.currentCard;
    if (card == null) return;

    final updated = await _updateCardUseCase(
      card.copyWith(front: front.trim(), back: back.trim()),
    );

    final queue = List<Flashcard>.from(state.queue);
    queue[state.currentIndex] = updated;
    emit(state.copyWith(queue: queue));
  }

  Future<void> deleteCurrentCard() async {
    final card = state.currentCard;
    if (card == null) return;

    await _deleteCardUseCase(card.id);

    final queue = List<Flashcard>.from(state.queue)
      ..removeAt(state.currentIndex);
    emit(state.copyWith(queue: queue, isFlipped: false));
  }
}
