import 'package:equatable/equatable.dart';
import 'package:recall/core/constants/leitner_constants.dart';

class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.box,
    this.lastReviewed,
    required this.createdAt,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final int box;
  final DateTime? lastReviewed;
  final DateTime createdAt;

  bool get isLearned => box >= learnedBox;

  bool isLearnedIn(int maxLearningBox) => box > maxLearningBox;

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    int? box,
    DateTime? lastReviewed,
    bool clearLastReviewed = false,
    DateTime? createdAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      box: box ?? this.box,
      lastReviewed: clearLastReviewed ? null : (lastReviewed ?? this.lastReviewed),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, deckId, front, back, box, lastReviewed, createdAt];

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'box': box,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      deckId: json['deckId'] as String,
      front: json['front'] as String,
      back: json['back'] as String,
      box: json['box'] as int? ?? 1,
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
