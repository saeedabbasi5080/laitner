enum AutoSpeakSide {
  front,
  back;

  static AutoSpeakSide fromName(String? name) {
    return AutoSpeakSide.values.firstWhere(
      (side) => side.name == name,
      orElse: () => AutoSpeakSide.front,
    );
  }

  /// Speaks only when the configured side is the one currently on screen.
  bool shouldSpeak({required bool isFlipped, required bool reversed}) {
    final showingFront = reversed ? isFlipped : !isFlipped;
    return this == AutoSpeakSide.front ? showingFront : !showingFront;
  }
}
