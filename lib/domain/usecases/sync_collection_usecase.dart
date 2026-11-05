import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/repositories/sync_remote.dart';
import 'package:recall/domain/repositories/sync_state_store.dart';
import 'package:recall/domain/usecases/reconcile_card_progress.dart';

/// What one sync moved.
///
/// Returned rather than acted on, because what to *say* about a sync is the
/// interface's problem and what to *do* is the caller's. A background sync that
/// moved nothing is not worth mentioning; a first sync that received four
/// hundred cards is.
class SyncOutcome {
  const SyncOutcome({
    required this.reviewLogsSent,
    required this.structureSent,
    required this.applied,
  });

  /// How many review entries went up. Zero is the normal case.
  final int reviewLogsSent;

  /// Whether the spaces, decks and cards were uploaded.
  ///
  /// False when this device had nothing to say about them — see [SyncCollectionUseCase.sync].
  final bool structureSent;

  /// The collection the device now holds, after the pull.
  final SyncCollection applied;
}

/// Moves the collection between this device and the server.
///
/// Written as a use case rather than a repository because it is not a way of
/// reading or writing one thing — it is an operation with an order and a
/// failure story. `RestoreCollectionBackupUseCase` is the same shape and is the
/// precedent this follows.
///
/// ## The order, and why
///
/// Push, then pull. After a successful push the server holds everything this
/// device knows, so the pull that follows can only add: review entries recorded
/// on another surface, and structure from a device that got there first. Applied
/// in the other order, the pull would overwrite local work with a server copy
/// that had never seen it.
///
/// ## The one failure this design exists to prevent
///
/// A fresh device signing in has no spaces, no decks and no cards. A sync that
/// uploaded that emptiness would erase the account. So structure is uploaded
/// **only when this device actually has some** — an empty collection is not an
/// opinion about what the collection should be, it is the absence of one.
///
/// The cost of that rule is one edge case, and it is worth stating plainly: a
/// user who deliberately deletes every space will not see that propagate. Doing
/// so needs a mechanism for "this emptiness is intentional", which is a
/// distinction the current data model cannot express. Deliberately deferred.
///
/// ## The first sync merges
///
/// Uploading first is only safe once this device and the account have met. The
/// first sync after a sign-in — on a new phone, or after creating cards before
/// signing in — would otherwise replace the account's structure with whatever
/// this device happened to hold. So the first sync pulls before it pushes, keeps
/// the union of both sides (this device wins where an id exists on both), and
/// only then uploads. Nothing on either side is lost.
///
/// "First" is "no completed sync since the sign-in": [SyncStateStore.clear] runs
/// on every sign-out, so signing in to another account merges again.
class SyncCollectionUseCase {
  const SyncCollectionUseCase({
    required LocalDataSource localDataSource,
    required SyncRemote remote,
    required SyncStateStore state,
    DateTime Function()? clock,
  })  : _local = localDataSource,
        _remote = remote,
        _state = state,
        _clock = clock;

  final LocalDataSource _local;
  final SyncRemote _remote;
  final SyncStateStore _state;
  final DateTime Function()? _clock;

  /// Exchanges this device's work with the server's copy.
  ///
  /// Throws whatever the transport throws. Sync runs in the background, so the
  /// caller is responsible for guarding it — an unhandled failure here must not
  /// reach the user as a crash while they are studying.
  ///
  /// Records the time of a completed sync itself, so every caller — the screen
  /// and the nightly job alike — leaves the same trail, and the next sync knows
  /// it is no longer the first.
  Future<SyncOutcome> sync() async {
    if (await _state.readLastSyncedAt() == null) {
      await _mergeWithServer();
    }

    final spaces = await _local.getAllSpaces();
    final decks = await _local.getAllDecks();
    final cards = await _local.getAllCards();

    // An empty collection says nothing about the collection, so it is not
    // uploaded. See the class comment.
    final hasStructure = spaces.isNotEmpty;
    if (hasStructure) {
      await _remote.replaceCollection(
        spaces: spaces,
        decks: decks,
        cards: cards,
      );
    }

    final pending = await _reviewLogsToSend();
    if (pending.isNotEmpty) {
      await _remote.appendReviewLogs(pending);
      // Only now, and only for what was actually sent. Advancing the watermark
      // before a successful push would mean a failed upload is never retried.
      await _state.writeReviewLogWatermark(_newestOf(pending));
    }

    final pulled = await _remote.pull();
    await _apply(pulled);
    await _state.writeLastSyncedAt((_clock ?? DateTime.now)());

    return SyncOutcome(
      reviewLogsSent: pending.length,
      structureSent: hasStructure,
      applied: pulled,
    );
  }

  /// Folds the server's collection into this device's, keeping both.
  ///
  /// Applied locally before anything is uploaded, so the push that follows
  /// carries the union and an upload that fails half-way loses nothing: the
  /// device already holds everything. Review entries are merged too, because
  /// [_apply] replaces the local history with the pulled one and entries this
  /// device has not uploaded yet would otherwise vanish with it.
  Future<void> _mergeWithServer() async {
    final server = await _remote.pull();

    final reviewLogs = _union(
      local: await _local.getAllReviewLogs(),
      server: server.reviewLogs,
      id: (log) => log.id,
    );

    await _apply(
      SyncCollection(
        spaces: _union(
          local: await _local.getAllSpaces(),
          server: server.spaces,
          id: (space) => space.id,
        ),
        decks: _union(
          local: await _local.getAllDecks(),
          server: server.decks,
          id: (deck) => deck.id,
        ),
        cards: _union(
          local: await _local.getAllCards(),
          server: server.cards,
          id: (card) => card.id,
        ),
        reviewLogs: reviewLogs,
      ),
    );
  }

  /// Everything in [local], plus whatever [server] holds that [local] does not.
  static List<T> _union<T>({
    required List<T> local,
    required List<T> server,
    required String Function(T) id,
  }) {
    final held = {for (final item in local) id(item)};
    return [
      ...local,
      for (final item in server)
        if (!held.contains(id(item))) item,
    ];
  }

  /// Replaces this device's collection with the server's.
  ///
  /// The other half of the first-sign-in question, and never called
  /// automatically: it discards whatever is on the device, so the user has to
  /// have chosen it. `sync()` covers every other case.
  Future<SyncOutcome> download() async {
    final pulled = await _remote.pull();
    await _apply(pulled);

    return SyncOutcome(
      reviewLogsSent: 0,
      structureSent: false,
      applied: pulled,
    );
  }

  /// How many reviews have been recorded since the last successful upload.
  ///
  /// Counts strictly *after* the watermark, which is not quite what [sync] sends.
  /// The send includes the entry sitting on the watermark — deliberately, because
  /// excluding it could lose a review recorded in the same clock tick — and
  /// counting the same way would make this read "1" forever. A badge that never
  /// clears is a badge the user stops seeing, which is worse than not having one.
  Future<int> reviewsSinceLastUpload() async {
    final logs = await _local.getAllReviewLogs();
    if (logs.isEmpty) return 0;

    final watermark = await _state.readReviewLogWatermark();
    if (watermark == null) return logs.length;

    return logs.where((log) => log.reviewedAt.isAfter(watermark)).length;
  }

  /// The review entries the server has not been sent.
  ///
  /// The comparison is `>=`, not `>`, so an entry recorded at exactly the
  /// watermark is sent again rather than skipped. Re-sending costs one row;
  /// skipping costs a review the user did. The ids are deterministic
  /// (`reviewedAt` and the card id), so a duplicate is an upsert on the server
  /// rather than a second row.
  Future<List<ReviewLog>> _reviewLogsToSend() async {
    final all = await _local.getAllReviewLogs();
    if (all.isEmpty) return const [];

    final watermark = await _state.readReviewLogWatermark();
    if (watermark == null) return all;

    return all
        .where((log) => !log.reviewedAt.isBefore(watermark))
        .toList(growable: false);
  }

  Future<void> _apply(SyncCollection collection) {
    // Corrected on the way in, before it reaches the database, so nothing ever
    // reads a box that disagrees with the history behind it. Every path that
    // writes a pulled collection goes through here, `download` included.
    //
    // The server's own copy is left alone. It is the same kind of cache, and the
    // next sync uploads this corrected structure over it — but it is never *read*
    // without passing through here first, so a stale value there cannot reach the
    // user.
    final reconciled = reconcileCardProgress(
      cards: collection.cards,
      reviewLogs: collection.reviewLogs,
    );

    return _local.replaceCollection(
      spaces: collection.spaces,
      decks: collection.decks,
      cards: reconciled,
      reviewLogs: collection.reviewLogs,
    );
  }

  static DateTime _newestOf(List<ReviewLog> logs) =>
      logs.map((log) => log.reviewedAt).reduce((a, b) => a.isAfter(b) ? a : b);
}
