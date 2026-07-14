class StudyConfig {
  const StudyConfig._({
    this.deckId,
    this.allDue = false,
    this.boxNumber,
    this.reversed = false,
  });

  const StudyConfig.deck(String deckId)
      : this._(deckId: deckId);

  const StudyConfig.allDue() : this._(allDue: true);

  /// Free review: all cards in a box regardless of due date.
  const StudyConfig.byBox(
    int box, {
    String? deckId,
    bool reversed = false,
  }) : this._(boxNumber: box, deckId: deckId, reversed: reversed);

  final String? deckId;
  final bool allDue;
  final int? boxNumber;
  final bool reversed;

  bool get isBoxReview => boxNumber != null;
}
