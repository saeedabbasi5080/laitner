import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/card_font_size.dart';
import 'package:recall/core/tts/auto_speak_side.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs, this._spaceSettingsStore, this._flashcards)
      : super(const SettingsState());

  final SharedPreferences _prefs;
  final SpaceSettingsStore _spaceSettingsStore;
  final IFlashcardRepository _flashcards;
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
        ttsSpeechRate: spaceSettings.ttsSpeechRate,
        leitnerBoxes: spaceSettings.leitnerBoxes,
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

  Future<void> setTtsSpeechRate(double rate) async {
    final clamped = rate.clamp(0.2, 0.8).toDouble();
    await _updateSpaceSettings(
      (settings) => settings.copyWith(ttsSpeechRate: clamped),
    );
    emit(state.copyWith(ttsSpeechRate: clamped));
  }

  Future<void> setLeitnerBoxes(LeitnerBoxConfig boxes) async {
    final previous = state.leitnerBoxes;
    await _updateSpaceSettings(
      (settings) => settings.copyWith(leitnerBoxes: boxes),
    );
    emit(state.copyWith(leitnerBoxes: boxes));
    await _migrateBoxes(previous.maxBox, boxes.maxBox);
  }

  Future<void> _updateSpaceSettings(
    SpaceSettingsData Function(SpaceSettingsData settings) update,
  ) async {
    final spaceId = state.currentSpaceId;
    if (spaceId == null) return;

    final current = await _spaceSettingsStore.load(spaceId);
    await _spaceSettingsStore.save(spaceId, update(current));
  }

  Future<void> _migrateBoxes(int oldMax, int newMax) async {
    if (oldMax == newMax) return;
    final spaceId = state.currentSpaceId;
    if (spaceId == null) return;

    final cards = await _flashcards.getCardsBySpaceId(spaceId);
    for (final card in cards) {
      if (oldMax < newMax) {
        if (card.box > oldMax) {
          await _flashcards.updateCard(card.copyWith(box: newMax + 1));
        }
      } else if (card.box > newMax) {
        await _flashcards.updateCard(card.copyWith(box: newMax + 1));
      }
    }
  }
}
