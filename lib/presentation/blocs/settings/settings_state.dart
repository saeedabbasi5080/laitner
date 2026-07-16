part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accent = AppAccent.lavender,
    this.ttsLanguage = TtsLanguage.englishUs,
  });

  final ThemeMode themeMode;
  final AppAccent accent;
  final TtsLanguage ttsLanguage;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppAccent? accent,
    TtsLanguage? ttsLanguage,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
    );
  }

  @override
  List<Object?> get props => [themeMode, accent, ttsLanguage];
}
