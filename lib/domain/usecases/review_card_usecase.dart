import 'dart:math';

import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

/// Pure Leitner review logic.
///
/// - **know**: advance one box (max 5).
/// - **dontKnow**: reset to box 1.
class ReviewCardUseCase {
  ReviewCardUseCase(this._repository);

  final IFlashcardRepository _repository;

  Flashcard applyReview(Flashcard card, ReviewRating rating, {DateTime? now}) {
    final reviewedAt = now ?? DateTime.now();

    final int newBox = switch (rating) {
      ReviewRating.dontKnow => 1,
      ReviewRating.know => min(maxBox, card.box + 1),
    };

    return card.copyWith(
      box: newBox,
      lastReviewed: reviewedAt,
    );
  }

  Future<Flashcard> call(
    Flashcard card,
    ReviewRating rating, {
    DateTime? now,
  }) async {
    final updated = applyReview(card, rating, now: now);
    return _repository.updateCard(updated);
  }

  DateTime computeNextReviewDate(
    Flashcard card,
    ReviewRating rating, {
    DateTime? now,
  }) {
    final updated = applyReview(card, rating, now: now);
    return nextReviewDate(updated);
  }
}
