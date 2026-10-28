import 'package:isar/isar.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';

part 'review_log_model.g.dart';

/// One answered card, stored next to the cards so statistics queries can be
/// answered by the database instead of decoding one giant JSON blob.
///
/// [uuid] is unique and replaces on conflict, which makes importing the same
/// history twice idempotent.
@collection
class ReviewLogModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late String spaceId;

  @Index()
  late String deckId;

  late String cardId;

  /// Index into [ReviewRating.values]; kept as an integer so it can be filtered
  /// on without a string comparison.
  @Index()
  late int rating;

  late int boxBefore;

  late int boxAfter;

  @Index()
  late DateTime reviewedAt;
}

extension ReviewLogModelMapper on ReviewLogModel {
  ReviewLog toEntity() {
    return ReviewLog(
      id: uuid,
      spaceId: spaceId,
      cardId: cardId,
      deckId: deckId,
      rating: ReviewRating.values[rating.clamp(0, ReviewRating.values.length - 1)],
      boxBefore: boxBefore,
      boxAfter: boxAfter,
      reviewedAt: reviewedAt,
    );
  }

  static ReviewLogModel fromEntity(ReviewLog log) {
    return ReviewLogModel()
      ..uuid = log.id
      ..spaceId = log.spaceId
      ..deckId = log.deckId
      ..cardId = log.cardId
      ..rating = log.rating.index
      ..boxBefore = log.boxBefore
      ..boxAfter = log.boxAfter
      ..reviewedAt = log.reviewedAt;
  }
}