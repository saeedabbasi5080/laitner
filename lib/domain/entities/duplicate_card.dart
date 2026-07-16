import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/flashcard.dart';

/// نتیجهٔ ناموفق افزودن کارت به‌خاطر تکراری بودن فیلد اول (روی کارت).
/// مطابق الگوی Duplicate Check در Anki.
class DuplicateCardException implements Exception {
  const DuplicateCardException({
    required this.existingCard,
    required this.deckName,
  });

  final Flashcard existingCard;
  final String deckName;

  @override
  String toString() =>
      'DuplicateCardException(front: ${existingCard.front}, deck: $deckName)';
}

class DuplicateCardMatch extends Equatable {
  const DuplicateCardMatch({required this.card, required this.deckName});

  final Flashcard card;
  final String deckName;

  @override
  List<Object?> get props => [card, deckName];
}

/// نرمال‌سازی متن روی کارت برای مقایسهٔ تکراری (مثل Anki روی فیلد اول).
String normalizeCardFront(String front) => front.trim().toLowerCase();
