import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/deck_color.dart';

class Deck extends Equatable {
  const Deck({
    required this.id,
    required this.spaceId,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final String spaceId;
  final String name;
  final DeckColor color;
  final DateTime createdAt;

  Deck copyWith({
    String? id,
    String? spaceId,
    String? name,
    DeckColor? color,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, spaceId, name, color, createdAt];
}
