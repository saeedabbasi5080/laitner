/// Where synchronisation keeps its own bookkeeping.
///
/// One value today: how far the review history has been uploaded. Its own port
/// rather than a field on something else, because it has to survive a sign-out
/// being cleared and a failed push not being advanced, and those are decisions
/// this type is the only place for.
///
/// Deliberately not a general key-value store. A port that can hold anything
/// will hold anything, and then the sync's state is spread across keys nobody
/// can enumerate.
abstract interface class SyncStateStore {
  /// The `reviewedAt` of the newest review the server has confirmed receiving.
  ///
  /// Null means nothing has ever been uploaded from this device — either it has
  /// never synced, or it synced before there was any history to send.
  Future<DateTime?> readReviewLogWatermark();

  /// Records that the server now holds everything up to [value].
  ///
  /// Only ever called after a push has succeeded. Writing it optimistically
  /// would mean a failed upload is never retried, which loses reviews silently —
  /// the one failure this whole design exists to prevent.
  Future<void> writeReviewLogWatermark(DateTime value);

  /// When this device last completed a sync, or null if it never has.
  ///
  /// Kept for the one thing a user actually wants to know from a sync screen:
  /// whether what is on the server is recent.
  Future<DateTime?> readLastSyncedAt();

  Future<void> writeLastSyncedAt(DateTime value);

  /// Forgets everything, on sign-out.
  ///
  /// The watermark belongs to an account, not to a device. Keeping it after a
  /// sign-out would make the next account's first push skip entries it had never
  /// sent.
  Future<void> clear();
}
