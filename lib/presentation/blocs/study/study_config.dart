class StudyConfig {
  const StudyConfig._({
    required this.spaceId,
    this.deckId,
    this.allDue = false,
    this.boxNumber,
    this.reversed = false,
    this.dueDay,
    this.overdueOnly = false,
    this.randomOrder = false,
  });

  const StudyConfig.deck({
    required String spaceId,
    required String deckId,
  }) : this._(spaceId: spaceId, deckId: deckId);

  const StudyConfig.allDue({required String spaceId})
      : this._(spaceId: spaceId, allDue: true);

  /// Free review: all cards in a box regardless of due date.
  const StudyConfig.byBox(
    int box, {
    required String spaceId,
    String? deckId,
    bool reversed = false,
    DateTime? dueDay,
    bool overdueOnly = false,
  }) : this._(
         spaceId: spaceId,
         boxNumber: box,
         deckId: deckId,
         reversed: reversed,
         dueDay: dueDay,
         overdueOnly: overdueOnly,
       );

  final String spaceId;
  final String? deckId;
  final bool allDue;
  final int? boxNumber;
  final bool reversed;
  final DateTime? dueDay;
  final bool overdueOnly;
  final bool randomOrder;

  bool get isBoxReview => boxNumber != null;

  StudyConfig withRandomOrder(bool enabled) => StudyConfig._(
    spaceId: spaceId,
    deckId: deckId,
    allDue: allDue,
    boxNumber: boxNumber,
    reversed: reversed,
    dueDay: dueDay,
    overdueOnly: overdueOnly,
    randomOrder: enabled,
  );
}
