import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';

class ReviewHistoryRepositoryImpl implements IReviewHistoryRepository {
  ReviewHistoryRepositoryImpl(this._localDataSource);

  final LocalDataSource _localDataSource;

  @override
  Future<List<ReviewLog>> getAll() => _localDataSource.getAllReviewLogs();

  @override
  Future<List<ReviewLog>> getBySpaceId(String spaceId) =>
      _localDataSource.getReviewLogsBySpaceId(spaceId);

  @override
  Future<int> countBySpaceId(String spaceId) =>
      _localDataSource.countReviewLogsBySpaceId(spaceId);

  @override
  Future<List<ReviewLog>> getInRange({
    required String spaceId,
    required DateTime from,
    required DateTime to,
  }) {
    return _localDataSource.getReviewLogsInRange(
      spaceId: spaceId,
      from: from,
      to: to,
    );
  }

  @override
  Future<void> add(ReviewLog log) async {
    await _localDataSource.addReviewLog(log);
  }

  @override
  Future<void> deleteBySpaceId(String spaceId) =>
      _localDataSource.deleteReviewLogsBySpaceId(spaceId);

  @override
  Future<void> reassignSpaceId(String fromSpaceId, String toSpaceId) async {
    final logs = await _localDataSource.getReviewLogsBySpaceId(fromSpaceId);
    if (logs.isEmpty) return;

    await _localDataSource.replaceReviewLogs([
      ...logs.map((log) => log.copyWith(spaceId: toSpaceId)),
      ...(await _localDataSource.getAllReviewLogs())
          .where((log) => log.spaceId != fromSpaceId),
    ]);
  }

  @override
  Future<void> replaceAll(List<ReviewLog> logs) =>
      _localDataSource.replaceReviewLogs(logs);
}