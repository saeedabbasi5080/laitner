import 'dart:convert';

import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/data/backup/collection_backup.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RestoreCollectionResult {
  const RestoreCollectionResult({
    required this.spaceCount,
    required this.cardCount,
    this.firstSpaceId,
  });

  final int spaceCount;
  final int cardCount;
  final String? firstSpaceId;
}

class RestoreCollectionBackupUseCase {
  RestoreCollectionBackupUseCase({
    required LocalDataSource localDataSource,
    required ReviewHistoryStore reviewHistoryStore,
    required ExcelImportStore excelImportStore,
    required SpaceSettingsStore spaceSettingsStore,
    required SharedPreferences prefs,
  })  : _localDataSource = localDataSource,
        _reviewHistoryStore = reviewHistoryStore,
        _excelImportStore = excelImportStore,
        _spaceSettingsStore = spaceSettingsStore,
        _prefs = prefs;

  final LocalDataSource _localDataSource;
  final ReviewHistoryStore _reviewHistoryStore;
  final ExcelImportStore _excelImportStore;
  final SpaceSettingsStore _spaceSettingsStore;
  final SharedPreferences _prefs;

  Future<RestoreCollectionResult> call(String jsonText) async {
    late final CollectionBackup backup;
    try {
      final decoded = jsonDecode(jsonText);
      if (decoded is! Map<String, dynamic>) {
        throw const BackupFormatException();
      }
      backup = CollectionBackup.fromJson(decoded);
    } on FormatException {
      throw const BackupFormatException();
    } on TypeError {
      throw const BackupFormatException();
    }

    await _localDataSource.replaceCollection(
      spaces: backup.spaces,
      decks: backup.decks,
      cards: backup.cards,
    );
    await _reviewHistoryStore.replaceAll(backup.reviewLogs);
    await _excelImportStore.replaceAll(backup.excelImports);
    await _spaceSettingsStore.replaceAll(backup.spaceSettings);
    await _prefs.setBool(defaultSpaceMigrationKey, true);

    return RestoreCollectionResult(
      spaceCount: backup.spaces.length,
      cardCount: backup.cards.length,
      firstSpaceId: backup.spaces.isEmpty ? null : backup.spaces.first.id,
    );
  }
}
