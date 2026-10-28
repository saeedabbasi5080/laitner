import 'package:recall/core/utils/day_key.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';

/// One card the user got wrong today, together with why it is worth retrying.
class MistakeCard {
  const MistakeCard({required this.card, required this.deckId, required this.wrongCount});

  final Flashcard card;
  final String deckId;

  /// How many times this card was answered wrongly today. A card answered
  /// wrong twice is more urgent than one answered wrong once.
  final int wrongCount;

  String get front => card.front;
}

/// Collects the cards that were answered wrongly today so they can be reviewed
/// again straight away.
///
/// Deliberately built on the review log rather than on a separate "mistakes"
/// table: the log is already the source of truth for every answer, so this
/// cannot drift out of step with the statistics screen.
///
/// A card that was wrong and then answered correctly later the same day still
/// counts as a mistake, because the point of the exercise is to drill what
/// actually caused trouble rather than only what stayed wrong at midnight.
class GetTodaysMistakesUseCase {
  const GetTodaysMistakesUseCase(
  IFlashcardRepository flashcardRepository,
  IReviewHistoryRepository reviewHistoryRepository,
) : _cards = flashcardRepository,
     _history = reviewHistoryRepository;

  final IFlashcardRepository _cards;
  final IReviewHistoryRepository _history;

  Future<List<MistakeCard>> call({
    required String spaceId,
    required String deckId,
    DateTime? now,
    Duration dayBoundary = Duration.zero,
  }) async {
    final reference = now ?? DateTime.now();
    // The day starts at the boundary, not at midnight, so the window must too.
    // Using midnight would let the hours before the boundary leak in from the
    // previous day.
    final today = dayStartWithBoundary(reference, dayBoundary);
    final from = today.add(dayBoundary);
    final logs = await _history.getInRange(
      spaceId: spaceId,
      from: from,
      to: addDays(today, 1).add(dayBoundary),
    );

    if (logs.isEmpty) return const [];

    // Count only the wrong answers, keyed by the card they belong to.
    final wrongCounts = <String, int>{};
    for (final log in logs) {
      if (log.rating != ReviewRating.dontKnow) continue;
      if (log.deckId != deckId) continue;
      wrongCounts[log.cardId] = (wrongCounts[log.cardId] ?? 0) + 1;
    }

    if (wrongCounts.isEmpty) return const [];

    final cards = await _cards.getCardsByDeckId(deckId);
    final byId = {for (final card in cards) card.id: card};

    final mistakes = <MistakeCard>[];
    for (final entry in wrongCounts.entries) {
      final card = byId[entry.key];
      // A card deleted after being answered has nothing left to review.
      if (card == null) continue;
      mistakes.add(
        MistakeCard(card: card, deckId: deckId, wrongCount: entry.value),
      );
    }

    // Most-practised problems first, then alphabetically for a stable order.
    mistakes.sort((a, b) {
      final byCount = b.wrongCount.compareTo(a.wrongCount);
      if (byCount != 0) return byCount;
      return a.front.compareTo(b.front);
    });

    return mistakes;
  }
}