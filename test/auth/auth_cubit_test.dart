import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/auth_api_client.dart';
import 'package:recall/data/datasources/device_identity.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';

import 'fake_auth_api_client.dart';

void main() {
  late FakeAuthApiClient api;
  late InMemoryAuthTokenStore store;
  late DateTime now;
  late AuthCubit cubit;

  /// Builds a cubit whose clock the test moves by hand, so a five-minute cooldown
  /// can be tested in microseconds.
  AuthCubit build({DateTime Function()? clock}) {
    return AuthCubit(
      api: api,
      tokenStore: store,
      clock: clock ?? () => now,
    );
  }

  setUp(() {
    api = FakeAuthApiClient();
    store = InMemoryAuthTokenStore();
    now = DateTime(2026, 1, 1, 12);
    cubit = build();
  });

  tearDown(() async {
    await cubit.close();
  });

  group('start state', () {
    test('begins unknown, so nothing claims a status it has not checked', () {
      expect(cubit.state.status, AuthStatus.unknown);
    });

    test('does not warn about backups while unknown', () {
      // Warning someone who may well be signed in that they cannot recover their
      // cards would simply be wrong.
      expect(cubit.state.shouldWarnAboutNoBackup, isFalse);
    });
  });

  group('restore', () {
    test('reports signed out when nothing is stored', () async {
      await cubit.restore();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(cubit.state.isSignedIn, isFalse);
      expect(cubit.state.shouldWarnAboutNoBackup, isTrue);
    });

    test('reports signed in from the stored session, then verifies', () async {
      store.write(StoredSession(
        accessToken: 'stored-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
      ));

      await cubit.restore();

      expect(cubit.state.isSignedIn, isTrue);
      expect(cubit.state.verified, isTrue);
      expect(api.meCalls, 1);
    });

    test('prefers the server copy over the stored one', () async {
      // The stored user may be months old — a name changed on another device, or
      // an account that was renamed. The server's answer is the current truth,
      // so it replaces what was on disk rather than being second-guessed.
      store.write(StoredSession(
        accessToken: 'stored-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
      ));

      await cubit.restore();

      expect(cubit.state.user!.phoneNumber, '0912 123 4567');
    });

    test('shows the stored user before the server answers', () async {
      // Otherwise the settings tile would be empty for as long as the server takes
      // to reply, which on a slow connection is a visible blank.
      await store.write(StoredSession(
        accessToken: 'stored-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
      ));
      final gate = Completer<void>();
      await cubit.close();
      cubit = AuthCubit(api: _SlowApi(gate), tokenStore: store, clock: () => now);

      final restoring = cubit.restore();
      // Yield once so the read completes and the first emit lands; the second is
      // still waiting on the gate.
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSignedIn, isTrue);
      expect(cubit.state.user!.phoneNumber, '0912 111 2222');
      expect(cubit.state.verified, isFalse);

      gate.complete();
      await restoring;

      expect(cubit.state.user!.phoneNumber, '0912 123 4567');
      expect(cubit.state.verified, isTrue);
    });

    test('stays signed in but unverified when the server cannot be reached', () async {
      // The app works offline by design, so a launch with no network must not
      // cost the user the fact that they are signed in.
      store.write(StoredSession(
        accessToken: 'stored-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
      ));
      api.failWith(AuthFailure.network);

      await cubit.restore();

      expect(cubit.state.isSignedIn, isTrue);
      expect(cubit.state.verified, isFalse);
      expect(cubit.state.shouldWarnAboutNoBackup, isFalse);
      // The token is kept: a network that is down is not a reason to forget it.
      expect(store.hasSession, isTrue);
    });

    test('signs out when the server rejects the token', () async {
      store.write(StoredSession(
        accessToken: 'stale-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
      ));
      api.failWith(AuthFailure.unauthorized);

      await cubit.restore();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(store.hasSession, isFalse);
    });

    test('discards an expired token without asking the server', () async {
      store.write(StoredSession(
        accessToken: 'expired-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
        expiresAt: now.subtract(const Duration(minutes: 1)),
      ));

      await cubit.restore();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(store.hasSession, isFalse);
      expect(api.meCalls, 0);
    });

    test('keeps a token that has not expired', () async {
      store.write(StoredSession(
        accessToken: 'fresh-token',
        user: const AuthUser(id: 'u1', phoneNumber: '0912 111 2222'),
        expiresAt: now.add(const Duration(days: 30)),
      ));

      await cubit.restore();

      expect(cubit.state.isSignedIn, isTrue);
    });
  });

  group('requestCode', () {
    test('refuses an impossible number without spending a request', () async {
      // Validating locally is what makes this work with no network at all.
      await cubit.requestCode('12345');

      expect(api.requestCodeCalls, 0);
      expect(cubit.state.error!.failure, AuthFailure.invalidPhone);
      expect(cubit.state.error!.message, AppStrings.phoneNumberInvalid);
    });

    test('sends the number grouped, as the server returns it', () async {
      await cubit.requestCode('09121234567');

      expect(api.requestCodeCalls, 1);
      expect(api.lastPhoneNumber, '0912 123 4567');
      expect(cubit.state.isAwaitingCode, isTrue);
    });

    test('starts the countdown at the server cooldown', () async {
      await cubit.requestCode('09121234567');

      expect(cubit.state.countdown, 120);
      expect(cubit.state.canResend, isFalse);
      expect(cubit.state.expiresInSeconds, 300);
    });

    test('falls back to the code lifetime when no resend delay is given', () async {
      // Without this the countdown would be zero and the button would be live
      // against an endpoint that refuses, which is worse than a wait.
      api = FakeAuthApiClient(
        dispatch: const CodeDispatch(expiresInSeconds: 300, resendAfterSeconds: 0),
      );
      await cubit.close();
      cubit = build();

      await cubit.requestCode('09121234567');

      expect(cubit.state.countdown, 300);
    });

    test('trusts the server cooldown when it refuses a resend', () async {
      // Guessing would let the user press a button that will be refused again.
      api.failWith(AuthFailure.cooldown, cooldownSeconds: 45);

      await cubit.requestCode('09121234567');

      expect(cubit.state.error!.failure, AuthFailure.cooldown);
      expect(cubit.state.countdown, 45);
      expect(cubit.state.canResend, isFalse);
      expect(cubit.state.error!.message, contains('۴۵'));
    });

    test('reports a network failure without pretending it was sent', () async {
      api.failWith(AuthFailure.network);

      await cubit.requestCode('09121234567');

      expect(cubit.state.status, AuthStatus.failed);
      expect(cubit.state.error!.failure, AuthFailure.network);
      expect(cubit.state.isAwaitingCode, isFalse);
    });

    test('reports an unconfigured server rather than a connection error', () async {
      api.failWith(AuthFailure.notConfigured, message: AppStrings.authServerNotConfigured);

      await cubit.requestCode('09121234567');

      expect(cubit.state.error!.failure, AuthFailure.notConfigured);
      expect(cubit.state.error!.message, AppStrings.authServerNotConfigured);
    });
  });

  group('verifyCode', () {
    setUp(() async {
      await cubit.requestCode('09121234567');
    });

    test('refuses a code that is not six digits, without a request', () async {
      await cubit.verifyCode(phoneNumber: '09121234567', code: '123');

      expect(api.verifyCodeCalls, 0);
      expect(cubit.state.error!.failure, AuthFailure.invalidCode);
    });

    test('sends the digits only, whatever the user typed', () async {
      // An Iranian keyboard emits Persian digits, which must reach the server as
      // the Latin ones the SMS contained.
      await cubit.verifyCode(phoneNumber: '09121234567', code: '۴۵۳۴۷۸');

      expect(api.lastCode, '453478');
    });

    test('signs in and stores the session', () async {
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      expect(cubit.state.isSignedIn, isTrue);
      expect(cubit.state.user!.phoneNumber, '0912 123 4567');
      expect(store.hasSession, isTrue);
    });

    test('stamps the expiry from the server lifetime', () async {
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      final stored = await store.read();
      expect(
        stored!.expiresAt!.isBefore(now.add(const Duration(days: 31))),
        isTrue,
      );
    });

    test('leaves the expiry unset when the server gives no lifetime', () async {
      // Guessing one would sign the user out early, or keep them in after the
      // server had already forgotten them.
      api = FakeAuthApiClient(
        session: const AuthSession(
          accessToken: 't',
          expiresInSeconds: 0,
          user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
        ),
      );
      await cubit.close();
      cubit = build();
      await cubit.requestCode('09121234567');

      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      expect((await store.read())!.expiresAt, isNull);
    });

    test('stays on the code step after a wrong code', () async {
      api.failWith(AuthFailure.invalidCode);

      await cubit.verifyCode(phoneNumber: '09121234567', code: '000000');

      expect(cubit.state.error!.failure, AuthFailure.invalidCode);
      expect(cubit.state.isSignedIn, isFalse);
    });

    test('stops the countdown when the code is locked out', () async {
      // The resend button must be free: a new code is the only way forward.
      api.failWith(AuthFailure.codeLocked);

      await cubit.verifyCode(phoneNumber: '09121234567', code: '000000');

      expect(cubit.state.countdown, 0);
    });

    test('stops the countdown when the code has expired', () async {
      api.failWith(AuthFailure.codeExpired);

      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      expect(cubit.state.countdown, 0);
    });

    test('keeps the countdown after a merely wrong code', () async {
      // Resending is still blocked by the server, so a local countdown that
      // stopped would invite a refusal.
      api.failWith(AuthFailure.invalidCode);

      await cubit.verifyCode(phoneNumber: '09121234567', code: '000000');

      expect(cubit.state.countdown, 120);
    });

    test('surfaces the remaining attempts', () async {
      api.failures.add(const AuthError(
        AuthFailure.invalidCode,
        message: 'x',
        attemptsRemaining: 3,
      ));

      await cubit.verifyCode(phoneNumber: '09121234567', code: '000000');

      expect(cubit.state.error!.attemptsRemaining, 3);
    });
  });

  group('guard against double submission', () {
    test('ignores a second tap while one is in flight', () async {
      // Otherwise the same code is submitted twice, which the server will read as
      // two attempts and the first of which consumes the code.
      final gate = Completer<void>();
      final slowApi = _SlowApi(gate);
      await cubit.close();
      cubit = AuthCubit(api: slowApi, tokenStore: store, clock: () => now);

      final first = cubit.verifyCode(phoneNumber: '09121234567', code: '453478');
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');
      gate.complete();
      await first;

      expect(slowApi.verifyCalls, 1);
    });

    test('ignores a resend while one is in flight', () async {
      final gate = Completer<void>();
      final slowApi = _SlowApi(gate);
      await cubit.close();
      cubit = AuthCubit(api: slowApi, tokenStore: store, clock: () => now);

      final first = cubit.requestCode('09121234567');
      await cubit.requestCode('09121234567');
      gate.complete();
      await first;

      expect(slowApi.requestCalls, 1);
    });
  });

  group('signOut', () {
    test('forgets the session and warns about backups again', () async {
      await cubit.requestCode('09121234567');
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');
      expect(cubit.state.isSignedIn, isTrue);

      await cubit.signOut();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(store.hasSession, isFalse);
      expect(cubit.state.shouldWarnAboutNoBackup, isTrue);
    });

    test('makes no request, so it works with no network', () async {
      await cubit.requestCode('09121234567');
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');
      final before = api.requestCodeCalls + api.verifyCodeCalls;

      await cubit.signOut();

      // A user on a plane must be able to sign out.
      expect(api.requestCodeCalls + api.verifyCodeCalls, before);
    });
  });

  group('setDisplayName', () {
    setUp(() async {
      await cubit.requestCode('09121234567');
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');
    });

    test('stores the name the server returned', () async {
      await cubit.setDisplayName('  سارا  ');

      expect(cubit.state.user!.displayName, 'سارا');
      expect((await store.read())!.user.displayName, 'سارا');
    });

    test('refuses an empty name without a request', () async {
      await cubit.setDisplayName('   ');

      expect(api.updateProfileCalls, 0);
      expect(cubit.state.error!.message, AppStrings.profileNameEmpty);
    });

    test('keeps the previous name when the request fails', () async {
      api.failWith(AuthFailure.network);

      await cubit.setDisplayName('سارا');

      expect(cubit.state.user!.displayName, isNull);
      expect(cubit.state.error!.failure, AuthFailure.network);
    });
  });

  group('backToPhoneNumber', () {
    test('returns to the number step and stops the countdown', () async {
      await cubit.requestCode('09121234567');
      expect(cubit.state.isAwaitingCode, isTrue);

      cubit.backToPhoneNumber();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(cubit.state.countdown, 0);
    });
  });

  group('clearError', () {
    test('drops the message so a corrected field is not still accused', () async {
      await cubit.requestCode('12345');
      expect(cubit.state.error, isNotNull);

      cubit.clearError();

      expect(cubit.state.error, isNull);
    });
  });

  group('the device that is signing in', () {
    setUp(() async {
      await cubit.requestCode('09121234567');
    });

    test('is named to the server when one can be worked out', () async {
      // The id travels into the token the server hands back, so it has to be sent
      // at sign-in rather than claimed later: a device that could name itself on a
      // later call could rename itself out of a sign-out.
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        deviceIdentity: const _NamedDevice(id: 'device-1', label: 'گوشی سارا'),
        clock: () => now,
      );
      await cubit.requestCode('09121234567');

      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      expect(api.lastDeviceId, 'device-1');
      expect(api.lastDeviceLabel, 'گوشی سارا');
    });

    test('is simply absent when the app has no identity to give', () async {
      await cubit.close();
      cubit = AuthCubit(api: api, tokenStore: store, clock: () => now);
      await cubit.requestCode('09121234567');

      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      expect(api.lastDeviceId, isNull);
      expect(cubit.state.isSignedIn, isTrue);
    });

    test('does not stop a sign-in when reading it fails', () async {
      // An identity that cannot be read costs the device its place in the list,
      // and nothing else. Refusing a sign-in over it would trade the whole feature
      // for its least important part.
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        deviceIdentity: const _BrokenDevice(),
        clock: () => now,
      );
      await cubit.requestCode('09121234567');

      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      expect(cubit.state.isSignedIn, isTrue);
      expect(api.lastDeviceId, isNull);
    });
  });

  group('ending a session', () {
    test('forgets what belonged to the account', () async {
      // The sync watermark is per account. Left behind, it would make the next
      // account's first upload skip every review older than the previous account's
      // last sync — silently, because those entries look already sent.
      var ended = 0;
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        onSessionEnded: () async => ended++,
        clock: () => now,
      );
      await cubit.requestCode('09121234567');
      await cubit.verifyCode(phoneNumber: '09121234567', code: '453478');

      await cubit.signOut();

      expect(ended, 1);
      expect(store.hasSession, isFalse);
    });

    test('is not announced when there was nothing to end', () async {
      var ended = 0;
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        onSessionEnded: () async => ended++,
        clock: () => now,
      );

      await cubit.restore();

      expect(ended, 0);
    });

    test('is announced when the stored token has expired', () async {
      store.write(StoredSession(
        accessToken: 'expired',
        user: const AuthUser(id: 'u', phoneNumber: '0912 111 2222'),
        expiresAt: now.subtract(const Duration(minutes: 1)),
      ));
      var ended = 0;
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        onSessionEnded: () async => ended++,
        clock: () => now,
      );

      await cubit.restore();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(ended, 1);
    });

    test('is announced when the server rejects the stored token', () async {
      store.write(StoredSession(
        accessToken: 'stale',
        user: const AuthUser(id: 'u', phoneNumber: '0912 111 2222'),
      ));
      api.failWith(AuthFailure.unauthorized);
      var ended = 0;
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        onSessionEnded: () async => ended++,
        clock: () => now,
      );

      await cubit.restore();

      expect(cubit.state.status, AuthStatus.signedOut);
      expect(ended, 1);
    });

    test('is not announced when a launch merely could not reach the server',
        () async {
      // The account is still there and still this device's. Only a session that has
      // actually ended should take the sync state with it.
      store.write(StoredSession(
        accessToken: 'stored',
        user: const AuthUser(id: 'u', phoneNumber: '0912 111 2222'),
      ));
      api.failWith(AuthFailure.network);
      var ended = 0;
      await cubit.close();
      cubit = AuthCubit(
        api: api,
        tokenStore: store,
        onSessionEnded: () async => ended++,
        clock: () => now,
      );

      await cubit.restore();

      expect(cubit.state.isSignedIn, isTrue);
      expect(ended, 0);
    });
  });
}

/// An identity that always answers the same thing.
class _NamedDevice implements DeviceIdentity {
  const _NamedDevice({required this.id, this.label});

  final String id;
  final String? label;

  @override
  Future<LocalDevice> resolve() async => LocalDevice(id: id, label: label);
}

/// An identity that cannot be read.
class _BrokenDevice implements DeviceIdentity {
  const _BrokenDevice();

  @override
  Future<LocalDevice> resolve() async => throw StateError('no device information');
}

/// An API whose calls wait on a gate, so a test can observe the in-flight window.
class _SlowApi extends FakeAuthApiClient {
  _SlowApi(this._gate);

  final Completer<void> _gate;
  int requestCalls = 0;
  int verifyCalls = 0;

  @override
  Future<CodeDispatch> requestCode(String phoneNumber) async {
    requestCalls++;
    await _gate.future;
    return super.requestCode(phoneNumber);
  }

  @override
  Future<AuthSession> verifyCode({
    required String phoneNumber,
    required String code,
    String? deviceId,
    String? deviceLabel,
  }) async {
    verifyCalls++;
    await _gate.future;
    return super.verifyCode(
      phoneNumber: phoneNumber,
      code: code,
      deviceId: deviceId,
      deviceLabel: deviceLabel,
    );
  }

  @override
  Future<AuthUser> me(String accessToken) async {
    await _gate.future;
    return super.me(accessToken);
  }
}
