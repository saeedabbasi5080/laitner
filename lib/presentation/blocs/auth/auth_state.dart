part of 'auth_cubit.dart';

/// Where sign-in has got to.
enum AuthStatus {
  /// Start-up has not finished looking for a stored session.
  ///
  /// Its own state so the settings tile can show nothing rather than "sign in"
  /// during the window where the user might in fact be signed in.
  unknown,

  /// No session. The number step is what should be shown.
  signedOut,

  /// A code is on its way, or has arrived.
  codeSent,

  /// A request is in flight.
  requesting,

  /// A code is being checked.
  verifying,

  /// There is a session.
  signedIn,

  /// The last attempt failed, and [AuthState.error] says why.
  failed,
}

/// The state of sign-in.
///
/// Immutable and comparable, so the interface rebuilds only when something
/// actually changed. [AuthUser] is compared by value rather than by identity,
/// which is why it overrides `==` — otherwise every `copyWith` would look like a
/// change and the settings tile would flicker on each rebuild.
class AuthState extends Equatable {
  const AuthState._({
    required this.status,
    this.phoneNumber,
    this.user,
    this.verified = false,
    this.error,
    this.countdown = 0,
    this.expiresInSeconds = 0,
  });

  /// Before anything has been looked up.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.signedOut()
      : this._(status: AuthStatus.signedOut);

  const AuthState.requesting(String phoneNumber)
      : this._(status: AuthStatus.requesting, phoneNumber: phoneNumber);

  /// A code being checked.
  ///
  /// [countdown] is carried through rather than reset, because the resend
  /// cooldown belongs to the number and does not stop while a code is being
  /// submitted.
  const AuthState.verifying(String phoneNumber, {int countdown = 0})
      : this._(
          status: AuthStatus.verifying,
          phoneNumber: phoneNumber,
          countdown: countdown,
        );

  const AuthState.codeSent({
    required String phoneNumber,
    required int cooldownSeconds,
    required int expiresInSeconds,
  }) : this._(
          status: AuthStatus.codeSent,
          phoneNumber: phoneNumber,
          countdown: cooldownSeconds,
          expiresInSeconds: expiresInSeconds,
        );

  const AuthState.signedIn(AuthUser user, {required bool verified})
      : this._(status: AuthStatus.signedIn, user: user, verified: verified);

  /// A failure.
  ///
  /// [user] and [verified] are carried over from whatever was there before. A
  /// failure while signed in — a name that would not save, say — must not drop
  /// the account tile back to "sign in": the user is still signed in, one thing
  /// went wrong, and losing the account on screen would be a bigger lie than the
  /// error being shown.
  const AuthState.failed({
    AuthError? error,
    String? phoneNumber,
    int countdown = 0,
    AuthUser? user,
    bool verified = false,
  }) : this._(
          status: AuthStatus.failed,
          error: error,
          phoneNumber: phoneNumber,
          countdown: countdown,
          user: user,
          verified: verified,
        );

  /// A failure that keeps the account it happened on.
  ///
  /// The usual form of [failed] for anything that happens after sign-in, so a
  /// caller does not have to remember to copy three fields across by hand.
  const AuthState.failedWhileSignedIn(
    AuthError error, {
    required AuthUser user,
    required bool verified,
  }) : this._(
          status: AuthStatus.failed,
          error: error,
          user: user,
          verified: verified,
        );

  final AuthStatus status;

  /// The number being signed in with, kept so the code step and the number step
  /// agree about it and a failure does not lose it.
  final String? phoneNumber;

  final AuthUser? user;

  /// Whether the server has confirmed the session on this launch.
  ///
  /// False after a restore that could not reach the server. The account is still
  /// there — the app works offline — but the difference is worth having, because
  /// it is the difference between "signed in" and "signed in, as far as we know".
  final bool verified;

  final AuthError? error;

  /// Seconds until a resend is allowed.
  final int countdown;

  /// How long the code itself lives.
  final int expiresInSeconds;

  /// Whether anyone is signed in.
  ///
  /// True for [AuthStatus.failed] as well, because a user whose display name
  /// would not save has not been signed out. Keyed on [user] rather than on the
  /// status so no state can hold an account and claim nobody is signed in.
  bool get isSignedIn =>
      user != null &&
      (status == AuthStatus.signedIn || status == AuthStatus.failed);

  /// Whether the code step is what should be shown.
  bool get isAwaitingCode => status == AuthStatus.codeSent;

  /// Whether a request is in flight, so the interface can disable its buttons.
  bool get isBusy =>
      status == AuthStatus.requesting || status == AuthStatus.verifying;

  /// Whether the resend button should work right now.
  bool get canResend => status == AuthStatus.codeSent && countdown == 0;

  /// Whether the warning should be shown on the settings screen.
  ///
  /// Requires [AuthStatus.signedOut] specifically, not merely "not signed in":
  /// during [AuthStatus.unknown] the user may well be signed in, and warning
  /// someone who is signed in that they cannot recover their cards would be
  /// simply wrong.
  bool get shouldWarnAboutNoBackup => status == AuthStatus.signedOut;

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    AuthUser? user,
    bool? verified,
    AuthError? error,
    int? countdown,
    int? expiresInSeconds,
  }) {
    return AuthState._(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
      verified: verified ?? this.verified,
      error: error ?? this.error,
      countdown: countdown ?? this.countdown,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        phoneNumber,
        user,
        verified,
        error,
        countdown,
        expiresInSeconds,
      ];

  @override
  String toString() =>
      'AuthState(${status.name}, phone: $phoneNumber, user: $user, '
      'error: ${error?.failure.name}, countdown: $countdown)';
}
