import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/review_rating.dart';

class ReviewLog extends Equatable {
  const ReviewLog({
    required this.id,
    required this.spaceId,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.boxBefore,
    required this.boxAfter,
    required this.reviewedAt,
  });

  final String id;
  final String spaceId;
  final String cardId;
  final String deckId;
  final ReviewRating rating;
  final int boxBefore;
  final int boxAfter;
  final DateTime reviewedAt;

  @override
  List<Object> get props => [
    id,
    spaceId,
    cardId,
    deckId,
    rating,
    boxBefore,
    boxAfter,
    reviewedAt,
  ];
}
