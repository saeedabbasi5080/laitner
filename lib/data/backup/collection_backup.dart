import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';

const collectionBackupFormat = 'atilearn-backup';
const collectionBackupVersion = 1;

class BackupFormatException implements Exception {
  const BackupFormatException([this.message = '']);

  final String message;

  @override
  String toString() => message;
}

class CollectionBackup {
  const CollectionBackup({
    required this.exportedAt,
    required this.spaces,
    required this.decks,
    required this.cards,
    required this.reviewLogs,
    required this.excelImports,
    required this.spaceSettings,
  });

  final DateTime exportedAt;
  final List<LearningSpace> spaces;
  final List<Deck> decks;
  final List<Flashcard> cards;
  final List<ReviewLog> reviewLogs;
  final List<ExcelImport> excelImports;
  final Map<String, SpaceSettingsData> spaceSettings;

  Map<String, dynamic> toJson() => {
        'format': collectionBackupFormat,
        'version': collectionBackupVersion,
        'exportedAt': exportedAt.toIso8601String(),
        'spaces': spaces.map((space) => space.toJson()).toList(),
        'decks': decks.map((deck) => deck.toJson()).toList(),
        'cards': cards.map((card) => card.toJson()).toList(),
        'reviewLogs': reviewLogs.map((log) => log.toJson()).toList(),
        'excelImports': excelImports.map((item) => item.toJson()).toList(),
        'spaceSettings': {
          for (final entry in spaceSettings.entries) entry.key: entry.value.toJson(),
        },
      };

  factory CollectionBackup.fromJson(Map<String, dynamic> json) {
    if (json['format'] != collectionBackupFormat) {
      throw const BackupFormatException();
    }
    final version = json['version'] as int? ?? 0;
    if (version < 1 || version > collectionBackupVersion) {
      throw const BackupFormatException();
    }

    final settingsRaw = json['spaceSettings'];
    final settings = <String, SpaceSettingsData>{};
    if (settingsRaw is Map<String, dynamic>) {
      for (final entry in settingsRaw.entries) {
        final value = entry.value;
        if (value is Map<String, dynamic>) {
          settings[entry.key] = SpaceSettingsData.fromJson(value);
        }
      }
    }

    return CollectionBackup(
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      spaces: _mapList(json['spaces'], LearningSpace.fromJson),
      decks: _mapList(json['decks'], Deck.fromJson),
      cards: _mapList(json['cards'], Flashcard.fromJson),
      reviewLogs: _mapList(json['reviewLogs'], ReviewLog.fromJson),
      excelImports: _mapList(json['excelImports'], ExcelImport.fromJson),
      spaceSettings: settings,
    );
  }

  static List<T> _mapList<T>(
    Object? raw,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (raw is! List<dynamic>) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .toList();
  }
}
