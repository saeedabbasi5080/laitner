part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accent = AppAccent.lavender,
  });

  final ThemeMode themeMode;
  final AppAccent accent;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppAccent? accent,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
    );
  }

  @override
  List<Object?> get props => [themeMode, accent];
}
