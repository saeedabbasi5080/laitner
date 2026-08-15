import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/flashcard.dart';

/// Pure Leitner scheduling logic — no Flutter or DB dependencies.
///
/// Scheduling uses local calendar days, not exact 24-hour durations.
///
/// A card created at 22:00 in Box 1 therefore becomes due at 00:00 on the next
/// local day. New cards use [Flashcard.createdAt] as their schedule anchor.
bool isCardDue(Flashcard card, DateTime now) {
  if (card.isLearned) return false;
  return !now.isBefore(nextReviewDate(card));
}

DateTime nextReviewDate(Flashcard card) {
  final reference = card.lastReviewed ?? card.createdAt;
  final boxIndex = card.box.clamp(0, maxBox);
  final intervalDays = boxIntervalsDays[boxIndex];
  return DateTime(
    reference.year,
    reference.month,
    reference.day + intervalDays,
  );
}
