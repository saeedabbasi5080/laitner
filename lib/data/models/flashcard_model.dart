import 'package:isar/isar.dart';
import 'package:recall/domain/entities/flashcard.dart';

part 'flashcard_model.g.dart';

@collection
class FlashcardModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String deckId;

  late String front;

  late String back;

  late int box;

  DateTime? lastReviewed;

  late DateTime createdAt;
}

extension FlashcardModelMapper on FlashcardModel {
  Flashcard toEntity() {
    return Flashcard(
      id: uuid,
      deckId: deckId,
      front: front,
      back: back,
      box: box,
      lastReviewed: lastReviewed,
      createdAt: createdAt,
    );
  }

  static FlashcardModel fromEntity(Flashcard card) {
    return FlashcardModel()
      ..uuid = card.id
      ..deckId = card.deckId
      ..front = card.front
      ..back = card.back
      ..box = card.box
      ..lastReviewed = card.lastReviewed
      ..createdAt = card.createdAt;
  }
}
