import 'dart:convert';

import 'package:recall/core/theme/card_font_size.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-space study settings (TTS, font size, review behavior).
class SpaceSettingsStore {
  SpaceSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'recall_space_settings_';

  String _key(String spaceId) => '$_prefix$spaceId';

  Future<SpaceSettingsData> load(String spaceId) async {
    final raw = _prefs.getString(_key(spaceId));
    if (raw == null) return const SpaceSettingsData();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SpaceSettingsData(
        ttsLanguage: TtsLanguage.fromCode(json['ttsLanguage'] as String?),
        randomReviewOrder: json['randomReviewOrder'] as bool? ?? false,
        cardFontSize: CardFontSize.fromName(json['cardFontSize'] as String?),
        autoSpeak: json['autoSpeak'] as bool? ?? false,
      );
    } on FormatException {
      return const SpaceSettingsData();
    } on TypeError {
      return const SpaceSettingsData();
    }
  }

  Future<void> save(String spaceId, SpaceSettingsData data) async {
    await _prefs.setString(
      _key(spaceId),
      jsonEncode({
        'ttsLanguage': data.ttsLanguage.code,
        'randomReviewOrder': data.randomReviewOrder,
        'cardFontSize': data.cardFontSize.name,
        'autoSpeak': data.autoSpeak,
      }),
    );
  }

  Future<void> delete(String spaceId) async {
    await _prefs.remove(_key(spaceId));
  }
}

class SpaceSettingsData {
  const SpaceSettingsData({
    this.ttsLanguage = TtsLanguage.englishUs,
    this.randomReviewOrder = false,
    this.cardFontSize = CardFontSize.size16,
    this.autoSpeak = false,
  });

  final TtsLanguage ttsLanguage;
  final bool randomReviewOrder;
  final CardFontSize cardFontSize;
  final bool autoSpeak;

  SpaceSettingsData copyWith({
    TtsLanguage? ttsLanguage,
    bool? randomReviewOrder,
    CardFontSize? cardFontSize,
    bool? autoSpeak,
  }) {
    return SpaceSettingsData(
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      randomReviewOrder: randomReviewOrder ?? this.randomReviewOrder,
      cardFontSize: cardFontSize ?? this.cardFontSize,
      autoSpeak: autoSpeak ?? this.autoSpeak,
    );
  }
}
