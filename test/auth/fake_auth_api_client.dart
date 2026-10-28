import 'dart:async';

import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/auth_api_client.dart';
import 'package:recall/domain/entities/auth_device.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';

/// A client that answers from a script instead of from a network.
///
/// Every test that drives [AuthCubit] needs a server it can make fail in a
/// specific way, and a specific number of times. A real one cannot be asked to
/// refuse the fourth attempt and accept the fifth.
class FakeAuthApiClient implements AuthApiClient {
  FakeAuthApiClient({
    this.dispatch = const CodeDispatch(expiresInSeconds: 300, resendAfterSeconds: 120),
    this.session,
    this.profileName,
  });

  /// What [requestCode] returns on success.
  final CodeDispatch dispatch;

  /// What [verifyCode] returns on success.
  AuthSession? session;

  /// What [updateProfile] returns on success.
  String? profileName;

  /// Queued failures, consumed in order, one per call.
  ///
  /// A queue rather than a single flag because several tests need a failure and
  /// then a success — a wrong code followed by the right one, say.
  final List<AuthError> failures = [];

  /// How many times each method was called.
  int requestCodeCalls = 0;
  int verifyCodeCalls = 0;
  int meCalls = 0;
  int updateProfileCalls = 0;

  /// The last code submitted, for assertions.
  String? lastCode;

  /// The last number submitted, for assertions.
  String? lastPhoneNumber;

  /// The device the last sign-in named, so a test can assert it travelled.
  String? lastDeviceId;
  String? lastDeviceLabel;

  /// What [listDevices] answers with.
  List<AuthDevice> devices = const [];

  /// Device ids passed to [signOutDevice], in order.
  final List<String> signedOutDevices = [];

  /// When set, every device call throws it.
  AuthError? deviceFailure;

  @override
  bool get isConfigured => true;

  @override
  void close() {
    // Nothing to release: this fake holds no socket.
  }

  @override
  Future<List<AuthDevice>> listDevices(String accessToken) async {
    if (deviceFailure != null) throw deviceFailure!;
    return devices;
  }

  @override
  Future<void> signOutDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    signedOutDevices.add(deviceId);
    if (deviceFailure != null) throw deviceFailure!;
    devices = devices.where((device) => device.deviceId != deviceId).toList();
  }

  @override
  Future<CodeDispatch> requestCode(String phoneNumber) async {
    requestCodeCalls++;
    lastPhoneNumber = phoneNumber;
    _throwIfQueued();
    return dispatch;
  }

  @override
  Future<AuthSession> verifyCode({
    required String phoneNumber,
    required String code,
    String? deviceId,
    String? deviceLabel,
  }) async {
    verifyCodeCalls++;
    lastPhoneNumber = phoneNumber;
    lastCode = code;
    lastDeviceId = deviceId;
    lastDeviceLabel = deviceLabel;
    _throwIfQueued();
    return session ?? _defaultSession;
  }

  @override
  Future<AuthUser> me(String accessToken) async {
    meCalls++;
    _throwIfQueued();
    return session?.user ?? _defaultSession.user;
  }

  @override
  Future<AuthUser> updateProfile({
    required String accessToken,
    required String displayName,
  }) async {
    updateProfileCalls++;
    _throwIfQueued();
    final base = session?.user ?? _defaultSession.user;
    return AuthUser(
      id: base.id,
      phoneNumber: base.phoneNumber,
      displayName: displayName,
      createdAt: base.createdAt,
      lastLoginAt: base.lastLoginAt,
    );
  }

  /// Queues one failure for the next call.
  void failWith(AuthFailure failure, {int cooldownSeconds = 0, String? message}) {
    failures.add(AuthError(
      failure,
      message: message ?? AppStrings.authSomethingWentWrong,
      cooldownSeconds: cooldownSeconds,
    ));
  }

  void _throwIfQueued() {
    if (failures.isEmpty) return;
    throw failures.removeAt(0);
  }

  static AuthSession get _defaultSession => AuthSession(
        accessToken: 'token-abc',
        expiresInSeconds: 2592000,
        user: const AuthUser(
          id: 'user-1',
          phoneNumber: '0912 123 4567',
          createdAt: null,
          lastLoginAt: null,
        ),
      );
}
