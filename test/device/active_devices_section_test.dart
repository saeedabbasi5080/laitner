import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_device.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/device_remote.dart';
import 'package:recall/presentation/blocs/devices/active_devices_cubit.dart';
import 'package:recall/presentation/widgets/active_devices_section.dart';

class _FakeRemote implements DeviceRemote {
  _FakeRemote({this.devices = const []});

  List<AuthDevice> devices;
  AuthError? failure;
  final List<String> signedOut = [];

  @override
  Future<List<AuthDevice>> listDevices(String accessToken) async {
    if (failure != null) throw failure!;
    return devices;
  }

  @override
  Future<void> signOutDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    signedOut.add(deviceId);
    devices = devices.where((device) => device.deviceId != deviceId).toList();
  }
}

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  AuthDevice device(String id, {required DateTime? seen, bool current = false, String? label}) {
    return AuthDevice(deviceId: id, lastSeenAt: seen, current: current, label: label);
  }

  ActiveDevicesCubit cubitFor(_FakeRemote remote) {
    return ActiveDevicesCubit(
      remote: remote,
      tokenStore: InMemoryAuthTokenStore(
        const StoredSession(
          accessToken: 'token',
          user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
        ),
      ),
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(AppAccent.lavender),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  /// Renders and lets the load finish.
  ///
  /// Explicit pumps rather than `pumpAndSettle`: the loading state holds a
  /// progress indicator, which never stops animating, so settling would time out.
  Future<void> render(WidgetTester tester, _FakeRemote remote) async {
    await tester.pumpWidget(wrap(ActiveDevicesSection(cubit: cubitFor(remote))));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('lists the devices and marks this one', (tester) async {
    final remote = _FakeRemote(devices: [
      device('mine', seen: now, current: true, label: 'گوشی سارا'),
      device('old', seen: now.subtract(const Duration(days: 4)), label: 'تبلت'),
    ]);

    await render(tester, remote);

    expect(find.text('گوشی سارا'), findsOneWidget);
    expect(find.text('تبلت'), findsOneWidget);
    expect(find.text(AppStrings.thisDevice), findsOneWidget);
  });

  testWidgets('falls back to part of the id when a device has no name',
      (tester) async {
    // Two unlabelled devices would otherwise be two identical rows, and there
    // would be no way to choose between them.
    final remote = _FakeRemote(devices: [
      device('mine', seen: now, current: true),
      device('0123456789abcdef', seen: now),
    ]);

    await render(tester, remote);

    expect(find.text('01234567'), findsOneWidget);
  });

  testWidgets('warns when another device has been used since this one',
      (tester) async {
    final remote = _FakeRemote(devices: [
      device('mine', seen: now.subtract(const Duration(hours: 3)), current: true),
      device('other', seen: now),
    ]);

    await render(tester, remote);

    expect(find.text(AppStrings.otherDeviceInUse), findsOneWidget);
  });

  testWidgets('says nothing when this device is the newest', (tester) async {
    final remote = _FakeRemote(devices: [
      device('mine', seen: now, current: true),
      device('other', seen: now.subtract(const Duration(days: 2))),
    ]);

    await render(tester, remote);

    expect(find.text(AppStrings.otherDeviceInUse), findsNothing);
  });

  testWidgets('offers no way to sign this device out from itself',
      (tester) async {
    final remote = _FakeRemote(devices: [device('mine', seen: now, current: true)]);

    await render(tester, remote);

    expect(find.byIcon(Icons.link_off), findsNothing);
  });

  testWidgets('asks before signing another device out', (tester) async {
    final remote = _FakeRemote(devices: [
      device('mine', seen: now, current: true),
      device('old', seen: now, label: 'تبلت'),
    ]);

    await render(tester, remote);
    await tester.tap(find.byIcon(Icons.link_off));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.signOutDeviceConfirm), findsOneWidget);
    expect(remote.signedOut, isEmpty);
  });

  testWidgets('signs the device out when confirmed', (tester) async {
    final remote = _FakeRemote(devices: [
      device('mine', seen: now, current: true),
      device('old', seen: now, label: 'تبلت'),
    ]);

    await render(tester, remote);
    await tester.tap(find.byIcon(Icons.link_off));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.yes));
    await tester.pumpAndSettle();

    expect(remote.signedOut, ['old']);
    expect(find.text('تبلت'), findsNothing);
  });

  testWidgets('reports a failure and offers to try again', (tester) async {
    final remote = _FakeRemote()
      ..failure = const AuthError(AuthFailure.network, message: 'سرور در دسترس نیست.');

    await render(tester, remote);

    expect(find.text('سرور در دسترس نیست.'), findsOneWidget);
    expect(find.text(AppStrings.confirm), findsOneWidget);
  });

  group('how long ago a device was used', () {
    test('reads as never when there is no timestamp', () {
      expect(lastUsedLabel(null), AppStrings.deviceNeverSeen);
    });

    test('reads as just now under a minute', () {
      final justNow = DateTime.now().toUtc().subtract(const Duration(seconds: 20));

      expect(lastUsedLabel(justNow), AppStrings.deviceLastUsedJustNow);
    });

    test('counts minutes, then hours, then days', () {
      final base = DateTime.now().toUtc();

      expect(
        lastUsedLabel(base.subtract(const Duration(minutes: 5))),
        AppStrings.deviceLastUsedMinutes(5),
      );
      expect(
        lastUsedLabel(base.subtract(const Duration(hours: 3))),
        AppStrings.deviceLastUsedHours(3),
      );
      expect(
        lastUsedLabel(base.subtract(const Duration(days: 2))),
        AppStrings.deviceLastUsedDays(2),
      );
    });

    test('does not report a future timestamp as ancient', () {
      // A device whose clock is behind would otherwise read as days in the past
      // or an overflowed duration. "Just now" is the honest answer.
      final future = DateTime.now().toUtc().add(const Duration(hours: 1));

      expect(lastUsedLabel(future), AppStrings.deviceLastUsedJustNow);
    });
  });
}
