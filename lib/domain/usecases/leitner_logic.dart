import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/flashcard.dart';

/// Pure Leitner scheduling logic — no Flutter or DB dependencies.
///
/// New cards (`lastReviewed == null`) use [Flashcard.createdAt] as the
/// schedule anchor and become due after Box 1's interval (1 day), matching
/// the standard Leitner setup of starting reviews the day after cards are added.
bool isCardDue(Flashcard card, DateTime now) {
  return !now.isBefore(nextReviewDate(card));
}

DateTime nextReviewDate(Flashcard card) {
  final reference = card.lastReviewed ?? card.createdAt;
  final boxIndex = card.box.clamp(0, maxBox);
  final intervalDays = boxIntervalsDays[boxIndex];
  return reference.add(Duration(days: intervalDays));
}
