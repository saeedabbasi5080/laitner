part of 'sync_cubit.dart';

/// Where a sync has got to.
enum SyncStatus {
  /// Nothing has been read or run yet.
  unknown,

  /// The local picture is known and nothing is in flight.
  idle,

  /// A sync is running.
  running,

  /// The last run finished.
  succeeded,

  /// The last run was refused.
  failed,
}

class SyncState extends Equatable {
  const SyncState({
    this.status = SyncStatus.unknown,
    this.lastSyncedAt,
    this.pendingReviews = 0,
    this.error,
    this.signedOutElsewhere = false,
    this.lastSentReviews = 0,
  });

  final SyncStatus status;

  /// When this device last completed a sync. Null when it never has.
  final DateTime? lastSyncedAt;

  /// Reviews recorded since the last successful upload.
  ///
  /// Zero after a successful sync. The send includes one extra entry on purpose —
  /// see `SyncCollectionUseCase.reviewsSinceLastUpload` — and counting it here
  /// would leave this reading "1" forever.
  final int pendingReviews;

  /// Ready to show, in Persian, or null.
  final String? error;

  /// Whether the server refused because this device was signed out elsewhere.
  ///
  /// Kept separately from [error] because it outlives the sign-out: once the token
  /// is gone there is no account section left to explain anything, and this is what
  /// the screen has to show instead of simply appearing to have forgotten the user.
  final bool signedOutElsewhere;

  /// How many entries the last run uploaded. Includes the boundary one.
  final int lastSentReviews;

  bool get isRunning => status == SyncStatus.running;

  bool get canRun => !isRunning;

  bool get hasPending => pendingReviews > 0;

  bool get neverSynced => lastSyncedAt == null;

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    int? pendingReviews,
    String? error,
    bool? signedOutElsewhere,
    int? lastSentReviews,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      error: clearError ? null : (error ?? this.error),
      signedOutElsewhere: signedOutElsewhere ?? this.signedOutElsewhere,
      lastSentReviews: lastSentReviews ?? this.lastSentReviews,
    );
  }

  @override
  List<Object?> get props => [
        status,
        lastSyncedAt,
        pendingReviews,
        error,
        signedOutElsewhere,
        lastSentReviews,
      ];
}
