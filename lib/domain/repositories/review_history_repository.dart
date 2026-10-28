import 'package:recall/domain/entities/review_log.dart';

abstract class IReviewHistoryRepository {
  Future<List<ReviewLog>> getAll();

  Future<List<ReviewLog>> getBySpaceId(String spaceId);

  /// Number of reviews ever recorded for [spaceId].
  ///
  /// Lets the UI distinguish an empty window from a space that was never
  /// studied, without loading the history to find out.
  Future<int> countBySpaceId(String spaceId);

  /// Reviews for [spaceId] with `reviewedAt` in `[from, to)`.
  ///
  /// The statistics screen queries a window rather than the whole history so a
  /// long-lived collection does not have to be loaded in full each time.
  Future<List<ReviewLog>> getInRange({
    required String spaceId,
    required DateTime from,
    required DateTime to,
  });

  Future<void> add(ReviewLog log);

  Future<void> deleteBySpaceId(String spaceId);

  /// Moves history from one space to another, used when a space is deleted
  /// and its decks are transferred instead.
  Future<void> reassignSpaceId(String fromSpaceId, String toSpaceId);

  Future<void> replaceAll(List<ReviewLog> logs);
}