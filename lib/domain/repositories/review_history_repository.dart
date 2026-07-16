import 'package:recall/domain/entities/review_log.dart';

abstract class IReviewHistoryRepository {
  Future<List<ReviewLog>> getAll();

  Future<void> add(ReviewLog log);
}
