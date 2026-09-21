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

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
        'name': name,
        'color': color.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Deck.fromJson(Map<String, dynamic> json) {
    return Deck(
      id: json['id'] as String,
      spaceId: json['spaceId'] as String? ?? '',
      name: json['name'] as String,
      color: DeckColor.fromString(json['color'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
