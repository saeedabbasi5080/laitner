import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:recall/domain/entities/card_media.dart';
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

  List<String> tags = [];

  String frontStyle = '';

  String backStyle = '';

  String mediaJson = '[]';
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
      tags: List<String>.from(tags),
      frontStyle: frontStyle,
      backStyle: backStyle,
      media: _decodeMedia(mediaJson),
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
      ..createdAt = card.createdAt
      ..tags = List<String>.from(card.tags)
      ..frontStyle = card.frontStyle
      ..backStyle = card.backStyle
      ..mediaJson = jsonEncode(card.media.map((item) => item.toJson()).toList());
  }

  static List<CardMedia> _decodeMedia(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            CardMedia.fromJson(Map<String, dynamic>.from(item)),
      ];
    } catch (_) {
      return const [];
    }
  }
}
