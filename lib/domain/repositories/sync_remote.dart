import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';

/// The server's half of synchronisation.
///
/// Deliberately three operations with unambiguous meanings rather than one
/// `push` that takes everything. An earlier draft had `push(spaces, decks,
/// cards, reviewLogs)`, and it could not answer a question the server must
/// answer every time: does an empty list mean "this device has nothing to say
/// about the structure", or "erase the structure"? Those are opposite
/// instructions and they arrived in the same shape. A fresh device signing in
/// would have erased the account. Splitting the calls removes the question.
///
/// The server holds the user's collection and does not merge. That is only sound
/// because a user is expected to be on one surface at a time — the same
/// restriction that makes the whole feature tractable. Were two surfaces able to
/// write at once, this would need revisions and conflict rules and would be
/// several times its size.
abstract interface class SyncRemote {
  /// Makes the server's structure match these lists.
  ///
  /// A replacement, and only called when this device actually has a structure to
  /// state. Review history is untouched by this call — it is not structure, and
  /// a user who has reviewed nothing yet must not lose the history they built on
  /// another device.
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
  });

  /// Adds review entries.
  ///
  /// Additions, never a replacement: an implementation must not treat the list
  /// as the whole history, or a sync would delete everything reviewed elsewhere.
  /// An entry whose id is already held is updated rather than duplicated, which
  /// is what makes it safe to send the same entry twice.
  Future<void> appendReviewLogs(List<ReviewLog> logs);

  /// Everything the server holds.
  ///
  /// Returns the whole history, not a delta. Sending it all on every pull is the
  /// one thing here that does not scale, and it is left that way on purpose: a
  /// pull happens on a device that has just been signed in and therefore has
  /// nothing, which is exactly when it needs everything. A delta can follow once
  /// the upload watermark has proved itself.
  Future<SyncCollection> pull();
}

/// A collection as it travels.
///
/// A plain carrier, with no behaviour of its own — it exists so the pull side has
/// a named thing to return rather than a four-element record, and so a test can
/// build one without naming the transport.
class SyncCollection {
  const SyncCollection({
    required this.spaces,
    required this.decks,
    required this.cards,
    required this.reviewLogs,
  });

  const SyncCollection.empty()
      : spaces = const [],
        decks = const [],
        cards = const [],
        reviewLogs = const [];

  final List<LearningSpace> spaces;
  final List<Deck> decks;
  final List<Flashcard> cards;
  final List<ReviewLog> reviewLogs;

  bool get isEmpty =>
      spaces.isEmpty && decks.isEmpty && cards.isEmpty && reviewLogs.isEmpty;
}
