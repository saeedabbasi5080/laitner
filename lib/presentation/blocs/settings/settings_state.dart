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
    this.ttsSpeechRate = 0.45,
    this.leitnerBoxes = LeitnerBoxConfig.classic,
    this.collectionEpoch = 0,
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
  final double ttsSpeechRate;
  final LeitnerBoxConfig leitnerBoxes;
  final int collectionEpoch;

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
    double? ttsSpeechRate,
    LeitnerBoxConfig? leitnerBoxes,
    int? collectionEpoch,
    bool clearCurrentSpaceId = false,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      currentSpaceId: clearCurrentSpaceId
          ? currentSpaceId
          : (currentSpaceId ?? this.currentSpaceId),
      ttsLanguage: ttsLanguage ?? this.ttsLanguage,
      randomReviewOrder: randomReviewOrder ?? this.randomReviewOrder,
      cardFontSize: cardFontSize ?? this.cardFontSize,
      autoSpeak: autoSpeak ?? this.autoSpeak,
      autoSpeakSide: autoSpeakSide ?? this.autoSpeakSide,
      defaultReversed: defaultReversed ?? this.defaultReversed,
      ttsSpeechRate: ttsSpeechRate ?? this.ttsSpeechRate,
      leitnerBoxes: leitnerBoxes ?? this.leitnerBoxes,
      collectionEpoch: collectionEpoch ?? this.collectionEpoch,
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
    ttsSpeechRate,
    leitnerBoxes,
    collectionEpoch,
  ];
}
