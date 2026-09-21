import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/utils/excel_encoder.dart';
import 'package:recall/data/utils/excel_parser.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/export_deck_excel_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';

void main() {
  test('key-value xlsx round-trips with the importer', () {
    final bytes = ExcelWorkbookEncoder.encodeKeyValue([
      (front: 'hello', back: 'سلام'),
      (front: '  apple  ', back: 'سیب'),
      (front: '', back: 'ignored'),
      (front: 'only-front', back: '  '),
    ]);

    final parsed = ExcelParser.parseRows(bytes);
    expect(parsed, [
      (front: 'hello', back: 'سلام'),
      (front: 'apple', back: 'سیب'),
    ]);
  });

  test('file name keeps Persian text and strips path characters', () {
    expect(
      ExcelWorkbookEncoder.fileNameForDeck('لغات / روزانه'),
      'لغات _ روزانه.xlsx',
    );
    expect(ExcelWorkbookEncoder.fileNameForDeck('   '), 'deck.xlsx');
  });

  test('export use case writes deck cards in creation order', () async {
    final deck = Deck(
      id: 'deck-1',
      spaceId: 'space-1',
      name: 'Words',
      color: DeckColor.sky,
      createdAt: DateTime(2026, 1, 1),
    );
    final later = Flashcard(
      id: 'card-2',
      deckId: 'deck-1',
      front: 'world',
      back: 'دنیا',
      box: 1,
      createdAt: DateTime(2026, 1, 3),
    );
    final earlier = Flashcard(
      id: 'card-1',
      deckId: 'deck-1',
      front: 'hello',
      back: 'سلام',
      box: 2,
      createdAt: DateTime(2026, 1, 2),
    );

    final exported = await ExportDeckExcelUseCase(
      getDeckUseCase: GetDeckUseCase(_FakeDeckRepo([deck])),
      getCardsByDeckUseCase: GetCardsByDeckUseCase(
        _FakeCardRepo([later, earlier]),
      ),
    )('deck-1');

    expect(exported.fileName, 'Words.xlsx');
    expect(ExcelParser.parseRows(exported.bytes), [
      (front: 'hello', back: 'سلام'),
      (front: 'world', back: 'دنیا'),
    ]);
  });

  test('export use case rejects an empty deck', () async {
    final deck = Deck(
      id: 'deck-1',
      spaceId: 'space-1',
      name: 'Empty',
      color: DeckColor.sky,
      createdAt: DateTime(2026, 1, 1),
    );

    expect(
      () => ExportDeckExcelUseCase(
        getDeckUseCase: GetDeckUseCase(_FakeDeckRepo([deck])),
        getCardsByDeckUseCase: GetCardsByDeckUseCase(_FakeCardRepo([])),
      )('deck-1'),
      throwsA(isA<DeckExportEmptyException>()),
    );
  });
}

class _FakeDeckRepo implements IDeckRepository {
  _FakeDeckRepo(this.decks);

  final List<Deck> decks;

  @override
  Future<Deck> addDeck(Deck deck) => throw UnimplementedError();

  @override
  Future<void> deleteDeck(String id) => throw UnimplementedError();

  @override
  Future<Deck?> getDeckById(String id) async {
    for (final deck in decks) {
      if (deck.id == id) return deck;
    }
    return null;
  }

  @override
  Future<List<Deck>> getAllDecks() async => decks;

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async => decks;

  @override
  Future<Deck> updateDeck(Deck deck) => throw UnimplementedError();
}

class _FakeCardRepo implements IFlashcardRepository {
  _FakeCardRepo(this.cards);

  final List<Flashcard> cards;

  @override
  Future<Flashcard> addCard(Flashcard card) => throw UnimplementedError();

  @override
  Future<void> deleteCard(String id) => throw UnimplementedError();

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<Flashcard?> getCardById(String id) => throw UnimplementedError();

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((c) => c.deckId == deckId).toList();

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<Flashcard> updateCard(Flashcard card) => throw UnimplementedError();
}
