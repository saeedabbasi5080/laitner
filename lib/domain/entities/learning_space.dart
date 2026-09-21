import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/deck_color.dart';

class LearningSpace extends Equatable {
  const LearningSpace({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final DeckColor color;
  final DateTime createdAt;
  final int sortOrder;

  LearningSpace copyWith({
    String? id,
    String? name,
    DeckColor? color,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return LearningSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [id, name, color, createdAt, sortOrder];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.name,
        'createdAt': createdAt.toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory LearningSpace.fromJson(Map<String, dynamic> json) {
    return LearningSpace(
      id: json['id'] as String,
      name: json['name'] as String,
      color: DeckColor.fromString(json['color'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}
