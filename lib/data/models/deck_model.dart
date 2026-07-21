import 'package:isar/isar.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';

part 'deck_model.g.dart';

@collection
class DeckModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index()
  late String spaceId;

  late String name;

  late String color;

  late DateTime createdAt;
}

extension DeckModelMapper on DeckModel {
  Deck toEntity() {
    return Deck(
      id: uuid,
      spaceId: spaceId,
      name: name,
      color: DeckColor.fromString(color),
      createdAt: createdAt,
    );
  }

  static DeckModel fromEntity(Deck deck) {
    return DeckModel()
      ..uuid = deck.id
      ..spaceId = deck.spaceId
      ..name = deck.name
      ..color = deck.color.name
      ..createdAt = deck.createdAt;
  }
}
