import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/card_font_size.dart';
import 'package:recall/core/tts/auto_speak_side.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs, this._spaceSettingsStore)
      : super(const SettingsState());

  final SharedPreferences _prefs;
  final SpaceSettingsStore _spaceSettingsStore;
  static const _themeKey = 'theme_mode';
  static const _accentKey = 'app_accent';

  Future<void> load() async {
    final index = _prefs.getInt(_themeKey);
    final accentName = _prefs.getString(_accentKey);
    emit(
      state.copyWith(
        themeMode: index != null && index < ThemeMode.values.length
            ? ThemeMode.values[index]
            : state.themeMode,
        accent: AppAccent.fromName(accentName),
      ),
    );
  }

  Future<void> loadForSpace(String spaceId) async {
    await load();
    final spaceSettings = await _spaceSettingsStore.load(spaceId);
    final accent = spaceSettings.accent ?? state.accent;
    if (spaceSettings.accent == null) {
      await _spaceSettingsStore.save(
        spaceId,
        spaceSettings.copyWith(accent: accent),
      );
    }
    emit(
      state.copyWith(
        currentSpaceId: spaceId,
        accent: accent,
        ttsLanguage: spaceSettings.ttsLanguage,
        randomReviewOrder: spaceSettings.randomReviewOrder,
        cardFontSize: spaceSettings.cardFontSize,
        autoSpeak: spaceSettings.autoSpeak,
        autoSpeakSide: spaceSettings.autoSpeakSide,
        defaultReversed: spaceSettings.defaultReversed,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_themeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setAccent(AppAccent accent) async {
    await _prefs.setString(_accentKey, accent.name);
    await _updateSpaceSettings(
      (settings) => settings.copyWith(accent: accent),
    );
    emit(state.copyWith(accent: accent));
  }

  Future<void> setTtsLanguage(TtsLanguage language) async {
    await _updateSpaceSettings(
      (settings) => settings.copyWith(ttsLanguage: language),
    );
    emit(state.copyWith(ttsLanguage: language));
  }

  Future<void> setRandomReviewOrder(bool enabled) async {
    await _updateSpaceSettings(
      (settings) => settings.copyWith(randomReviewOrder: enabled),
    );
    emit(state.copyWith(randomReviewOrder: enabled));
  }

  Future<void> setCardFontSize(CardFontSize size) async {
    await _updateSpaceSettings(
      (settings) => settings.copyWith(cardFontSize: size),
    );
    emit(state.copyWith(cardFontSize: size));
  }

  Future<void> setAutoSpeak(bool enabled) async {
    await _updateSpaceSettings(
      (settings) => settings.copyWith(autoSpeak: enabled),
    );
    emit(state.copyWith(autoSpeak: enabled));
  }

  Future<void> setAutoSpeakSide(AutoSpeakSide side) async {
    await _updateSpaceSettings(
      (settings) => settings.copyWith(autoSpeakSide: side),
    );
    emit(state.copyWith(autoSpeakSide: side));
  }

  Future<void> setDefaultReversed(bool reversed) async {
    await _updateSpaceSettings(
      (settings) => settings.copyWith(defaultReversed: reversed),
    );
    emit(state.copyWith(defaultReversed: reversed));
  }

  Future<void> _updateSpaceSettings(
    SpaceSettingsData Function(SpaceSettingsData settings) update,
  ) async {
    final spaceId = state.currentSpaceId;
    if (spaceId == null) return;

    final current = await _spaceSettingsStore.load(spaceId);
    await _spaceSettingsStore.save(spaceId, update(current));
  }
}
