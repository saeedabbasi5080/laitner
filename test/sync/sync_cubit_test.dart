import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/sync_remote.dart';
import 'package:recall/domain/usecases/sync_collection_usecase.dart';
import 'package:recall/presentation/blocs/sync/sync_cubit.dart';

import '../support/in_memory_sync_state_store.dart';

/// A sync that answers from fields rather than from a server.
class _FakeSync implements SyncCollectionUseCase {
  AuthError? failure;
  int pending = 0;
  int syncCalls = 0;

  @override
  Future<SyncOutcome> sync() async {
    syncCalls++;
    if (failure != null) throw failure!;
    return const SyncOutcome(
      reviewLogsSent: 2,
      structureSent: true,
      applied: SyncCollection.empty(),
    );
  }

  @override
  Future<SyncOutcome> download() async => throw UnimplementedError();

  @override
  Future<int> reviewsSinceLastUpload() async => pending;
}

void main() {
  late _FakeSync sync;
  late InMemorySyncStateStore store;
  late int signedOutCalls;
  late DateTime now;

  SyncCubit build({bool signedIn = true, Duration? interval}) {
    return SyncCubit(
      sync: sync,
      state: store,
      tokenStore: InMemoryAuthTokenStore(
        signedIn
            ? const StoredSession(
                accessToken: 'token',
                user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
              )
            : null,
      ),
      onSignedOutElsewhere: () async => signedOutCalls++,
      clock: () => now,
      autoSyncInterval: interval,
    );
  }

  setUp(() {
    sync = _FakeSync();
    store = InMemorySyncStateStore();
    signedOutCalls = 0;
    now = DateTime(2026, 1, 2, 12);
  });

  group('before anything is read', () {
    test('is unknown, so nothing claims a status it has not checked', () {
      expect(build().state.status, SyncStatus.unknown);
    });
  });

  group('refresh', () {
    test('reports what is already known locally', () async {
      store = InMemorySyncStateStore(null, DateTime(2026, 1, 1, 9));
      sync.pending = 4;
      final cubit = build();

      await cubit.refresh();

      expect(cubit.state.status, SyncStatus.idle);
      expect(cubit.state.lastSyncedAt, DateTime(2026, 1, 1, 9));
      expect(cubit.state.pendingReviews, 4);
      expect(cubit.state.hasPending, isTrue);
    });

    test('asks the server for nothing', () async {
      final cubit = build();

      await cubit.refresh();

      expect(sync.syncCalls, 0);
    });

    test('clears a previous error', () async {
      sync.failure = const AuthError(AuthFailure.network, message: 'قطع شد');
      final cubit = build();
      await cubit.run();

      sync.failure = null;
      await cubit.refresh();

      expect(cubit.state.error, isNull);
    });
  });

  group('run', () {
    test('reports success and records when it happened', () async {
      final cubit = build();

      await cubit.run();

      expect(cubit.state.status, SyncStatus.succeeded);
      expect(cubit.state.lastSyncedAt, now);
      expect(store.lastSyncedAt, now);
      expect(cubit.state.lastSentReviews, 2);
    });

    test('recounts what is waiting, after the watermark has moved', () async {
      // Counted after rather than before, so the figure shows what is *still*
      // waiting instead of what was just sent.
      sync.pending = 7;
      final cubit = build();

      await cubit.run();

      expect(cubit.state.pendingReviews, 7);
    });

    test('reports a refusal rather than throwing', () async {
      sync.failure = const AuthError(AuthFailure.network, message: 'سرور در دسترس نیست.');
      final cubit = build();

      await cubit.run();

      expect(cubit.state.status, SyncStatus.failed);
      expect(cubit.state.error, 'سرور در دسترس نیست.');
      expect(store.lastSyncedAt, isNull);
    });

    test('ignores a second run while one is in flight', () async {
      final cubit = build();

      final first = cubit.run();
      await cubit.run();
      await first;

      expect(sync.syncCalls, 1);
    });
  });

  group('a device signed out from somewhere else', () {
    setUp(() {
      sync.failure = const AuthError(
        AuthFailure.deviceSignedOut,
        message: 'این دستگاه از حساب خارج شده است.',
      );
    });

    test('hands the sign-out over rather than leaving it to a screen', () async {
      // Every caller of a sync would otherwise have to know this one code, and the
      // one that forgot would leave the user on a screen whose every action fails.
      final cubit = build();

      await cubit.run();

      expect(signedOutCalls, 1);
    });

    test('is remembered, because the account block will be gone', () async {
      final cubit = build();

      await cubit.run();

      expect(cubit.state.signedOutElsewhere, isTrue);
      expect(cubit.state.status, SyncStatus.failed);
    });

    test('is not recorded as a successful sync', () async {
      final cubit = build();

      await cubit.run();

      expect(store.lastSyncedAt, isNull);
    });

    test('the notice can be dismissed', () async {
      final cubit = build();
      await cubit.run();

      cubit.dismissNotice();

      expect(cubit.state.signedOutElsewhere, isFalse);
    });

    test('an ordinary failure is not mistaken for it', () async {
      sync.failure = const AuthError(AuthFailure.network, message: 'قطع شد');
      final cubit = build();

      await cubit.run();

      expect(cubit.state.signedOutElsewhere, isFalse);
      expect(signedOutCalls, 0);
    });

    test('goes away once a sync works again', () async {
      // A successful sync is proof this device is still allowed to sync, so a notice
      // about a past removal no longer describes anything.
      sync.failure = const AuthError(
        AuthFailure.deviceSignedOut,
        message: 'این دستگاه از حساب خارج شده است.',
      );
      final cubit = build();
      await cubit.run();
      expect(cubit.state.signedOutElsewhere, isTrue);

      sync.failure = null;
      await cubit.run();

      expect(cubit.state.signedOutElsewhere, isFalse);
      expect(cubit.state.status, SyncStatus.succeeded);
    });
  });

  group('autoSync', () {
    test('does nothing at all when nobody is signed in', () async {
      // Checked here rather than left to the remote, which refuses anyway but would
      // leave a failed status behind for somebody who has no account and never
      // asked for one.
      final cubit = build(signedIn: false);

      await cubit.autoSync();

      expect(sync.syncCalls, 0);
      expect(cubit.state.status, SyncStatus.unknown);
      expect(cubit.state.error, isNull);
    });

    test('runs when there is an account', () async {
      final cubit = build();

      await cubit.autoSync();

      expect(sync.syncCalls, 1);
      expect(cubit.state.status, SyncStatus.succeeded);
    });

    test('does not run twice in quick succession', () async {
      // Coming back to the app is not a reason to sync if it happened a minute ago.
      final cubit = build(interval: const Duration(minutes: 5));

      await cubit.autoSync();
      await cubit.autoSync();

      expect(sync.syncCalls, 1);
    });

    test('runs again once the interval has passed', () async {
      final cubit = build(interval: const Duration(minutes: 5));
      await cubit.autoSync();

      now = now.add(const Duration(minutes: 6));
      await cubit.autoSync();

      expect(sync.syncCalls, 2);
    });

    test('says nothing when it fails', () async {
      // The user did not ask for this one, and an error appearing in settings
      // because they switched apps would be an interruption rather than information.
      sync.failure = const AuthError(AuthFailure.network, message: 'قطع شد');
      final cubit = build();

      await cubit.autoSync();

      expect(cubit.state.status, SyncStatus.idle);
      expect(cubit.state.error, isNull);
    });

    test('still says how much is waiting when it fails', () async {
      // That count is the honest signal, and the one the user acts on.
      sync.failure = const AuthError(AuthFailure.network, message: 'قطع شد');
      sync.pending = 3;
      final cubit = build();

      await cubit.autoSync();

      expect(cubit.state.pendingReviews, 3);
    });

    test('still explains a removal, because nothing else will', () async {
      sync.failure = const AuthError(
        AuthFailure.deviceSignedOut,
        message: 'این دستگاه از حساب خارج شده است.',
      );
      final cubit = build();

      await cubit.autoSync();

      expect(cubit.state.signedOutElsewhere, isTrue);
      expect(signedOutCalls, 1);
    });

    test('does nothing while a sync is already in flight', () async {
      final cubit = build();

      final first = cubit.run();
      await cubit.autoSync();
      await first;

      expect(sync.syncCalls, 1);
    });
  });
}
