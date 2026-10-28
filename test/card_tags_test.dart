import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/tag_utils.dart';
import 'package:recall/domain/entities/flashcard.dart';

void main() {
  test('tag input splits on space and Persian comma and drops duplicates', () {
    expect(
      TagUtils.splitInput('فعل،  اسم  فعل  '),
      ['فعل', 'اسم'],
    );
  });

  test('old card json without tags still loads', () {
    final card = Flashcard.fromJson({
      'id': 'c1',
      'deckId': 'd1',
      'front': 'hello',
      'back': 'سلام',
      'box': 1,
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    expect(card.tags, isEmpty);
  });
}
