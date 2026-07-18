part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accent = AppAccent.lavender,
    this.ttsLanguage = TtsLanguage.englishUs,
    this.randomReviewOrder = false,
    this.cardFontSize = CardFontSize.size16,
    this.autoSpeak = false,
  });

  final ThemeMode themeMode;
  final AppAccent accent;
  final TtsLanguage ttsLanguage;
  final bool randomReviewOrder;
  final CardFontSize cardFontSize;
  final bool autoSpeak;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppAccent? accent,
    TtsLanguage? ttsLanguage,
    bool? randomReviewOrder,
    CardFontSize? cardFontSize,
    bool? autoSpeak,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      randomReviewOrder: randomReviewOrder ?? this.randomReviewOrder,
      cardFontSize: cardFontSize ?? this.cardFontSize,
      autoSpeak: autoSpeak ?? this.autoSpeak,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    accent,
    ttsLanguage,
    randomReviewOrder,
    cardFontSize,
    autoSpeak,
  ];
}
