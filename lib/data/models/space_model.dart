import 'package:isar/isar.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/learning_space.dart';

part 'space_model.g.dart';

@collection
class SpaceModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  late String name;

  late String color;

  late DateTime createdAt;

  late int sortOrder;
}

extension SpaceModelMapper on SpaceModel {
  LearningSpace toEntity() {
    return LearningSpace(
      id: uuid,
      name: name,
      color: DeckColor.fromString(color),
      createdAt: createdAt,
      sortOrder: sortOrder,
    );
  }

  static SpaceModel fromEntity(LearningSpace space) {
    return SpaceModel()
      ..uuid = space.id
      ..name = space.name
      ..color = space.color.name
      ..createdAt = space.createdAt
      ..sortOrder = space.sortOrder;
  }
}
