import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/data/backup/collection_backup.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/export_collection_backup_usecase.dart';
import 'package:recall/domain/usecases/restore_collection_backup_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_local_data_source.dart';

void main() {
  late InMemoryLocalDataSource local;
  late ExcelImportStore excel;
  late SpaceSettingsStore settings;
  late SharedPreferences prefs;

  final space = LearningSpace(
    id: 'space-1',
    name: 'English',
    color: DeckColor.mint,
    createdAt: DateTime(2026, 1, 1),
  );
  final deck = Deck(
    id: 'deck-1',
    spaceId: 'space-1',
    name: 'Words',
    color: DeckColor.sky,
    createdAt: DateTime(2026, 1, 2),
  );
  final card = Flashcard(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'hello',
    back: 'سلام',
    box: 2,
    lastReviewed: DateTime(2026, 1, 3),
    createdAt: DateTime(2026, 1, 2),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    local = InMemoryLocalDataSource(
      spaces: [space],
      decks: [deck],
      cards: [card],
      reviewLogs: [
        ReviewLog(
          id: 'log-1',
          spaceId: 'space-1',
          cardId: 'card-1',
          deckId: 'deck-1',
          rating: ReviewRating.know,
          boxBefore: 1,
          boxAfter: 2,
          reviewedAt: DateTime(2026, 1, 3),
        ),
      ],
    );
    excel = ExcelImportStore(prefs);
    settings = SpaceSettingsStore(prefs);
    await settings.save('space-1', const SpaceSettingsData());
  });

  test('export then restore replaces the collection', () async {
    final exported = await ExportCollectionBackupUseCase(
      localDataSource: local,
      excelImportStore: excel,
      spaceSettingsStore: settings,
    )(now: DateTime(2026, 9, 21));

    await local.replaceCollection(
      spaces: const [],
      decks: const [],
      cards: const [],
      reviewLogs: const [],
    );
    await excel.replaceAll(const []);
    await settings.clearAll();

    final result = await RestoreCollectionBackupUseCase(
      localDataSource: local,
      excelImportStore: excel,
      spaceSettingsStore: settings,
      prefs: prefs,
    )(jsonEncode(exported.toJson()));

    expect(result.cardCount, 1);
    expect(result.firstSpaceId, 'space-1');
    expect(local.cards.single.front, 'hello');
    expect(local.cards.single.box, 2);
    expect(local.reviewLogs, hasLength(1));
    expect(prefs.getBool(defaultSpaceMigrationKey), isTrue);
  });

  test('invalid backup file is rejected', () async {
    final restore = RestoreCollectionBackupUseCase(
      localDataSource: local,
      excelImportStore: excel,
      spaceSettingsStore: settings,
      prefs: prefs,
    );

    expect(
      () => restore('{"hello":"world"}'),
      throwsA(isA<BackupFormatException>()),
    );
    expect(local.cards, isNotEmpty);
  });

  test('restoring a backup restores review history as well', () async {
    final backup = CollectionBackup(
      exportedAt: DateTime(2026, 9, 21),
      spaces: [space],
      decks: [deck],
      cards: [card],
      reviewLogs: [
        ReviewLog(
          id: 'log-2',
          spaceId: 'space-1',
          cardId: 'card-1',
          deckId: 'deck-1',
          rating: ReviewRating.dontKnow,
          boxBefore: 3,
          boxAfter: 1,
          reviewedAt: DateTime(2026, 2, 1),
        ),
      ],
      excelImports: const [],
      spaceSettings: const {},
    );

    await RestoreCollectionBackupUseCase(
      localDataSource: local,
      excelImportStore: excel,
      spaceSettingsStore: settings,
      prefs: prefs,
    )(jsonEncode(backup.toJson()));

    expect(local.reviewLogs.single.id, 'log-2');
    expect(local.reviewLogs.single.rating, ReviewRating.dontKnow);
  });
}