import 'package:http/http.dart' as http;
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/api_transport.dart';
import 'package:recall/domain/entities/auth_device.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/device_remote.dart';

/// The outcome of asking for a code: how long it lives, and when a resend is
/// allowed.
class CodeDispatch {
  const CodeDispatch({required this.expiresInSeconds, required this.resendAfterSeconds});

  final int expiresInSeconds;
  final int resendAfterSeconds;

  /// How long the countdown starts at.
  ///
  /// Falls back to the code's own lifetime when the server sent no resend delay,
  /// so the button always becomes available eventually rather than never.
  int get effectiveCooldown => resendAfterSeconds > 0 ? resendAfterSeconds : expiresInSeconds;
}

/// A verified session: the token to present, and who it belongs to.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresInSeconds,
    required this.user,
  });

  final String accessToken;
  final int expiresInSeconds;
  final AuthUser user;
}

/// Talks to the sign-in service.
///
/// Every method returns a [Future] that completes with a value or throws an
/// [AuthError] — never with a raw `SocketException` or a `FormatException`. The
/// screen above should not have to know what an HTTP status code is, and it
/// certainly should not have to know that `dart:io` is involved.
class AuthApiClient implements DeviceRemote {
  AuthApiClient({http.Client? client, String? baseUrl, ApiTransport? transport})
      : _transport = transport ?? ApiTransport(client: client, baseUrl: baseUrl);

  final ApiTransport _transport;

  /// Whether this client knows where to send requests.
  bool get isConfigured => _transport.isConfigured;

  /// Closes the underlying connection.
  ///
  /// Called on sign-out so a long-lived app does not keep a socket open to a
  /// service it is not using.
  void close() => _transport.close();

  /// Asks the server to text a code.
  Future<CodeDispatch> requestCode(String phoneNumber) async {
    final body = await _send(
      'POST',
      '/auth/otp/request',
      payload: {'phoneNumber': phoneNumber},
      fallbackMessage: AppStrings.authRequestFailed,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );

    return CodeDispatch(
      expiresInSeconds: _intOf(body['expiresInSeconds']) ?? 300,
      resendAfterSeconds: _intOf(body['resendAfterSeconds']) ?? 0,
    );
  }

  /// Exchanges a code for a session.
  ///
  /// [phoneNumber] is sent as typed, not canonicalised. The server normalises
  /// and is the only place that knows the rules; doing it twice risks the two
  /// copies disagreeing, and a disagreement here would look to the user like a
  /// correct code being rejected.
  ///
  /// [deviceId] names this install so the server can list it against the account
  /// and let somebody sign it out from elsewhere. It travels into the token the
  /// server hands back, which is why it cannot be sent on later calls instead —
  /// a device that could name itself later could rename itself out of a sign-out.
  Future<AuthSession> verifyCode({
    required String phoneNumber,
    required String code,
    String? deviceId,
    String? deviceLabel,
  }) async {
    final body = await _send(
      'POST',
      '/auth/otp/verify',
      payload: {
        'phoneNumber': phoneNumber,
        'code': code,
        // Null-aware entries: the server treats a missing field as "unknown
        // device", which is what an install from before this feature sends.
        'deviceId': ?deviceId,
        'deviceLabel': ?deviceLabel,
      },
      fallbackMessage: AppStrings.authVerifyFailed,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );

    final token = body['accessToken'];
    final user = body['user'];

    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      // A 200 with no token is not a success this app can use. Treating it as
      // one would leave the user apparently signed in with no way to prove it.
      throw AuthError(
        AuthFailure.unexpected,
        message: AppStrings.authUnexpectedResponse,
      );
    }

    return AuthSession(
      accessToken: token,
      expiresInSeconds: _intOf(body['expiresInSeconds']) ?? 0,
      user: AuthUser.fromJson(user),
    );
  }

  /// Reads the signed-in user back, to prove the token still works.
  ///
  /// Used only when the app starts and finds a stored token. A failure here is
  /// treated by the caller as "signed out", which is the safe reading: a token
  /// the server rejects is worth no more than one it has not heard of.
  Future<AuthUser> me(String accessToken) async {
    final body = await _send(
      'GET',
      '/auth/me',
      accessToken: accessToken,
      fallbackMessage: AppStrings.authUnexpectedResponse,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );

    return AuthUser.fromJson(body);
  }

  /// Sets a display name.
  Future<AuthUser> updateProfile({
    required String accessToken,
    required String displayName,
  }) async {
    final body = await _send(
      'PUT',
      '/auth/profile',
      payload: {'displayName': displayName},
      accessToken: accessToken,
      fallbackMessage: AppStrings.authProfileFailed,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );

    return AuthUser.fromJson(body);
  }

  /// Every device on the account, most recently used first.
  ///
  /// A missing or unreadable list reads as empty rather than failing. The screen
  /// this feeds is informational, and an empty list is a truthful thing to show
  /// when the server said something this build cannot parse.
  @override
  Future<List<AuthDevice>> listDevices(String accessToken) async {
    final body = await _send(
      'GET',
      '/devices',
      accessToken: accessToken,
      fallbackMessage: AppStrings.devicesLoadFailed,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );

    final raw = body['devices'];
    if (raw is! List) return const [];

    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>) AuthDevice.fromJson(entry),
    ];
  }

  /// Signs a device out, so its next call is refused.
  ///
  /// The device is not told. It finds out on its own next call, which is the only
  /// way this can work: the device most likely to need removing is one the user is
  /// not holding.
  @override
  Future<void> signOutDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    await _send(
      'DELETE',
      '/devices/$deviceId',
      accessToken: accessToken,
      fallbackMessage: AppStrings.deviceSignOutFailed,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );
  }

  /// One request, through the shared transport.
  ///
  /// Still a method rather than calling the transport directly, so the payload on
  /// this surface stays a map: every sign-in call sends an object, and the sync
  /// calls that need to send an array do not belong here.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? payload,
    String? accessToken,
    required String fallbackMessage,
    required String notConfiguredMessage,
  }) {
    return _transport.send(
      method,
      path,
      payload: payload,
      accessToken: accessToken,
      fallbackMessage: fallbackMessage,
      notConfiguredMessage: notConfiguredMessage,
    );
  }

  static int? _intOf(Object? value) => value is num ? value.toInt() : null;
}
