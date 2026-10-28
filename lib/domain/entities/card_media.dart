import 'package:equatable/equatable.dart';

enum CardMediaKind { image, audio, voice }

enum CardMediaSide { front, back }

class CardMedia extends Equatable {
  const CardMedia({
    required this.id,
    required this.side,
    required this.kind,
    required this.relativePath,
    this.originalName = '',
  });

  final String id;
  final CardMediaSide side;
  final CardMediaKind kind;
  final String relativePath;
  final String originalName;

  bool get isImage => kind == CardMediaKind.image;
  bool get isPlayable => kind == CardMediaKind.audio || kind == CardMediaKind.voice;

  CardMedia copyWith({
    String? id,
    CardMediaSide? side,
    CardMediaKind? kind,
    String? relativePath,
    String? originalName,
  }) {
    return CardMedia(
      id: id ?? this.id,
      side: side ?? this.side,
      kind: kind ?? this.kind,
      relativePath: relativePath ?? this.relativePath,
      originalName: originalName ?? this.originalName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'side': side.name,
        'kind': kind.name,
        'relativePath': relativePath,
        'originalName': originalName,
      };

  factory CardMedia.fromJson(Map<String, dynamic> json) {
    return CardMedia(
      id: json['id'] as String,
      side: CardMediaSide.values.firstWhere(
        (value) => value.name == json['side'],
        orElse: () => CardMediaSide.front,
      ),
      kind: CardMediaKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => CardMediaKind.image,
      ),
      relativePath: json['relativePath'] as String? ?? '',
      originalName: json['originalName'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, side, kind, relativePath, originalName];
}
