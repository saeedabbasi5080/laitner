import 'dart:convert';

import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewHistoryStore {
  ReviewHistoryStore(this._prefs);

  final SharedPreferences _prefs;

  static const _storageKey = 'recall_review_history_v1';

  List<ReviewLog> getAll() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final logs = decoded
          .map((item) => _fromJson(item as Map<String, dynamic>))
          .toList();
      logs.sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
      return logs;
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  List<ReviewLog> getBySpaceId(String spaceId) =>
      getAll().where((log) => log.spaceId == spaceId).toList();

  Future<void> add(ReviewLog log) async {
    final logs = [...getAll(), log];
    await _persist(logs);
  }

  Future<void> replaceAll(List<ReviewLog> logs) async {
    await _persist(logs);
  }

  Future<void> deleteBySpaceId(String spaceId) async {
    final logs = getAll().where((log) => log.spaceId != spaceId).toList();
    await _persist(logs);
  }

  Future<void> _persist(List<ReviewLog> logs) async {
    await _prefs.setString(_storageKey, jsonEncode(logs.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(ReviewLog log) => {
    'id': log.id,
    'spaceId': log.spaceId,
    'cardId': log.cardId,
    'deckId': log.deckId,
    'rating': log.rating.name,
    'boxBefore': log.boxBefore,
    'boxAfter': log.boxAfter,
    'reviewedAt': log.reviewedAt.toIso8601String(),
  };

  ReviewLog _fromJson(Map<String, dynamic> json) => ReviewLog(
    id: json['id'] as String,
    spaceId: json['spaceId'] as String? ?? '',
    cardId: json['cardId'] as String,
    deckId: json['deckId'] as String,
    rating: ReviewRating.values.byName(json['rating'] as String),
    boxBefore: json['boxBefore'] as int,
    boxAfter: json['boxAfter'] as int,
    reviewedAt: DateTime.parse(json['reviewedAt'] as String),
  );
}
