import 'package:recall/data/backup/collection_backup.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';

class ExportCollectionBackupUseCase {
  ExportCollectionBackupUseCase({
    required LocalDataSource localDataSource,
    required ReviewHistoryStore reviewHistoryStore,
    required ExcelImportStore excelImportStore,
    required SpaceSettingsStore spaceSettingsStore,
  })  : _localDataSource = localDataSource,
        _reviewHistoryStore = reviewHistoryStore,
        _excelImportStore = excelImportStore,
        _spaceSettingsStore = spaceSettingsStore;

  final LocalDataSource _localDataSource;
  final ReviewHistoryStore _reviewHistoryStore;
  final ExcelImportStore _excelImportStore;
  final SpaceSettingsStore _spaceSettingsStore;

  Future<CollectionBackup> call({DateTime? now}) async {
    return CollectionBackup(
      exportedAt: now ?? DateTime.now(),
      spaces: await _localDataSource.getAllSpaces(),
      decks: await _localDataSource.getAllDecks(),
      cards: await _localDataSource.getAllCards(),
      reviewLogs: _reviewHistoryStore.getAll(),
      excelImports: await _excelImportStore.getAll(),
      spaceSettings: await _spaceSettingsStore.exportAll(),
    );
  }
}
