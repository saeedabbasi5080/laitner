import 'package:recall/domain/repositories/sync_state_store.dart';

/// [SyncStateStore] that keeps its two values in fields.
class InMemorySyncStateStore implements SyncStateStore {
  InMemorySyncStateStore([this._watermark, this._lastSyncedAt]);

  DateTime? _watermark;
  DateTime? _lastSyncedAt;

  /// How many times the watermark was written, for assertions about a failed push
  /// not advancing it.
  int writes = 0;

  /// How many times it was cleared.
  int clears = 0;

  DateTime? get watermark => _watermark;

  DateTime? get lastSyncedAt => _lastSyncedAt;

  @override
  Future<DateTime?> readReviewLogWatermark() async => _watermark;

  @override
  Future<void> writeReviewLogWatermark(DateTime value) async {
    writes++;
    _watermark = value;
  }

  @override
  Future<DateTime?> readLastSyncedAt() async => _lastSyncedAt;

  @override
  Future<void> writeLastSyncedAt(DateTime value) async {
    _lastSyncedAt = value;
  }

  @override
  Future<void> clear() async {
    clears++;
    _watermark = null;
    _lastSyncedAt = null;
  }
}
