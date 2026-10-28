import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/sync_state_store.dart';
import 'package:recall/domain/usecases/sync_collection_usecase.dart';

part 'sync_state.dart';

/// Running a sync, and saying what happened.
///
/// Thin on purpose: the rules are in [SyncCollectionUseCase] and the state lives in
/// [SyncStateStore]. What is left here is the part neither of those can own — when
/// to run, what to tell the user, and what to do when the server says this device
/// is no longer allowed to.
class SyncCubit extends Cubit<SyncState> {
  SyncCubit({
    required SyncCollectionUseCase sync,
    required SyncStateStore state,
    required AuthTokenStore tokenStore,
    Future<void> Function()? onSignedOutElsewhere,
    DateTime Function()? clock,
    Duration? autoSyncInterval,
  })  : _sync = sync,
        _state = state,
        _tokenStore = tokenStore,
        _onSignedOutElsewhere = onSignedOutElsewhere,
        _now = clock ?? DateTime.now,
        _autoSyncInterval = autoSyncInterval ?? const Duration(minutes: 5),
        super(const SyncState());

  final SyncCollectionUseCase _sync;
  final SyncStateStore _state;

  /// Read only to answer "is there an account at all?".
  ///
  /// A sync is for somebody with an account, and a launch with nobody signed in
  /// should do nothing rather than produce a failure nobody asked for.
  final AuthTokenStore _tokenStore;

  /// What to do when the server refuses because this device was removed.
  ///
  /// A callback rather than a reference to the sign-in cubit: this class should not
  /// know that sign-in is even where the token comes from, and a test can watch the
  /// callback without a second cubit. The same shape `StudyCubit` uses for its
  /// schedule change.
  final Future<void> Function()? _onSignedOutElsewhere;

  final DateTime Function() _now;

  /// How close together two automatic syncs may be.
  ///
  /// Only automatic ones. A person pressing the button is asking, and answering
  /// "not yet" would be the wrong reply.
  final Duration _autoSyncInterval;

  /// When an automatic sync last started.
  ///
  /// In memory on purpose. It exists to stop a burst of app switches from each
  /// starting one, and a launch is a fresh process — which is how a failed sync
  /// gets retried rather than being held off by a timestamp written before the
  /// network came back.
  DateTime? _lastAutomaticAttempt;

  /// Reads what is known locally: when the last sync was, and how much is waiting.
  ///
  /// No network. This runs whenever the screen opens, and a settings screen should
  /// not wait on a server to show what it already knows.
  Future<void> refresh() async {
    final lastSyncedAt = await _state.readLastSyncedAt();
    final pending = await _sync.reviewsSinceLastUpload();
    if (isClosed) return;

    emit(state.copyWith(
      status: SyncStatus.idle,
      lastSyncedAt: lastSyncedAt,
      pendingReviews: pending,
      clearError: true,
    ));
  }

  /// Syncs if it is worth doing, and says nothing if it is not.
  ///
  /// Called on start and on returning to the foreground. Silent about failures: the
  /// user did not ask for this one, and an error appearing in settings because they
  /// switched apps would be an interruption rather than information. What is still
  /// waiting is refreshed either way — that count is the honest signal, and it is
  /// the one the user will act on.
  Future<void> autoSync() async {
    if (state.isRunning) return;

    // Nothing to sync, and nothing to report. Checked here rather than left to the
    // remote, which would refuse anyway but would leave a failed status behind for
    // somebody who has no account and never asked for one.
    if (!await _hasSession()) return;

    final last = _lastAutomaticAttempt;
    if (last != null && _now().difference(last) < _autoSyncInterval) return;

    _lastAutomaticAttempt = _now();
    await run(quiet: true);
  }

  /// Runs a sync.
  ///
  /// Never throws. A sync that fails is an ordinary outcome — the network is gone,
  /// the server is down, this device was signed out — and the screen has to survive
  /// all of them without a try/catch.
  ///
  /// [quiet] suppresses the error for a sync the user did not ask for. It does not
  /// suppress the removal notice: that one has to be explained, because after it
  /// there is no account block left to explain anything.
  Future<void> run({bool quiet = false}) async {
    if (state.isRunning) return;

    emit(state.copyWith(status: SyncStatus.running, clearError: true));

    try {
      final outcome = await _sync.sync();

      final now = _now();
      await _state.writeLastSyncedAt(now);

      // After the watermark has moved, so this reads what is *still* waiting rather
      // than what was just sent.
      final pending = await _sync.reviewsSinceLastUpload();
      if (isClosed) return;

      emit(state.copyWith(
        status: SyncStatus.succeeded,
        lastSyncedAt: now,
        pendingReviews: pending,
        lastSentReviews: outcome.reviewLogsSent,
        // Cleared here because a sync that worked is proof this device is still
        // allowed to sync. Only the flag, not the history: the notice described a
        // past removal, and a successful sync says the situation has moved on.
        signedOutElsewhere: false,
      ));
    } on AuthError catch (error) {
      // A failed sync still tells the truth about how much is waiting, so the count
      // is refreshed on the way out of both paths.
      final pending = await _sync.reviewsSinceLastUpload();
      if (isClosed) return;

      // A device removed elsewhere cannot sync again until somebody signs in here.
      // Handled in this class rather than left to the screen, because every caller
      // would otherwise have to know this one code — and the one that forgot would
      // leave the user on a screen whose every action fails with no explanation.
      if (error.failure == AuthFailure.deviceSignedOut) {
        await _onSignedOutElsewhere?.call();
        if (isClosed) return;
        emit(state.copyWith(
          status: SyncStatus.failed,
          signedOutElsewhere: true,
          error: error.message,
          pendingReviews: pending,
        ));
        return;
      }

      if (quiet) {
        emit(state.copyWith(
          status: SyncStatus.idle,
          pendingReviews: pending,
          clearError: true,
        ));
        return;
      }

      emit(state.copyWith(
        status: SyncStatus.failed,
        error: error.message,
        pendingReviews: pending,
      ));
    }
  }

  /// Acknowledges the notice that this device was signed out elsewhere.
  void dismissNotice() {
    if (state.signedOutElsewhere) {
      emit(state.copyWith(signedOutElsewhere: false, clearError: true));
    }
  }

  Future<bool> _hasSession() async {
    try {
      final stored = await _tokenStore.read();
      return stored != null && stored.accessToken.isNotEmpty;
    } catch (_) {
      // Storage that will not open is indistinguishable, from here, from having no
      // session — and either way there is nothing to sync.
      return false;
    }
  }
}
