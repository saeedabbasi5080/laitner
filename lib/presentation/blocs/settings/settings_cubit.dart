import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/card_font_size.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs) : super(const SettingsState());

  final SharedPreferences _prefs;
  static const _themeKey = 'theme_mode';
  static const _accentKey = 'app_accent';
  static const _ttsLanguageKey = 'tts_language';
  static const _randomReviewOrderKey = 'random_review_order';
  static const _cardFontSizeKey = 'card_font_size';
  static const _autoSpeakKey = 'auto_speak';

  Future<void> load() async {
    final index = _prefs.getInt(_themeKey);
    final accentName = _prefs.getString(_accentKey);
    final ttsCode = _prefs.getString(_ttsLanguageKey);
    emit(
      state.copyWith(
        themeMode: index != null && index < ThemeMode.values.length
            ? ThemeMode.values[index]
            : state.themeMode,
        accent: AppAccent.fromName(accentName),
        ttsLanguage: TtsLanguage.fromCode(ttsCode),
        randomReviewOrder: _prefs.getBool(_randomReviewOrderKey) ?? false,
        cardFontSize: CardFontSize.fromName(_prefs.getString(_cardFontSizeKey)),
        autoSpeak: _prefs.getBool(_autoSpeakKey) ?? false,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setAccent(AppAccent accent) async {
    await _prefs.setString(_accentKey, accent.name);
    emit(state.copyWith(accent: accent));
  }

  Future<void> setTtsLanguage(TtsLanguage language) async {
    await _prefs.setString(_ttsLanguageKey, language.code);
    emit(state.copyWith(ttsLanguage: language));
  }

  Future<void> setRandomReviewOrder(bool enabled) async {
    await _prefs.setBool(_randomReviewOrderKey, enabled);
    emit(state.copyWith(randomReviewOrder: enabled));
  }

  Future<void> setCardFontSize(CardFontSize size) async {
    await _prefs.setString(_cardFontSizeKey, size.name);
    emit(state.copyWith(cardFontSize: size));
  }

  Future<void> setAutoSpeak(bool enabled) async {
    await _prefs.setBool(_autoSpeakKey, enabled);
    emit(state.copyWith(autoSpeak: enabled));
  }
}
