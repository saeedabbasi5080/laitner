import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/migration/legacy_review_history_reader.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _reviewLogMigrationKey = 'recall_review_log_isar_migration_v1';

/// Moves review history out of the SharedPreferences JSON blob and into the
/// database, where it can be indexed and queried by date range.
///
/// Runs before [runSpaceMigration] so the back-fill of empty `spaceId` values
/// happens on rows that are already in their final home. The legacy key is
/// deliberately left untouched.
Future<void> runReviewLogMigration({
  required LocalDataSource localDataSource,
  required SharedPreferences prefs,
}) async {
  if (prefs.getBool(_reviewLogMigrationKey) == true) return;

  final legacy = LegacyReviewHistoryReader(prefs).readAll();
  if (legacy.isEmpty) {
    await prefs.setBool(_reviewLogMigrationKey, true);
    return;
  }

  // De-duplicate by id: the legacy writer appended unconditionally, so a
  // crashed write followed by a retry can leave the same review twice.
  final seen = <String>{};
  final unique = <ReviewLog>[];
  for (final log in legacy) {
    if (log.id.isEmpty || !seen.add(log.id)) continue;
    unique.add(log);
  }

  await localDataSource.replaceReviewLogs(unique);
  await prefs.setBool(_reviewLogMigrationKey, true);
}