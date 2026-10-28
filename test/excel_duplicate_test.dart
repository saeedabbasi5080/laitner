import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/excel_duplicate.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';

ExcelImportRow _row(String id, String front, {bool isAdded = false}) =>
    ExcelImportRow(id: id, front: front, back: 'back-$id', isAdded: isAdded);

ExcelImport _import(List<ExcelImportRow> rows, {String spaceId = 'space-1'}) =>
    ExcelImport(
      id: 'import-1',
      spaceId: spaceId,
      fileName: 'words.xlsx',
      createdAt: DateTime(2026, 3, 11),
      rows: rows,
    );

Flashcard _card(String id, String front, String deckId) => Flashcard(
      id: id,
      deckId: deckId,
      front: front,
      back: 'x',
      box: 1,
      createdAt: DateTime(2026, 3, 1),
    );

DuplicateCardMatch _match(String front, String deckId) => DuplicateCardMatch(
      card: _card('c-$front', front, deckId),
      deckName: deckId,
    );

void main() {
  const analysis = ExcelDuplicateAnalysis();

  List<ExcelRowDuplicate> run(
    ExcelImport import, {
    List<DuplicateCardMatch> existing = const [],
    Map<String, String> deckNames = const {},
  }) {
    return analysis.findDuplicates(
      import: import,
      existingCards: existing,
      deckNames: deckNames,
    );
  }

  group('duplicate detection within one space', () {
    test('flags a row whose front already exists as a card', () {
      final duplicates = run(
        _import([_row('r1', 'apple')]),
        existing: [_match('apple', 'deck-1')],
        deckNames: {'deck-1': 'میوه‌ها'},
      );

      expect(duplicates, hasLength(1));
      expect(duplicates.single.rowId, 'r1');
      expect(duplicates.single.kind, ExcelDuplicateKind.existingCard);
      expect(duplicates.single.deckName, 'میوه‌ها');
    });

    test('leaves a genuinely new row alone', () {
      final duplicates = run(
        _import([_row('r1', 'apple')]),
        existing: [_match('banana', 'deck-1')],
        deckNames: {'deck-1': 'میوه‌ها'},
      );

      expect(duplicates, isEmpty);
    });

    test('ignores casing and surrounding whitespace', () {
      final duplicates = run(
        _import([_row('r1', '  Apple  ')]),
        existing: [_match('apple', 'deck-1')],
        deckNames: {'deck-1': 'میوه‌ها'},
      );

      expect(duplicates, hasLength(1));
    });

    test('reports the deck name of the card it clashes with', () {
      final duplicates = run(
        _import([_row('r1', 'apple')]),
        existing: [_match('apple', 'deck-9')],
        deckNames: {'deck-9': 'لغات'},
      );

      expect(duplicates.single.deckName, 'لغات');
    });

    test('falls back to the match name when the deck is unknown', () {
      final duplicates = run(
        _import([_row('r1', 'apple')]),
        existing: [_match('apple', 'deck-7')],
      );

      expect(duplicates.single.deckName, 'deck-7');
    });

    test('skips rows that were already added', () {
      final duplicates = run(
        _import([_row('r1', 'apple', isAdded: true)]),
        existing: [_match('apple', 'deck-1')],
        deckNames: {'deck-1': 'میوه‌ها'},
      );

      // An added row is expected to have a card behind it.
      expect(duplicates, isEmpty);
    });
  });

  group('duplicates inside one file', () {
    test('keeps the first occurrence and flags the rest', () {
      final duplicates = run(
        _import([
          _row('r1', 'apple'),
          _row('r2', 'banana'),
          _row('r3', 'Apple'),
        ]),
      );

      expect(duplicates, hasLength(1));
      expect(duplicates.single.rowId, 'r3');
      expect(duplicates.single.kind, ExcelDuplicateKind.withinFile);
      expect(duplicates.single.duplicateRowId, 'r1');
    });

    test('flags every repeat after the first', () {
      final duplicates = run(
        _import([
          _row('r1', 'apple'),
          _row('r2', 'apple'),
          _row('r3', 'apple'),
        ]),
      );

      expect(duplicates.map((item) => item.rowId), ['r2', 'r3']);
      expect(
        duplicates.every((item) => item.duplicateRowId == 'r1'),
        isTrue,
      );
    });

    test('does not chain: repeats point at the first row, not the previous', () {
      final duplicates = run(
        _import([
          _row('r1', 'apple'),
          _row('r2', 'apple'),
          _row('r3', 'apple'),
        ]),
      );

      expect(duplicates.first.duplicateRowId, 'r1');
      expect(duplicates.last.duplicateRowId, 'r1');
    });

    test('an already-added row does not block the pending one', () {
      // The added row's card is already in the space, so the pending row is a
      // clash with an existing card rather than with the file.
      final duplicates = run(
        _import([
          _row('r1', 'apple', isAdded: true),
          _row('r2', 'apple'),
        ]),
        existing: [_match('apple', 'deck-1')],
        deckNames: {'deck-1': 'میوه‌ها'},
      );

      expect(duplicates.single.kind, ExcelDuplicateKind.existingCard);
    });

    test('an existing card wins over a within-file clash', () {
      final duplicates = run(
        _import([
          _row('r1', 'apple'),
          _row('r2', 'apple'),
        ]),
        existing: [_match('apple', 'deck-1')],
        deckNames: {'deck-1': 'میوه‌ها'},
      );

      // Both rows clash with the card, which is the more useful explanation.
      expect(
        duplicates.every((item) => item.kind == ExcelDuplicateKind.existingCard),
        isTrue,
      );
      expect(duplicates, hasLength(2));
    });

    test('ignores an empty front so a blank row is not reported', () {
      final duplicates = run(
        _import([
          _row('r1', '   '),
          _row('r2', ''),
        ]),
      );

      expect(duplicates, isEmpty);
    });
  });

  group('scope', () {
    test('the caller only ever supplies cards from the row’s own space', () {
      // A word living in another space is not a duplicate here, because the
      // repository query is already limited to this import's space.
      final duplicates = run(
        _import([_row('r1', 'apple')], spaceId: 'space-2'),
        existing: const [],
      );

      expect(duplicates, isEmpty);
    });

    test('an empty collection produces no duplicates', () {
      expect(run(_import([_row('r1', 'apple')])), isEmpty);
    });
  });
}