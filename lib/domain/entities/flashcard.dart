import 'package:equatable/equatable.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/card_media.dart';

class Flashcard extends Equatable {
  const Flashcard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.box,
    this.lastReviewed,
    required this.createdAt,
    this.tags = const [],
    this.frontStyle = '',
    this.backStyle = '',
    this.media = const [],
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final int box;
  final DateTime? lastReviewed;
  final DateTime createdAt;
  final List<String> tags;
  final String frontStyle;
  final String backStyle;
  final List<CardMedia> media;

  bool get isLearned => box >= learnedBox;

  bool isLearnedIn(int maxLearningBox) => box > maxLearningBox;

  List<CardMedia> mediaFor(CardMediaSide side) =>
      media.where((item) => item.side == side).toList();

  Flashcard copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    int? box,
    DateTime? lastReviewed,
    bool clearLastReviewed = false,
    DateTime? createdAt,
    List<String>? tags,
    String? frontStyle,
    String? backStyle,
    List<CardMedia>? media,
  }) {
    return Flashcard(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      box: box ?? this.box,
      lastReviewed: clearLastReviewed ? null : (lastReviewed ?? this.lastReviewed),
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      frontStyle: frontStyle ?? this.frontStyle,
      backStyle: backStyle ?? this.backStyle,
      media: media ?? this.media,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deckId,
        front,
        back,
        box,
        lastReviewed,
        createdAt,
        tags,
        frontStyle,
        backStyle,
        media,
      ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'box': box,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'tags': tags,
        'frontStyle': frontStyle,
        'backStyle': backStyle,
        'media': media.map((item) => item.toJson()).toList(),
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
      tags: _tagsFromJson(json['tags']),
      frontStyle: json['frontStyle'] as String? ?? '',
      backStyle: json['backStyle'] as String? ?? '',
      media: _mediaFromJson(json['media']),
    );
  }

  static List<String> _tagsFromJson(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item != null && item.toString().trim().isNotEmpty)
          item.toString().trim(),
    ];
  }

  static List<CardMedia> _mediaFromJson(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          CardMedia.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
}
