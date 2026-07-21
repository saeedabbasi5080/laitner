import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';

class ReviewHistoryRepositoryImpl implements IReviewHistoryRepository {
  ReviewHistoryRepositoryImpl(this._store);

  final ReviewHistoryStore _store;

  @override
  Future<void> add(ReviewLog log) => _store.add(log);

  @override
  Future<List<ReviewLog>> getAll() async => _store.getAll();

  @override
  Future<List<ReviewLog>> getBySpaceId(String spaceId) async =>
      _store.getBySpaceId(spaceId);
}
