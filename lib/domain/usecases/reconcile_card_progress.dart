import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';

/// Puts every card back in step with the history that produced it.
///
/// `Flashcard.box` and `Flashcard.lastReviewed` are **derived**, not authored.
/// They are what the reviews add up to, and they are stored rather than computed
/// on every read only because the app asks "what is due" constantly and cannot
/// afford to fold the whole history each time.
///
/// Stored derived state goes stale. A device that has been offline for a week
/// holds a `box` from a week ago, and a synchronisation that took that number at
/// face value would let it overwrite reviews another device has already recorded
/// — the card would slide backwards through the boxes and the work would be gone
/// with nothing to show it ever happened.
///
/// So a merged collection is corrected: for every card that has been reviewed, the
/// **newest** entry decides the box and the date. Every entry carries the box it
/// produced (`boxAfter`) and when it happened (`reviewedAt`), so the correct answer
/// is always recoverable — the history is the authority and the card is a cache of
/// it.
///
/// ## What is deliberately not done
///
/// A card with no reviews is returned untouched. That is not a detail: there is
/// nothing to rebuild such a card from, and treating "no history" as "box 1" would
/// reset every card somebody had created but not yet studied.
///
/// ## The order is total, not merely by time
///
/// Ties are broken by id. Two entries can share a timestamp — the clock the app
/// reads has millisecond resolution on some platforms — and a rebuild whose result
/// depended on which order the rows happened to arrive in would be a cache that
/// disagreed with itself between runs.
List<Flashcard> reconcileCardProgress({
  required List<Flashcard> cards,
  required List<ReviewLog> reviewLogs,
}) {
  if (cards.isEmpty || reviewLogs.isEmpty) {
    return cards;
  }

  final newest = <String, ReviewLog>{};
  for (final log in reviewLogs) {
    final current = newest[log.cardId];
    if (current == null || _isNewer(log, current)) {
      newest[log.cardId] = log;
    }
  }

  var changed = false;
  final reconciled = <Flashcard>[];

  for (final card in cards) {
    final latest = newest[card.id];
    if (latest == null || !_disagrees(card, latest)) {
      reconciled.add(card);
      continue;
    }
    changed = true;
    reconciled.add(card.copyWith(
      box: latest.boxAfter,
      lastReviewed: latest.reviewedAt,
    ));
  }

  // Returned unchanged when nothing needed correcting, so a caller that compares
  // the result to its input sees the common case for what it is.
  return changed ? reconciled : cards;
}

bool _isNewer(ReviewLog candidate, ReviewLog current) {
  final byTime = candidate.reviewedAt.compareTo(current.reviewedAt);
  if (byTime != 0) {
    return byTime > 0;
  }
  return candidate.id.compareTo(current.id) > 0;
}

bool _disagrees(Flashcard card, ReviewLog latest) =>
    card.box != latest.boxAfter || card.lastReviewed != latest.reviewedAt;
