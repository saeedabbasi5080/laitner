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
    bool reversed = false,
  }) : this._(spaceId: spaceId, deckId: deckId, reversed: reversed);

  const StudyConfig.allDue({
    required String spaceId,
    bool reversed = false,
  }) : this._(spaceId: spaceId, allDue: true, reversed: reversed);

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

  StudyConfig withSessionOptions({
    required bool randomOrder,
    bool? reversed,
  }) => StudyConfig._(
    spaceId: spaceId,
    deckId: deckId,
    allDue: allDue,
    boxNumber: boxNumber,
    reversed: reversed ?? this.reversed,
    dueDay: dueDay,
    overdueOnly: overdueOnly,
    randomOrder: randomOrder,
  );

  StudyConfig applySpaceSettings({
    required bool randomOrder,
    required bool defaultReversed,
  }) {
    if (isBoxReview) {
      return withSessionOptions(randomOrder: randomOrder);
    }
    return withSessionOptions(
      randomOrder: randomOrder,
      reversed: defaultReversed,
    );
  }
}
