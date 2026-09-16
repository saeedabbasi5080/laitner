import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/due_day_utils.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

Flashcard _card({
  required DateTime createdAt,
  DateTime? lastReviewed,
  int box = 1,
}) {
  return Flashcard(
    id: '1',
    deckId: 'd1',
    front: 'front',
    back: 'back',
    box: box,
    lastReviewed: lastReviewed,
    createdAt: createdAt,
  );
}

void main() {
  group('new cards (never reviewed)', () {
    final createdAt = DateTime(2026, 7, 16, 15, 30);
    final card = _card(createdAt: createdAt);

    test('are not due on the same day they are added', () {
      expect(isCardDue(card, DateTime(2026, 7, 16, 20, 0)), isFalse);
    });

    test('become due the next day (Box 1 interval)', () {
      expect(isCardDue(card, DateTime(2026, 7, 17)), isTrue);
      expect(nextReviewDate(card), DateTime(2026, 7, 17));
      expect(cardDueDay(card), DateTime(2026, 7, 17));
    });
  });

  group('reviewed cards', () {
    test('Box 1 is due after 1 day', () {
      final reviewedAt = DateTime(2026, 7, 16, 10);
      final card = _card(createdAt: reviewedAt, lastReviewed: reviewedAt);

      expect(isCardDue(card, DateTime(2026, 7, 16, 22)), isFalse);
      expect(isCardDue(card, DateTime(2026, 7, 17)), isTrue);
    });

    test('classic houses follow 1, 2, 4, 8 and 16 day intervals', () {
      final reviewedAt = DateTime(2026, 7, 1, 10);
      final cases = <int, DateTime>{
        1: DateTime(2026, 7, 2),
        2: DateTime(2026, 7, 3),
        3: DateTime(2026, 7, 5),
        4: DateTime(2026, 7, 9),
        5: DateTime(2026, 7, 17),
      };

      for (final entry in cases.entries) {
        final card = _card(
          createdAt: reviewedAt,
          lastReviewed: reviewedAt,
          box: entry.key,
        );
        expect(
          nextReviewDate(card),
          entry.value,
          reason: 'box ${entry.key}',
        );
        expect(isCardDue(card, entry.value.subtract(const Duration(seconds: 1))), isFalse);
        expect(isCardDue(card, entry.value), isTrue);
      }
    });
    test('calendar intervals cross month and year boundaries', () {
      final reviewedAt = DateTime(2026, 12, 31, 23);
      final card = _card(
        createdAt: reviewedAt,
        lastReviewed: reviewedAt,
        box: 2,
      );

      expect(nextReviewDate(card), DateTime(2027, 1, 2));
    });
  });
}
