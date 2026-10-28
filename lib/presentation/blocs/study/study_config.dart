import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/review_settings.dart';

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
    this.boxConfig = LeitnerBoxConfig.classic,
    this.reviewSettings = const ReviewSettings(),
    this.mistakeCardIds = const [],
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
  final LeitnerBoxConfig boxConfig;

  /// How a wrong answer moves the card between houses.
  final ReviewSettings reviewSettings;

  /// Ids of the cards the user got wrong today.
  ///
  /// A non-empty list means this session is a retry run. Those cards are no
  /// longer due, so without this the retry queue would come back empty.
  final List<String> mistakeCardIds;

  /// True when the user picked "review my mistakes" rather than a due list.
  bool get isMistakeRetry => mistakeCardIds.isNotEmpty;

  bool get isBoxReview => boxNumber != null;

  StudyConfig withSessionOptions({
    required bool randomOrder,
    bool? reversed,
    LeitnerBoxConfig? boxConfig,
    ReviewSettings? reviewSettings,
    List<String>? mistakeCardIds,
  }) => StudyConfig._(
    spaceId: spaceId,
    deckId: deckId,
    allDue: allDue,
    boxNumber: boxNumber,
    reversed: reversed ?? this.reversed,
    dueDay: dueDay,
    overdueOnly: overdueOnly,
    randomOrder: randomOrder,
    boxConfig: boxConfig ?? this.boxConfig,
    reviewSettings: reviewSettings ?? this.reviewSettings,
    mistakeCardIds: mistakeCardIds ?? this.mistakeCardIds,
  );

  StudyConfig applySpaceSettings({
    required bool randomOrder,
    required bool defaultReversed,
    LeitnerBoxConfig boxConfig = LeitnerBoxConfig.classic,
    ReviewSettings reviewSettings = const ReviewSettings(),
  }) {
    if (isBoxReview) {
      return withSessionOptions(
        randomOrder: randomOrder,
        boxConfig: boxConfig,
        reviewSettings: reviewSettings,
      );
    }
    return withSessionOptions(
      randomOrder: randomOrder,
      reversed: defaultReversed,
      boxConfig: boxConfig,
      reviewSettings: reviewSettings,
    );
  }

  /// A retry session over the cards that were answered wrongly today.
  ///
  /// Answers still feed the normal scheduler, so a card that is answered
  /// correctly here moves forward as it normally would.
  StudyConfig withMistakeRetry(List<String> cardIds) => withSessionOptions(
    randomOrder: randomOrder,
    reversed: reversed,
    boxConfig: boxConfig,
    reviewSettings: reviewSettings,
    mistakeCardIds: cardIds,
  );
}
