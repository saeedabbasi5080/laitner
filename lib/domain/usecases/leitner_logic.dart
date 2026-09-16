import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';

/// Pure Leitner scheduling logic — no Flutter or DB dependencies.
///
/// Scheduling uses local calendar days, not exact 24-hour durations.
///
/// A card created at 22:00 in Box 1 therefore becomes due at 00:00 on the next
/// local day. New cards use [Flashcard.createdAt] as their schedule anchor.
bool isCardDue(
  Flashcard card,
  DateTime now, {
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  if (boxes.isLearnedBox(card.box)) return false;
  return !now.isBefore(nextReviewDate(card, boxes: boxes));
}

DateTime nextReviewDate(
  Flashcard card, {
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  final reference = card.lastReviewed ?? card.createdAt;
  final intervalDays = boxes.intervalDays(card.box);
  return DateTime(
    reference.year,
    reference.month,
    reference.day + intervalDays,
  );
}
