import 'package:equatable/equatable.dart';

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
}
