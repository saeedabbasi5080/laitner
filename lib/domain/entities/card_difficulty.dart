import 'package:equatable/equatable.dart';

/// An optional difficulty label stored on a card as one of its tags.
///
/// The app already keeps free-form tags, so difficulty rides on that field
/// rather than adding a parallel concept that would need migrating and could
/// drift out of sync. A card with no difficulty simply has no such tag, and the
/// UI stays quiet about it.
enum CardDifficulty {
  easy('آسان', 'easy'),
  medium('متوسط', 'medium'),
  hard('سخت', 'hard'),
  veryHard('خیلی سخت', 'veryHard');

  const CardDifficulty(this.label, this.tag);

  /// Persian label shown in the picker.
  final String label;

  /// Value stored in [Flashcard.tags].
  final String tag;

  /// Offered as chips so the common cases are one tap away, while the tag
  /// field still accepts anything the user types themselves.
  static const suggestions = CardDifficulty.values;

  static CardDifficulty? fromTag(String tag) {
    for (final difficulty in CardDifficulty.values) {
      if (difficulty.tag == tag) return difficulty;
    }
    return null;
  }

  /// The difficulty among [tags], if the card carries one.
  static CardDifficulty? fromTags(List<String> tags) {
    for (final tag in tags) {
      final difficulty = fromTag(tag);
      if (difficulty != null) return difficulty;
    }
    return null;
  }
}

/// The difficulty carried by a card.
class CardDifficultyInfo extends Equatable {
  const CardDifficultyInfo({this.difficulty});

  /// `null` means the user never labelled this card.
  final CardDifficulty? difficulty;

  bool get hasDifficulty => difficulty != null;

  @override
  List<Object?> get props => [difficulty];
}