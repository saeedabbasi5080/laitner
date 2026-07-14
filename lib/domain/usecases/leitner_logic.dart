import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/flashcard.dart';

/// Pure Leitner scheduling logic — no Flutter or DB dependencies.
bool isCardDue(Flashcard card, DateTime now) {
  if (card.lastReviewed == null) return true;

  final boxIndex = card.box.clamp(0, maxBox);
  final intervalDays = boxIntervalsDays[boxIndex];
  final dueAt = card.lastReviewed!.add(Duration(days: intervalDays));

  return !now.isBefore(dueAt);
}

DateTime nextReviewDate(Flashcard card) {
  if (card.lastReviewed == null) return DateTime.now();

  final boxIndex = card.box.clamp(0, maxBox);
  final intervalDays = boxIntervalsDays[boxIndex];
  return card.lastReviewed!.add(Duration(days: intervalDays));
}
