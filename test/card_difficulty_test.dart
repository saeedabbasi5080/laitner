import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/tag_utils.dart';
import 'package:recall/domain/entities/card_difficulty.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';

void main() {
  group('CardDifficulty', () {
    test('reads itself back out of a tag list', () {
      expect(
        CardDifficulty.fromTags(['verb', 'hard', 'noun']),
        CardDifficulty.hard,
      );
      expect(CardDifficulty.fromTags(['easy']), CardDifficulty.easy);
      expect(CardDifficulty.fromTags(['veryHard']), CardDifficulty.veryHard);
    });

    test('returns null when the card carries no difficulty', () {
      expect(CardDifficulty.fromTags(const []), isNull);
      expect(CardDifficulty.fromTags(['verb', 'noun']), isNull);
    });

    test('picks the difficulty even when other tags come first', () {
      expect(
        CardDifficulty.fromTags(['noun', 'medium']),
        CardDifficulty.medium,
      );
    });

    test('ignores an unrecognised tag', () {
      expect(CardDifficulty.fromTag('extreme'), isNull);
      expect(CardDifficulty.fromTag('easy'), CardDifficulty.easy);
    });

    test('every difficulty has a distinct tag', () {
      final tags = CardDifficulty.values.map((d) => d.tag).toSet();
      expect(tags.length, CardDifficulty.values.length);
    });

    test('suggestions cover every option', () {
      expect(CardDifficulty.suggestions.length, CardDifficulty.values.length);
    });
  });

  group('difficulty rides along with normal tags', () {
    test('adding it is just another tag', () {
      final tags = TagUtils.normalize(['verb', CardDifficulty.hard.tag]);
      expect(tags, contains(CardDifficulty.hard.tag));
      expect(tags, contains('verb'));
      expect(CardDifficulty.fromTags(tags), CardDifficulty.hard);
    });

    test('removing it leaves the other tags intact', () {
      final tags = TagUtils.normalize(['verb', CardDifficulty.hard.tag])
          .where((tag) => tag != CardDifficulty.hard.tag)
          .toList();

      expect(tags, ['verb']);
      expect(CardDifficulty.fromTags(tags), isNull);
    });

    test('switching difficulty replaces rather than stacks', () {
      final withHard = TagUtils.normalize([CardDifficulty.hard.tag]);
      final switched = TagUtils.normalize(
        withHard
            .where((tag) => tag != CardDifficulty.easy.tag)
            .map((tag) => tag == CardDifficulty.hard.tag
                ? CardDifficulty.easy.tag
                : tag)
            .toList(),
      );

      expect(CardDifficulty.fromTags(switched), CardDifficulty.easy);
    });
  });

  group('Flashcard', () {
    test('keeps difficulty across a copy', () {
      final card = Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: 'Apple',
        back: 'سیب',
        box: 1,
        createdAt: DateTime(2026, 3, 1),
        tags: [CardDifficulty.hard.tag],
      );

      expect(CardDifficulty.fromTags(card.copyWith(box: 2).tags),
          CardDifficulty.hard);
    });

    test('survives a json round trip', () {
      final card = Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: 'Apple',
        back: 'سیب',
        box: 1,
        createdAt: DateTime(2026, 3, 1),
        tags: const ['verb', 'hard'],
      );

      final restored = Flashcard.fromJson(card.toJson());
      expect(restored.tags, ['verb', 'hard']);
      expect(CardDifficulty.fromTags(restored.tags), CardDifficulty.hard);
    });
  });

  group('ExcelImportRow', () {
    test('carries tags through copyWith', () {
      const row = ExcelImportRow(id: 'r1', front: 'a', back: 'b');
      expect(row.tags, isEmpty);

      final tagged = row.copyWith(tags: const ['hard']);
      expect(tagged.tags, ['hard']);
      // An omitted argument must not wipe the existing tags.
      expect(tagged.copyWith(front: 'z').tags, ['hard']);
    });

    test('survives a json round trip', () {
      const row = ExcelImportRow(
        id: 'r1',
        front: 'a',
        back: 'b',
        tags: ['hard', 'verb'],
      );

      final restored = ExcelImportRow.fromJson(row.toJson());
      expect(restored.tags, ['hard', 'verb']);
    });

    test('reads a row saved before tags existed', () {
      final restored = ExcelImportRow.fromJson({
        'id': 'r1',
        'front': 'a',
        'back': 'b',
        'isAdded': false,
      });

      expect(restored.tags, isEmpty);
    });
  });
}