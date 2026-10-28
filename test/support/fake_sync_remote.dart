import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/repositories/sync_remote.dart';

/// A server that lives in a field.
///
/// It behaves the way the real one is specified to: `replaceCollection` swaps
/// the structure, `appendReviewLogs` accumulates, and an entry whose id is
/// already held is upserted rather than duplicated. A fake that merely recorded
/// what it was handed could not show that a second sync does not grow the
/// history.
class FakeSyncRemote implements SyncRemote {
  FakeSyncRemote({SyncCollection? stored})
      : _stored = stored ?? const SyncCollection.empty();

  SyncCollection _stored;

  /// What the server currently holds.
  SyncCollection get stored => _stored;

  int replaceCalls = 0;
  int appendCalls = 0;
  int pullCalls = 0;

  /// The arguments of the most recent call, empty when it never happened.
  List<LearningSpace> replacedSpaces = const [];
  List<Deck> replacedDecks = const [];
  List<Flashcard> replacedCards = const [];
  List<ReviewLog> appendedLogs = const [];

  /// Makes the next call of this kind throw, to prove what does and does not
  /// happen afterwards.
  bool failReplace = false;
  bool failAppend = false;
  bool failPull = false;

  @override
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
  }) async {
    replaceCalls++;
    replacedSpaces = List.of(spaces);
    replacedDecks = List.of(decks);
    replacedCards = List.of(cards);

    if (failReplace) throw StateError('replaceCollection refused');

    _stored = SyncCollection(
      spaces: spaces,
      decks: decks,
      cards: cards,
      reviewLogs: _stored.reviewLogs,
    );
  }

  @override
  Future<void> appendReviewLogs(List<ReviewLog> logs) async {
    appendCalls++;
    appendedLogs = List.of(logs);

    if (failAppend) throw StateError('appendReviewLogs refused');

    // Upsert by id, so sending the boundary entry again is not a second row.
    // This is the property that makes the `>=` watermark comparison safe.
    final merged = <String, ReviewLog>{
      for (final log in _stored.reviewLogs) log.id: log,
      for (final log in logs) log.id: log,
    }.values.toList()
      ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));

    _stored = SyncCollection(
      spaces: _stored.spaces,
      decks: _stored.decks,
      cards: _stored.cards,
      reviewLogs: merged,
    );
  }

  @override
  Future<SyncCollection> pull() async {
    pullCalls++;
    if (failPull) throw StateError('pull refused');
    return _stored;
  }
}
