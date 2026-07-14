import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/deck_color.dart';

class Deck extends Equatable {
  const Deck({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
  });

  final String id;
  final String name;
  final DeckColor color;
  final DateTime createdAt;

  Deck copyWith({
    String? id,
    String? name,
    DeckColor? color,
    DateTime? createdAt,
  }) {
    return Deck(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, color, createdAt];
}
