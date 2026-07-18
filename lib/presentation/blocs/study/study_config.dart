class StudyConfig {
  const StudyConfig._({
    this.deckId,
    this.allDue = false,
    this.boxNumber,
    this.reversed = false,
    this.dueDay,
    this.overdueOnly = false,
    this.randomOrder = false,
  });

  const StudyConfig.deck(String deckId) : this._(deckId: deckId);

  const StudyConfig.allDue() : this._(allDue: true);

  /// Free review: all cards in a box regardless of due date.
  const StudyConfig.byBox(
    int box, {
    String? deckId,
    bool reversed = false,
    DateTime? dueDay,
    bool overdueOnly = false,
  }) : this._(
         boxNumber: box,
         deckId: deckId,
         reversed: reversed,
         dueDay: dueDay,
         overdueOnly: overdueOnly,
       );

  final String? deckId;
  final bool allDue;
  final int? boxNumber;
  final bool reversed;
  final DateTime? dueDay;
  final bool overdueOnly;
  final bool randomOrder;

  bool get isBoxReview => boxNumber != null;

  StudyConfig withRandomOrder(bool enabled) => StudyConfig._(
    deckId: deckId,
    allDue: allDue,
    boxNumber: boxNumber,
    reversed: reversed,
    dueDay: dueDay,
    overdueOnly: overdueOnly,
    randomOrder: enabled,
  );
}
