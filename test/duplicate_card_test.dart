import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/find_duplicate_card_usecase.dart';

const _spaceId = 'space-1';

void main() {
  test('AddCardUseCase rejects duplicate front text across decks', () async {
    final cards = [
      Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: 'Hello',
        back: 'سلام',
        box: 1,
        createdAt: DateTime(2026, 7, 1),
      ),
    ];
    final decks = [
      Deck(
        id: 'd1',
        spaceId: _spaceId,
        name: 'انگلیسی',
        color: DeckColor.sky,
        createdAt: DateTime(2026, 7, 1),
      ),
    ];
    final flashcards = _FakeFlashcardRepository(cards);
    final useCase = AddCardUseCase(
      flashcards,
      FindDuplicateCardUseCase(flashcards, _FakeDeckRepository(decks)),
    );

    expect(
      () => useCase(
        Flashcard(
          id: 'c2',
          deckId: 'd2',
          front: ' hello ',
          back: 'درود',
          box: 1,
          createdAt: DateTime(2026, 7, 15),
        ),
        spaceId: _spaceId,
      ),
      throwsA(
        isA<DuplicateCardException>().having(
          (error) => error.deckName,
          'deckName',
          'انگلیسی',
        ),
      ),
    );
    expect(flashcards.cards, hasLength(1));
  });

  test('AddCardUseCase adds unique front text', () async {
    final flashcards = _FakeFlashcardRepository([]);
    final useCase = AddCardUseCase(
      flashcards,
      FindDuplicateCardUseCase(flashcards, _FakeDeckRepository([])),
    );

    final card = await useCase(
      Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: 'World',
        back: 'جهان',
        box: 1,
        createdAt: DateTime(2026, 7, 15),
      ),
      spaceId: _spaceId,
    );

    expect(card.front, 'World');
    expect(flashcards.cards, hasLength(1));
  });

  test('Excel import adds duplicates the user selected and counts them',
      () async {
    final now = DateTime(2026, 7, 15);
    final flashcards = _FakeFlashcardRepository([
      Flashcard(
        id: 'existing',
        deckId: 'english',
        front: 'Apple',
        back: 'سیب',
        box: 1,
        createdAt: now,
      ),
    ]);
    final decks = _FakeDeckRepository([
      Deck(
        id: 'english',
        spaceId: _spaceId,
        name: 'انگلیسی',
        color: DeckColor.sky,
        createdAt: now,
      ),
      Deck(
        id: 'target',
        spaceId: _spaceId,
        name: 'جدید',
        color: DeckColor.mint,
        createdAt: now,
      ),
    ]);
    final excel = _FakeExcelImportRepository(
      ExcelImport(
        id: 'file',
        spaceId: _spaceId,
        fileName: 'words.xlsx',
        createdAt: now,
        rows: const [
          ExcelImportRow(id: '1', front: 'Banana', back: 'موز'),
          ExcelImportRow(id: '2', front: ' apple ', back: 'سیب — میوه'),
          ExcelImportRow(id: '3', front: 'banana', back: 'موز'),
        ],
      ),
    );
    final useCase = AddSelectedExcelRowsUseCase(excel, flashcards, decks);

    var nextId = 0;
    final result = await useCase(
      importId: 'file',
      deckId: 'target',
      rowIds: const ['1', '2', '3'],
      generateId: () => 'new-${nextId++}',
    );

    // Nothing is withheld: the row list already warned, so the user's choice
    // is respected and merely reported back.
    expect(result.addedCount, 3);
    expect(result.addedDuplicateCount, 2);
    expect(result.hasAddedDuplicates, isTrue);
    expect(flashcards.cards, hasLength(4));
    expect(
      flashcards.cards.where((card) => card.deckId == 'target'),
      hasLength(3),
    );
    expect(excel.value.rows.every((row) => row.isAdded), isTrue);
  });

  test('Excel import adds only the rows the user actually selected', () async {
    final now = DateTime(2026, 7, 15);
    final flashcards = _FakeFlashcardRepository([
      Flashcard(
        id: 'existing',
        deckId: 'english',
        front: 'Apple',
        back: 'سیب',
        box: 1,
        createdAt: now,
      ),
    ]);
    final decks = _FakeDeckRepository([
      Deck(
        id: 'english',
        spaceId: _spaceId,
        name: 'انگلیسی',
        color: DeckColor.sky,
        createdAt: now,
      ),
      Deck(
        id: 'target',
        spaceId: _spaceId,
        name: 'جدید',
        color: DeckColor.mint,
        createdAt: now,
      ),
    ]);
    final excel = _FakeExcelImportRepository(
      ExcelImport(
        id: 'file',
        spaceId: _spaceId,
        fileName: 'words.xlsx',
        createdAt: now,
        rows: const [
          ExcelImportRow(id: '1', front: 'Banana', back: 'موز'),
          ExcelImportRow(id: '2', front: ' apple ', back: 'سیب'),
        ],
      ),
    );
    final useCase = AddSelectedExcelRowsUseCase(excel, flashcards, decks);

    var nextId = 0;
    final result = await useCase(
      importId: 'file',
      deckId: 'target',
      rowIds: const ['1'],
      generateId: () => 'new-${nextId++}',
    );

    expect(result.addedCount, 1);
    expect(result.addedDuplicateCount, 0);
    expect(result.hasAddedDuplicates, isFalse);
    expect(flashcards.cards, hasLength(2));
    expect(excel.value.rows.firstWhere((row) => row.id == '1').isAdded, isTrue);
    expect(excel.value.rows.firstWhere((row) => row.id == '2').isAdded, isFalse);
  });

  test('duplicates are counted against the state the user approved', () async {
    final now = DateTime(2026, 7, 15);
    final flashcards = _FakeFlashcardRepository([]);
    final decks = _FakeDeckRepository([
      Deck(
        id: 'target',
        spaceId: _spaceId,
        name: 'جدید',
        color: DeckColor.mint,
        createdAt: now,
      ),
    ]);
    final excel = _FakeExcelImportRepository(
      ExcelImport(
        id: 'file',
        spaceId: _spaceId,
        fileName: 'words.xlsx',
        createdAt: now,
        rows: const [
          ExcelImportRow(id: '1', front: 'Banana', back: 'موز'),
          ExcelImportRow(id: '2', front: 'banana', back: 'موز — دوباره'),
        ],
      ),
    );
    final useCase = AddSelectedExcelRowsUseCase(excel, flashcards, decks);

    var nextId = 0;
    final result = await useCase(
      importId: 'file',
      deckId: 'target',
      rowIds: const ['1', '2'],
      generateId: () => 'new-${nextId++}',
    );

    // The second row repeats the first within the file, so it was flagged.
    expect(result.addedCount, 2);
    expect(result.addedDuplicateCount, 1);
  });
}

class _FakeFlashcardRepository implements IFlashcardRepository {
  _FakeFlashcardRepository(this.cards);

  final List<Flashcard> cards;

  @override
  Future<Flashcard> addCard(Flashcard card) async {
    cards.add(card);
    return card;
  }

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<Flashcard?> getCardById(String id) async =>
      cards.where((card) => card.id == id).firstOrNull;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((card) => card.deckId == deckId).toList();

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;
}

class _FakeDeckRepository implements IDeckRepository {
  _FakeDeckRepository(this.decks);

  final List<Deck> decks;

  @override
  Future<Deck> addDeck(Deck deck) async => deck;

  @override
  Future<void> deleteDeck(String id) async {}

  @override
  Future<List<Deck>> getAllDecks() async => decks;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async =>
      decks.where((deck) => deck.spaceId == spaceId).toList();

  @override
  Future<Deck?> getDeckById(String id) async =>
      decks.where((deck) => deck.id == id).firstOrNull;

  @override
  Future<Deck> updateDeck(Deck deck) async => deck;
}

class _FakeExcelImportRepository implements IExcelImportRepository {
  _FakeExcelImportRepository(this.value);

  ExcelImport value;

  @override
  Future<void> deleteImport(String id) async {}

  @override
  Future<List<ExcelImport>> getAllImports() async => [value];

  @override
  Future<List<ExcelImport>> getImportsBySpaceId(String spaceId) async =>
      value.spaceId == spaceId ? [value] : [];

  @override
  Future<ExcelImport?> getImportById(String id) async =>
      value.id == id ? value : null;

  @override
  Future<ExcelImport> saveImport(ExcelImport import) async {
    value = import;
    return value;
  }

  @override
  Future<ExcelImport> updateImport(ExcelImport import) async {
    value = import;
    return value;
  }
}
