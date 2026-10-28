import 'dart:convert';

import 'package:recall/domain/entities/review_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Reads review history from the pre-Isar layout, where every log lived in a
/// single JSON array under one SharedPreferences key.
///
/// Only the migration still needs this; new writes go through
/// `LocalDataSource`. The key is left in place after a successful migration so
/// downgrading the app does not lose the user's history.
class LegacyReviewHistoryReader {
  const LegacyReviewHistoryReader(this._prefs);

  final SharedPreferences _prefs;

  static const storageKey = 'recall_review_history_v1';

  List<ReviewLog> readAll() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final logs = decoded
          .map((item) => ReviewLog.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList()
        ..sort((a, b) => a.reviewedAt.compareTo(b.reviewedAt));
      return logs;
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }
}