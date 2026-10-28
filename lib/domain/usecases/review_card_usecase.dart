import 'dart:math';

import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/entities/review_settings.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

/// Pure Leitner review logic.
///
/// - **know**: advance one house; a success in the last enabled house retires
///   the card to the learned archive.
/// - **dontKnow**: drop back, per [ReviewSettings.dontKnowBehaviour].
class ReviewCardUseCase {
  ReviewCardUseCase(this._repository, this._reviewHistoryRepository);

  final IFlashcardRepository _repository;
  final IReviewHistoryRepository _reviewHistoryRepository;

  Flashcard applyReview(
    Flashcard card,
    ReviewRating rating, {
    DateTime? now,
    LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
    ReviewSettings settings = const ReviewSettings(),
  }) {
    final reviewedAt = now ?? DateTime.now();

    final int newBox = switch (rating) {
      ReviewRating.dontKnow => _boxAfterDontKnow(card.box, settings),
      ReviewRating.know =>
        card.box >= boxes.maxBox
            ? boxes.learnedBox
            : min(boxes.maxBox, card.box + 1),
    };

    return card.copyWith(box: newBox, lastReviewed: reviewedAt);
  }

  /// House to fall back to after a wrong answer.
  ///
  /// [DontKnowBehaviour.stepBack] never goes below house 1, and a card that was
  /// already in house 1 simply stays there either way.
  static int _boxAfterDontKnow(int box, ReviewSettings settings) {
    if (settings.dontKnowBehaviour.goesToFirstHouse) return 1;
    return max(1, box - 1);
  }

  Future<Flashcard> call(
    Flashcard card,
    ReviewRating rating, {
    required String spaceId,
    DateTime? now,
    LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
    ReviewSettings settings = const ReviewSettings(),
  }) async {
    final reviewedAt = now ?? DateTime.now();
    final updated = applyReview(
      card,
      rating,
      now: reviewedAt,
      boxes: boxes,
      settings: settings,
    );
    final saved = await _repository.updateCard(updated);

    await _reviewHistoryRepository.add(
      ReviewLog(
        id: '${reviewedAt.microsecondsSinceEpoch}-${card.id}',
        spaceId: spaceId,
        cardId: card.id,
        deckId: card.deckId,
        rating: rating,
        boxBefore: card.box,
        boxAfter: saved.box,
        reviewedAt: reviewedAt,
      ),
    );

    return saved;
  }

  DateTime computeNextReviewDate(
    Flashcard card,
    ReviewRating rating, {
    DateTime? now,
    LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
    ReviewSettings settings = const ReviewSettings(),
  }) {
    final updated = applyReview(
      card,
      rating,
      now: now,
      boxes: boxes,
      settings: settings,
    );
    return nextReviewDate(updated, boxes: boxes);
  }
}
