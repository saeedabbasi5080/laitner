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

  ReviewLog copyWith({
    String? id,
    String? spaceId,
    String? cardId,
    String? deckId,
    ReviewRating? rating,
    int? boxBefore,
    int? boxAfter,
    DateTime? reviewedAt,
  }) {
    return ReviewLog(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      cardId: cardId ?? this.cardId,
      deckId: deckId ?? this.deckId,
      rating: rating ?? this.rating,
      boxBefore: boxBefore ?? this.boxBefore,
      boxAfter: boxAfter ?? this.boxAfter,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
        'cardId': cardId,
        'deckId': deckId,
        'rating': rating.name,
        'boxBefore': boxBefore,
        'boxAfter': boxAfter,
        'reviewedAt': reviewedAt.toIso8601String(),
      };

  factory ReviewLog.fromJson(Map<String, dynamic> json) {
    return ReviewLog(
      id: json['id'] as String,
      spaceId: json['spaceId'] as String? ?? '',
      cardId: json['cardId'] as String,
      deckId: json['deckId'] as String,
      rating: ReviewRating.values.byName(json['rating'] as String),
      boxBefore: json['boxBefore'] as int,
      boxAfter: json['boxAfter'] as int,
      reviewedAt: DateTime.parse(json['reviewedAt'] as String),
    );
  }
}
