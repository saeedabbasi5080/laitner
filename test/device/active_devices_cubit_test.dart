import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_device.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/device_remote.dart';
import 'package:recall/presentation/blocs/devices/active_devices_cubit.dart';

class _FakeRemote implements DeviceRemote {
  _FakeRemote({this.devices = const []});

  List<AuthDevice> devices;
  AuthError? failure;
  int listCalls = 0;
  int signOutCalls = 0;
  String? signedOut;

  @override
  Future<List<AuthDevice>> listDevices(String accessToken) async {
    listCalls++;
    if (failure != null) throw failure!;
    return devices;
  }

  @override
  Future<void> signOutDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    signOutCalls++;
    signedOut = deviceId;
    if (failure != null) throw failure!;
    devices = devices.where((device) => device.deviceId != deviceId).toList();
  }
}

void main() {
  late _FakeRemote remote;
  late InMemoryAuthTokenStore tokens;

  final now = DateTime.utc(2026, 1, 1, 12);

  AuthDevice device(String id, {required DateTime? seen, bool current = false}) {
    return AuthDevice(deviceId: id, lastSeenAt: seen, current: current, label: id);
  }

  ActiveDevicesCubit cubitWith({required bool signedIn}) {
    tokens = InMemoryAuthTokenStore(
      signedIn
          ? const StoredSession(
              accessToken: 'token',
              user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
            )
          : null,
    );
    return ActiveDevicesCubit(remote: remote, tokenStore: tokens);
  }

  setUp(() {
    remote = _FakeRemote();
  });

  group('until something is asked', () {
    test('is unknown, so nothing claims a list it has not read', () {
      expect(cubitWith(signedIn: true).state.status, ActiveDevicesStatus.unknown);
      expect(cubitWith(signedIn: true).state.hasLoaded, isFalse);
    });
  });

  group('load', () {
    test('reports the devices the server named', () async {
      remote = _FakeRemote(devices: [
        device('mine', seen: now, current: true),
        device('other', seen: now.subtract(const Duration(days: 2))),
      ]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.devices.map((d) => d.deviceId), ['mine', 'other']);
      expect(cubit.state.currentDevice?.deviceId, 'mine');
    });

    test('reports an empty list when there is no account', () async {
      // Signing in is optional, so having nothing to list is not a failure.
      final cubit = cubitWith(signedIn: false);

      await cubit.load();

      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.devices, isEmpty);
      expect(remote.listCalls, 0);
    });

    test('reports a refusal rather than throwing', () async {
      // This runs when settings is opened. A settings screen that crashed on a
      // dropped connection would be worse than one that says it could not load.
      remote = _FakeRemote()
        ..failure = const AuthError(AuthFailure.network, message: 'سرور در دسترس نیست.');
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.error, 'سرور در دسترس نیست.');
    });

    test('clears a previous error on the next attempt', () async {
      remote = _FakeRemote()..failure = const AuthError(AuthFailure.network, message: 'x');
      final cubit = cubitWith(signedIn: true);
      await cubit.load();

      remote.failure = null;
      remote.devices = [device('mine', seen: now, current: true)];
      await cubit.load();

      expect(cubit.state.error, isNull);
      expect(cubit.state.hasLoaded, isTrue);
    });
  });

  group('signing a device out', () {
    test('asks the server, then re-reads the list', () async {
      // Re-read rather than removing the row locally: the server decides, and a
      // list that disagreed with it would show a device as gone that can still
      // sync.
      remote = _FakeRemote(devices: [
        device('mine', seen: now, current: true),
        device('old', seen: now.subtract(const Duration(days: 3))),
      ]);
      final cubit = cubitWith(signedIn: true);
      await cubit.load();
      final listsBefore = remote.listCalls;

      await cubit.signOut('old');

      expect(remote.signOutCalls, 1);
      expect(remote.signedOut, 'old');
      expect(remote.listCalls, listsBefore + 1);
      expect(cubit.state.devices.map((d) => d.deviceId), ['mine']);
    });

    test('reports a refusal', () async {
      remote = _FakeRemote(devices: [device('mine', seen: now, current: true)]);
      final cubit = cubitWith(signedIn: true);
      await cubit.load();

      remote.failure = const AuthError(AuthFailure.network, message: 'قطع شد');
      await cubit.signOut('old');

      expect(cubit.state.hasFailed, isTrue);
      expect(cubit.state.error, 'قطع شد');
      expect(cubit.state.busy, isFalse);
    });

    test('does nothing without an account', () async {
      final cubit = cubitWith(signedIn: false);

      await cubit.signOut('old');

      expect(remote.signOutCalls, 0);
    });
  });

  group('the warning condition', () {
    test('is true when another device was used after this one', () async {
      remote = _FakeRemote(devices: [
        device('mine', seen: now.subtract(const Duration(hours: 5)), current: true),
        device('other', seen: now),
      ]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.anotherDeviceIsNewer, isTrue);
    });

    test('is false when this device is the newest', () async {
      remote = _FakeRemote(devices: [
        device('mine', seen: now, current: true),
        device('other', seen: now.subtract(const Duration(hours: 5))),
      ]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.anotherDeviceIsNewer, isFalse);
    });

    test('is false when this device has never been seen', () async {
      // A comparison that cannot be made cannot justify a warning, and a warning
      // that cannot be justified is one the user learns to dismiss.
      remote = _FakeRemote(devices: [
        device('mine', seen: null, current: true),
        device('other', seen: now),
      ]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.anotherDeviceIsNewer, isFalse);
    });

    test('is false when this is the only device', () async {
      remote = _FakeRemote(devices: [device('mine', seen: now, current: true)]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.anotherDeviceIsNewer, isFalse);
      expect(cubit.state.hasOtherDevices, isFalse);
    });

    test('is false when the server named no current device', () async {
      // Nothing to compare against, so nothing to warn about.
      remote = _FakeRemote(devices: [device('other', seen: now)]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.currentDevice, isNull);
      expect(cubit.state.anotherDeviceIsNewer, isFalse);
    });

    test('does not count an unreadable timestamp as newer', () async {
      remote = _FakeRemote(devices: [
        device('mine', seen: now, current: true),
        device('other', seen: null),
      ]);
      final cubit = cubitWith(signedIn: true);

      await cubit.load();

      expect(cubit.state.anotherDeviceIsNewer, isFalse);
    });
  });
}
