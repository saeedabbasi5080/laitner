import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:recall/data/datasources/isar_local_data_source.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/models/deck_model.dart';
import 'package:recall/data/models/flashcard_model.dart';
import 'package:recall/data/models/space_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _isarName = 'recall';
const _isarMaxSizeMiB = 256;

final _schemas = [
  SpaceModelSchema,
  DeckModelSchema,
  FlashcardModelSchema,
];

Future<LocalDataSource> createLocalDataSource(
  SharedPreferences prefs,
) async {
  final documents = await getApplicationDocumentsDirectory();
  final isar = await _openIsar(documents.path, _isarName);
  await _importLegacyIsarIfEmpty(isar, documents.path);

  if (await _isEmpty(isar)) {
    try {
      final support = await getApplicationSupportDirectory();
      if (support.path != documents.path) {
        await _importLegacyIsarIfEmpty(isar, support.path);
      }
    } catch (e, st) {
      debugPrint('Isar support-dir scan failed: $e\n$st');
    }
  }

  return IsarLocalDataSource(isar);
}

Future<Isar> _openIsar(String directory, String name) {
  return Isar.open(
    _schemas,
    directory: directory,
    name: name,
    inspector: false,
    maxSizeMiB: _isarMaxSizeMiB,
  );
}

Future<bool> _isEmpty(Isar isar) async {
  return await isar.spaceModels.count() == 0 &&
      await isar.deckModels.count() == 0 &&
      await isar.flashcardModels.count() == 0;
}

Future<void> _importLegacyIsarIfEmpty(Isar current, String directoryPath) async {
  if (!await _isEmpty(current)) return;

  final directory = Directory(directoryPath);
  if (!directory.existsSync()) return;

  final List<FileSystemEntity> entries;
  try {
    entries = directory.listSync();
  } catch (e, st) {
    debugPrint('Isar dir list failed: $e\n$st');
    return;
  }

  final names = entries
      .whereType<File>()
      .map((file) => file.uri.pathSegments.last)
      .where((name) => name.endsWith('.isar') && !name.endsWith('.isar.lock'))
      .map((name) => name.substring(0, name.length - '.isar'.length))
      .where((name) => name != _isarName)
      .toSet();

  for (final name in names) {
    Isar? legacy;
    try {
      legacy = await _openIsar(directoryPath, name);
      final spaces = await legacy.spaceModels.where().findAll();
      final decks = await legacy.deckModels.where().findAll();
      final cards = await legacy.flashcardModels.where().findAll();
      if (spaces.isEmpty && decks.isEmpty && cards.isEmpty) {
        continue;
      }

      await current.writeTxn(() async {
        for (final space in spaces) {
          await current.spaceModels.put(_copySpace(space));
        }
        for (final deck in decks) {
          await current.deckModels.put(_copyDeck(deck));
        }
        for (final card in cards) {
          await current.flashcardModels.put(_copyCard(card));
        }
      });
      return;
    } catch (e, st) {
      debugPrint('Isar legacy import failed for $name: $e\n$st');
    } finally {
      await legacy?.close();
    }
  }
}

SpaceModel _copySpace(SpaceModel space) {
  return SpaceModel()
    ..uuid = space.uuid
    ..name = space.name
    ..color = space.color
    ..createdAt = space.createdAt
    ..sortOrder = space.sortOrder;
}

DeckModel _copyDeck(DeckModel deck) {
  return DeckModel()
    ..uuid = deck.uuid
    ..spaceId = deck.spaceId
    ..name = deck.name
    ..color = deck.color
    ..createdAt = deck.createdAt;
}

FlashcardModel _copyCard(FlashcardModel card) {
  return FlashcardModel()
    ..uuid = card.uuid
    ..deckId = card.deckId
    ..front = card.front
    ..back = card.back
    ..box = card.box
    ..lastReviewed = card.lastReviewed
    ..createdAt = card.createdAt;
}
