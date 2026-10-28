import 'package:equatable/equatable.dart';

/// Why a sign-in request failed.
///
/// A sealed set rather than a message, because the interface has to react
/// differently to each of these: a wrong code deserves a red box on the code
/// field, a dead network deserves a "check your connection" and a disabled
/// button, and a rate limit deserves a countdown.
enum AuthFailure {
  /// The server could not be reached at all.
  network,

  /// The number is not an Iranian mobile number.
  invalidPhone,

  /// The code was wrong, or already used.
  invalidCode,

  /// The code is older than the server allows.
  codeExpired,

  /// Too many wrong attempts; the code is dead.
  codeLocked,

  /// Resend requested too soon.
  cooldown,

  /// The SMS gateway refused.
  smsFailed,

  /// The account is suspended.
  userInactive,

  /// The token was missing, expired, or rejected.
  ///
  /// Its own case because it means something different from the others: not "you
  /// may not do that" but "you are not who you were". The app treats it as signed
  /// out rather than showing an error, since the user's remedy is to sign in
  /// again, not to try harder.
  unauthorized,

  /// This device was signed out from somewhere else.
  ///
  /// The server refuses a sync from a device it no longer lists. Distinct from
  /// [unauthorized] because the app has to do something specific with it: forget
  /// the token and explain, rather than leaving the user on a signed-in screen
  /// whose every action fails.
  deviceSignedOut,

  /// Too many requests from this address.
  rateLimited,

  /// The server answered, but not in a shape this app understands.
  ///
  /// Its own case, because it is a bug rather than a condition the user can fix,
  /// and lumping it in with "network" would send the user looking at their Wi-Fi
  /// when the problem is here.
  unexpected,

  /// The server is not configured, so there is nowhere to sign in.
  notConfigured,
}

/// A failed sign-in call, with whatever the server said about it.
class AuthError extends Equatable {
  const AuthError(
    this.failure, {
    required this.message,
    this.code,
    this.cooldownSeconds = 0,
    this.attemptsRemaining,
  });

  /// Builds from what the server sent, falling back to a generic Persian message.
  ///
  /// The `error` field is already Persian and ready to show, so it is preferred
  /// over anything composed here — the server knows more about why it refused.
  factory AuthError.fromServer(
    int statusCode,
    Map<String, dynamic> body, {
    required String fallbackMessage,
  }) {
    final code = body['code'] as String?;
    final serverMessage = body['error'];

    // `cooldown` rides along with the refusal so the countdown can start from the
    // server's own number rather than from a guess made on the client.
    final rawCooldown = body['cooldown'] ?? body['retryAfterSeconds'];
    final cooldown = rawCooldown is num ? rawCooldown.toInt() : 0;

    final rawAttempts = body['attemptsRemaining'];
    final attempts = rawAttempts is num ? rawAttempts.toInt() : null;

    final failure = switch (code) {
      'invalid_phone' => AuthFailure.invalidPhone,
      'invalid_otp' => AuthFailure.invalidCode,
      'otp_expired' => AuthFailure.codeExpired,
      'otp_locked' => AuthFailure.codeLocked,
      'otp_cooldown' => AuthFailure.cooldown,
      'sms_failed' => AuthFailure.smsFailed,
      'user_inactive' => AuthFailure.userInactive,
      'unauthorized' => AuthFailure.unauthorized,
      'device_signed_out' => AuthFailure.deviceSignedOut,
      'rate_limited' => AuthFailure.rateLimited,
      // An unmapped `code` is a server that knows something this build does not.
      // Showing the refusal is still better than pretending it did not happen.
      _ when statusCode == 400 => AuthFailure.invalidCode,
      _ when statusCode == 401 => AuthFailure.invalidCode,
      _ when statusCode == 403 => AuthFailure.userInactive,
      _ when statusCode == 429 => AuthFailure.rateLimited,
      _ when statusCode >= 500 => AuthFailure.network,
      _ => AuthFailure.unexpected,
    };

    return AuthError(
      failure,
      message: serverMessage is String && serverMessage.isNotEmpty
          ? serverMessage
          : fallbackMessage,
      code: code,
      cooldownSeconds: cooldown,
      attemptsRemaining: attempts,
    );
  }

  final AuthFailure failure;

  /// Ready to show, in Persian.
  final String message;

  /// The server's stable machine-readable code, if it sent one.
  final String? code;

  /// Seconds until a resend is allowed. Zero unless the server said otherwise.
  final int cooldownSeconds;

  /// Wrong tries left before the code dies, if the server counted.
  final int? attemptsRemaining;

  /// Whether trying the same thing again could plausibly work.
  ///
  /// Drives whether the resend button stays enabled, so the user is not invited
  /// to hammer an endpoint that will refuse.
  bool get canRetryImmediately =>
      failure != AuthFailure.invalidCode &&
      failure != AuthFailure.codeLocked &&
      failure != AuthFailure.codeExpired &&
      // Signing in again is what fixes it, not trying the same call harder.
      failure != AuthFailure.deviceSignedOut;

  @override
  List<Object?> get props =>
      [failure, message, code, cooldownSeconds, attemptsRemaining];
}
