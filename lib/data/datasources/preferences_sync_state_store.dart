import 'package:recall/domain/repositories/sync_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The sync's bookkeeping, in preferences.
///
/// One value, written as the same kind of timestamp the review history uses: wall
/// clock with no offset. That is deliberate and not a shortcut — the watermark is
/// compared against `reviewedAt`, those are stored the same way, so both are read
/// back with the current zone applied and the comparison stays consistent even if
/// the device crosses a time zone between syncs. Storing this one as UTC while the
/// history stayed local would be the thing that broke it.
class PreferencesSyncStateStore implements SyncStateStore {
  PreferencesSyncStateStore({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;

  /// Not under the auth namespace. It belongs to the account, and it is cleared
  /// by [clear] on sign-out rather than by the auth store, because only this class
  /// knows what it is holding.
  static const String watermarkKey = 'recall.sync.review_watermark';

  /// When this device last finished a sync. A real instant, unlike the watermark:
  /// nothing is ever compared against it, it is only shown.
  static const String lastSyncedKey = 'recall.sync.last_synced_at';

  @override
  Future<DateTime?> readReviewLogWatermark() async {
    final raw = _prefs.getString(watermarkKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> writeReviewLogWatermark(DateTime value) async {
    await _prefs.setString(watermarkKey, value.toIso8601String());
  }

  @override
  Future<DateTime?> readLastSyncedAt() async {
    final raw = _prefs.getString(lastSyncedKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> writeLastSyncedAt(DateTime value) async {
    await _prefs.setString(lastSyncedKey, value.toIso8601String());
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(watermarkKey);
    await _prefs.remove(lastSyncedKey);
  }
}
