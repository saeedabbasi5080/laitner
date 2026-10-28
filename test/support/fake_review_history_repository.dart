import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';

/// Shared in-memory [IReviewHistoryRepository] for tests.
class FakeReviewHistoryRepository implements IReviewHistoryRepository {
  final List<ReviewLog> logs = [];

  @override
  Future<void> add(ReviewLog log) async {
    logs.add(log);
  }

  @override
  Future<List<ReviewLog>> getAll() async => logs;

  @override
  Future<List<ReviewLog>> getBySpaceId(String spaceId) async =>
      logs.where((log) => log.spaceId == spaceId).toList();

  @override
  Future<int> countBySpaceId(String spaceId) async =>
      logs.where((log) => log.spaceId == spaceId).length;

  @override
  Future<List<ReviewLog>> getInRange({
    required String spaceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return logs
        .where(
          (log) =>
              log.spaceId == spaceId &&
              !log.reviewedAt.isBefore(from) &&
              log.reviewedAt.isBefore(to),
        )
        .toList();
  }

  @override
  Future<void> deleteBySpaceId(String spaceId) async {
    logs.removeWhere((log) => log.spaceId == spaceId);
  }

  @override
  Future<void> reassignSpaceId(String fromSpaceId, String toSpaceId) async {
    for (var index = 0; index < logs.length; index++) {
      if (logs[index].spaceId == fromSpaceId) {
        logs[index] = logs[index].copyWith(spaceId: toSpaceId);
      }
    }
  }

  @override
  Future<void> replaceAll(List<ReviewLog> next) async {
    logs
      ..clear()
      ..addAll(next);
  }
}