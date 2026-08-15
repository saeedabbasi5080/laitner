import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/sync_excel_import_added_status_usecase.dart';

void main() {
  test('successful Box 5 review archives the card as learned', () {
    final useCase = ReviewCardUseCase(
      _FakeFlashcardRepository(),
      _FakeReviewHistoryRepository(),
    );
    final now = DateTime(2026, 8, 15);
    final card = Flashcard(
      id: '1',
      deckId: 'd1',
      front: 'hello',
      back: 'سلام',
      box: maxBox,
      createdAt: now,
    );

    final updated = useCase.applyReview(card, ReviewRating.know, now: now);
    expect(updated.box, learnedBox);
    expect(updated.isLearned, isTrue);
  });

  test('excel sync returns edited fronts to pending', () async {
    final cards = [
      Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: 'Edited',
        back: 'ویرایش‌شده',
        box: 1,
        createdAt: DateTime(2026, 8, 1),
      ),
    ];
    final import = ExcelImport(
      id: 'file',
      spaceId: 'space-1',
      fileName: 'words.xlsx',
      createdAt: DateTime(2026, 8, 1),
      rows: [
        ExcelImportRow(
          id: '1',
          front: 'Hello',
          back: 'سلام',
          isAdded: true,
          addedAt: DateTime(2026, 8, 1),
        ),
      ],
    );
    final excel = _FakeExcelImportRepository(import);
    final useCase = SyncExcelImportAddedStatusUseCase(
      excel,
      _FakeFlashcardRepository(cards),
    );

    final synced = await useCase(import);
    expect(synced.rows.single.isAdded, isFalse);
    expect(synced.rows.single.addedAt, isNull);
  });
}

class _FakeFlashcardRepository implements IFlashcardRepository {
  _FakeFlashcardRepository([List<Flashcard>? cards]) : cards = cards ?? [];

  final List<Flashcard> cards;
  Flashcard? updatedCard;

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<List<Flashcard>> getAllCards() async => cards;

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => cards;

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    updatedCard = card;
    return card;
  }
}

class _FakeReviewHistoryRepository implements IReviewHistoryRepository {
  final List<ReviewLog> logs = [];

  @override
  Future<void> add(ReviewLog log) async => logs.add(log);

  @override
  Future<List<ReviewLog>> getAll() async => logs;

  @override
  Future<List<ReviewLog>> getBySpaceId(String spaceId) async => logs;
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
      [value];

  @override
  Future<ExcelImport?> getImportById(String id) async => value;

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
