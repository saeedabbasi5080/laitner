part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.accent = AppAccent.lavender,
    this.currentSpaceId,
    this.ttsLanguage = TtsLanguage.englishUs,
    this.randomReviewOrder = false,
    this.cardFontSize = CardFontSize.size16,
    this.autoSpeak = false,
    this.autoSpeakSide = AutoSpeakSide.front,
    this.defaultReversed = false,
  });

  final ThemeMode themeMode;
  final AppAccent accent;
  final String? currentSpaceId;
  final TtsLanguage ttsLanguage;
  final bool randomReviewOrder;
  final CardFontSize cardFontSize;
  final bool autoSpeak;
  final AutoSpeakSide autoSpeakSide;
  final bool defaultReversed;

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppAccent? accent,
    String? currentSpaceId,
    TtsLanguage? ttsLanguage,
    bool? randomReviewOrder,
    CardFontSize? cardFontSize,
    bool? autoSpeak,
    AutoSpeakSide? autoSpeakSide,
    bool? defaultReversed,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      currentSpaceId: currentSpaceId ?? this.currentSpaceId,
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      randomReviewOrder: randomReviewOrder ?? this.randomReviewOrder,
      cardFontSize: cardFontSize ?? this.cardFontSize,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      autoSpeakSide: autoSpeakSide ?? this.autoSpeakSide,
      defaultReversed: defaultReversed ?? this.defaultReversed,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    accent,
    currentSpaceId,
    ttsLanguage,
    randomReviewOrder,
    cardFontSize,
    autoSpeak,
    autoSpeakSide,
    defaultReversed,
  ];
}
