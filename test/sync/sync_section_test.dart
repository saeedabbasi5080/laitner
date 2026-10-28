import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/sync_remote.dart';
import 'package:recall/domain/usecases/sync_collection_usecase.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';
import 'package:recall/presentation/blocs/sync/sync_cubit.dart';
import 'package:recall/presentation/widgets/sync_section.dart';

import '../auth/fake_auth_api_client.dart';
import '../support/in_memory_sync_state_store.dart';

class _FakeSync implements SyncCollectionUseCase {
  AuthError? failure;
  int pending = 0;
  int syncCalls = 0;

  @override
  Future<SyncOutcome> sync() async {
    syncCalls++;
    if (failure != null) throw failure!;
    return const SyncOutcome(
      reviewLogsSent: 0,
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

  setUp(() => sync = _FakeSync());

  Future<AuthCubit> authCubit({required bool signedIn}) async {
    final cubit = AuthCubit(
      api: FakeAuthApiClient(),
      tokenStore: signedIn
          ? InMemoryAuthTokenStore(
              const StoredSession(
                accessToken: 'token',
                user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
              ),
            )
          : InMemoryAuthTokenStore(),
    );
    await cubit.restore();
    return cubit;
  }

  SyncCubit syncCubit({InMemorySyncStateStore? store}) => SyncCubit(
        sync: sync,
        state: store ?? InMemorySyncStateStore(),
        // Never asked to sync automatically here — the section only refreshes and
        // runs on request — but the cubit needs somewhere to look for an account.
        tokenStore: InMemoryAuthTokenStore(
          const StoredSession(
            accessToken: 'token',
            user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
          ),
        ),
      );

  Widget wrap(AuthCubit auth, SyncCubit sync) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: auth),
        BlocProvider.value(value: sync),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(AppAccent.lavender),
        home: Scaffold(
          body: SingleChildScrollView(child: SyncSection(cubit: sync)),
        ),
      ),
    );
  }

  /// Renders and lets the local read finish.
  ///
  /// Explicit pumps rather than `pumpAndSettle`: the running state holds a progress
  /// indicator, which never stops animating.
  Future<void> render(WidgetTester tester, AuthCubit auth, SyncCubit sync) async {
    await tester.pumpWidget(wrap(auth, sync));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows nothing at all for somebody with no account',
      (tester) async {
    // There is nothing to sync and the question it answers is not one they have.
    await render(tester, await authCubit(signedIn: false), syncCubit());

    expect(find.text(AppStrings.syncTitle), findsNothing);
    expect(find.text(AppStrings.syncNow), findsNothing);
  });

  testWidgets('shows the sync block once signed in', (tester) async {
    await render(tester, await authCubit(signedIn: true), syncCubit());

    expect(find.text(AppStrings.syncTitle), findsOneWidget);
    expect(find.text(AppStrings.syncNow), findsOneWidget);
    expect(find.text(AppStrings.syncNeverRun), findsOneWidget);
  });

  testWidgets('reports when the last sync was', (tester) async {
    final store = InMemorySyncStateStore(
      null,
      DateTime.now().subtract(const Duration(hours: 3)),
    );

    await render(tester, await authCubit(signedIn: true), syncCubit(store: store));

    expect(find.text(AppStrings.syncLastHours(3)), findsOneWidget);
  });

  testWidgets('says how much is waiting, only when something is', (tester) async {
    sync.pending = 5;

    await render(tester, await authCubit(signedIn: true), syncCubit());

    expect(find.text(AppStrings.syncPendingSave(5)), findsOneWidget);
  });

  testWidgets('does not show a pending line when nothing is waiting',
      (tester) async {
    // A permanent "0 reviews pending" is a line the user stops reading.
    await render(tester, await authCubit(signedIn: true), syncCubit());

    expect(find.text(AppStrings.syncPendingSave(0)), findsNothing);
  });

  testWidgets('runs a sync when the button is pressed', (tester) async {
    await render(tester, await authCubit(signedIn: true), syncCubit());

    await tester.tap(find.text(AppStrings.syncNow));
    await tester.pump();

    expect(sync.syncCalls, 1);
  });

  testWidgets('reports a failure', (tester) async {
    sync.failure = const AuthError(AuthFailure.network, message: 'سرور در دسترس نیست.');

    await render(tester, await authCubit(signedIn: true), syncCubit());
    await tester.tap(find.text(AppStrings.syncNow));
    await tester.pump();

    expect(find.text('سرور در دسترس نیست.'), findsOneWidget);
  });

  group('after being signed out from somewhere else', () {
    Future<SyncCubit> removedCubit() async {
      sync.failure = const AuthError(
        AuthFailure.deviceSignedOut,
        message: 'این دستگاه از حساب خارج شده است.',
      );
      final cubit = syncCubit();
      await cubit.run();
      return cubit;
    }

    testWidgets('explains what happened even though the account is gone',
        (tester) async {
      // The case that matters most: there is no account block left to explain it,
      // so without this the app would simply appear to have forgotten the user.
      final syncCubitReady = await removedCubit();

      await render(tester, await authCubit(signedIn: false), syncCubitReady);

      expect(find.text(AppStrings.syncDeviceRemoved), findsOneWidget);
    });

    testWidgets('offers no button, because nothing can be done from here',
        (tester) async {
      final syncCubitReady = await removedCubit();

      await render(tester, await authCubit(signedIn: false), syncCubitReady);

      expect(find.text(AppStrings.syncNow), findsNothing);
    });

    testWidgets('does not accuse somebody who has since signed in',
        (tester) async {
      // The flag outlives the sign-out it describes. Without the gate on being
      // signed out, a stale one would tell a fresh sign-in they had been removed.
      final syncCubitReady = await removedCubit();

      await render(tester, await authCubit(signedIn: true), syncCubitReady);

      expect(find.text(AppStrings.syncDeviceRemoved), findsNothing);
      expect(find.text(AppStrings.syncNow), findsOneWidget);
    });
  });
}
