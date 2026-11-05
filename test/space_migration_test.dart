import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/migration/space_migration.dart';
import 'package:recall/data/utils/uuid_id_generator.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_local_data_source.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> migrate(InMemoryLocalDataSource local) => runSpaceMigration(
        localDataSource: local,
        idGenerator: const UuidIdGenerator(),
        prefs: prefs,
        excelImportStore: ExcelImportStore(prefs),
        spaceSettingsStore: SpaceSettingsStore(prefs),
      );

  Deck deck({required String spaceId}) => Deck(
        id: 'deck-1',
        spaceId: spaceId,
        name: 'Words',
        color: DeckColor.sky,
        createdAt: DateTime(2026, 1, 1),
      );

  test('a fresh install gets no space', () async {
    final local = InMemoryLocalDataSource();

    await migrate(local);

    expect(await local.getAllSpaces(), isEmpty);
    expect(prefs.getBool(defaultSpaceMigrationKey), isTrue);
  });

  test('legacy preferences alone do not create a space', () async {
    SharedPreferences.setMockInitialValues({'auto_speak': true});
    prefs = await SharedPreferences.getInstance();
    final local = InMemoryLocalDataSource();

    await migrate(local);

    expect(await local.getAllSpaces(), isEmpty);
  });

  test('a legacy deck with no space gets one', () async {
    final local = InMemoryLocalDataSource(decks: [deck(spaceId: '')]);

    await migrate(local);

    final spaces = await local.getAllSpaces();
    expect(spaces, hasLength(1));
    final decks = await local.getAllDecks();
    expect(decks.single.spaceId, spaces.single.id);
  });

  test('a legacy deck joins the existing space instead of a new one', () async {
    final existing = LearningSpace(
      id: 'space-1',
      name: 'English',
      color: DeckColor.mint,
      createdAt: DateTime(2026, 1, 1),
    );
    final local = InMemoryLocalDataSource(
      spaces: [existing],
      decks: [deck(spaceId: '')],
    );

    await migrate(local);

    expect(await local.getAllSpaces(), hasLength(1));
    expect((await local.getAllDecks()).single.spaceId, 'space-1');
  });

  test('runs once', () async {
    final local = InMemoryLocalDataSource();
    await migrate(local);
    await local.addDeck(deck(spaceId: ''));

    await migrate(local);

    expect(await local.getAllSpaces(), isEmpty);
  });
}
