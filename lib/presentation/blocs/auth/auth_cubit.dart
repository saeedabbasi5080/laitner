import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/auth_api_client.dart';
import 'package:recall/data/datasources/device_identity.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/entities/phone_numbers.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';

part 'auth_state.dart';

/// Sign-in, as a state machine.
///
/// Six states, because the distinctions between them are the ones the interface
/// has to act on: unknown means "do not show the account tile yet", signed out
/// means "offer to sign in", code sent means "offer to type a code and count
/// down", and the rest are in-flight or failed.
///
/// Every failure lands in [AuthState.failed] with an [AuthError] rather than
/// being re-thrown. A sign-in that fails is an ordinary outcome, not an
/// exception, and the screen must survive it without a try/catch.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this.api,
    required this.tokenStore,
    this.deviceIdentity,
    this.onSessionEnded,
    DateTime Function()? clock,
  })  : _now = clock ?? DateTime.now,
        super(const AuthState.unknown());

  final AuthApiClient api;
  final AuthTokenStore tokenStore;

  /// Called when this device stops having a usable session.
  ///
  /// The sync watermark belongs to an **account**, not to a device, so it has to go
  /// when the account does. Keeping it across a sign-out would make the next
  /// account's first upload skip every review older than the previous account's
  /// last sync — silently, because the skipped entries look like ones the server
  /// already has.
  ///
  /// A callback rather than a second store this class knows about: sign-in should
  /// not have to know that synchronisation exists. What is wired to it is decided
  /// where the graph is assembled.
  final Future<void> Function()? onSessionEnded;

  /// Names this install to the server, so it can be listed and signed out from
  /// elsewhere.
  ///
  /// Optional, because sign-in works without it: an install that cannot say what
  /// it is still gets an account, it just will not appear in the device list. Not
  /// worth refusing a sign-in over.
  final DeviceIdentity? deviceIdentity;

  /// The clock, injectable so a cooldown can be tested without waiting for it.
  final DateTime Function() _now;

  Timer? _countdownTimer;

  /// The current bearer token, or null when signed out.
  ///
  /// Held here rather than in [AuthState] on purpose. A state is printed in
  /// errors, compared by `==`, and kept for as long as the app lives — none of
  /// which a credential should be subject to. The interface asks [AuthState]
  /// whether someone is signed in; only a request asks for the token, and only
  /// through this field.
  String? _token;

  /// Whether anything is in flight.
  ///
  /// Read before every network call so a second tap cannot start a second
  /// request — which on the request endpoint would be a rate-limit refusal, and
  /// on the verify endpoint would be the same code submitted twice.
  bool get _busy => state.status == AuthStatus.requesting ||
      state.status == AuthStatus.verifying;

  /// Whether a countdown belongs on the screen as things stand.
  ///
  /// True through the in-flight states as well as the two that show it outright,
  /// because a code being checked is still a code with a resend cooldown behind
  /// it, and a timer that paused there would show a stale number once the
  /// attempt finished.
  bool get _showsCountdown =>
      state.status == AuthStatus.codeSent ||
      state.status == AuthStatus.failed ||
      state.status == AuthStatus.verifying;

  /// Reads any stored session at start-up.
  ///
  /// Never throws and never blocks the app. A stored token that has expired, or
  /// that the server has since forgotten, reads as signed out — the user is
  /// asked for a code rather than shown a broken account tile.
  Future<void> restore() async {
    try {
      final stored = await tokenStore.read();
      if (stored == null || stored.accessToken.isEmpty) {
        _token = null;
        emit(const AuthState.signedOut());
        return;
      }

      // Judged against this cubit's clock rather than [StoredSession.isExpired],
      // which reads the wall clock. Same comparison, but the clock is the one
      // the rest of this class uses — the one that stamped the expiry in the
      // first place, and the one a test controls.
      final expiry = stored.expiresAt;
      if (expiry != null && _now().isAfter(expiry)) {
        await _endSession();
        emit(const AuthState.signedOut());
        return;
      }

      _token = stored.accessToken;

      // Shown immediately from what is stored, then confirmed against the
      // server. Waiting for the confirmation would leave the settings tile
      // empty on every launch, and a network that is down should not cost the
      // user the fact that they are signed in.
      emit(AuthState.signedIn(stored.user, verified: false));

      try {
        final fresh = await api.me(stored.accessToken);
        emit(AuthState.signedIn(fresh, verified: true));
      } on AuthError catch (error) {
        if (error.failure == AuthFailure.unauthorized) {
          await _endSession();
          emit(const AuthState.signedOut());
          return;
        }
        // Network down, service down, unexpected body: the stored session is
        // still the best account information there is. Signed in, unverified,
        // and no complaint — the app works offline by design.
      }
    } catch (error) {
      // A keystore that will not open, a corrupt blob. Signed out is the only
      // honest reading.
      _token = null;
      emit(const AuthState.signedOut());
    }
  }

  /// Asks the server to text a code to [phoneNumber].
  ///
  /// Refuses without a request when the number cannot be valid, so the user is
  /// not made to wait for a round trip to be told what could have been checked
  /// before they typed.
  Future<void> requestCode(String phoneNumber) async {
    if (_busy) return;

    if (!PhoneNumbers.isValid(phoneNumber)) {
      emit(AuthState.failed(
        error: const AuthError(AuthFailure.invalidPhone, message: AppStrings.phoneNumberInvalid),
        phoneNumber: phoneNumber,
      ));
      return;
    }

    emit(AuthState.requesting(phoneNumber));

    try {
      final dispatch = await api.requestCode(PhoneNumbers.toDisplay(phoneNumber));
      _startCountdown(dispatch.effectiveCooldown);
      emit(AuthState.codeSent(
        phoneNumber: phoneNumber,
        cooldownSeconds: dispatch.effectiveCooldown,
        expiresInSeconds: dispatch.expiresInSeconds,
      ));
    } on AuthError catch (error) {
      // A cooldown refusal carries the server's own remaining seconds. Trusting
      // them keeps the countdown in step with the server instead of guessing and
      // letting the user press a button that will be refused.
      if (error.cooldownSeconds > 0) {
        _startCountdown(error.cooldownSeconds);
        emit(AuthState.failed(
          error: AuthError(
            error.failure,
            message: AppStrings.codeRequestFailed(error.cooldownSeconds),
            code: error.code,
            cooldownSeconds: error.cooldownSeconds,
          ),
          phoneNumber: phoneNumber,
          countdown: error.cooldownSeconds,
        ));
        return;
      }
      emit(AuthState.failed(error: error, phoneNumber: phoneNumber));
    }
  }

  /// Submits a code.
  Future<void> verifyCode({required String phoneNumber, required String code}) async {
    if (_busy) return;

    final digits = PhoneNumbers.digitsOnly(code);
    if (digits.length != 6) {
      emit(AuthState.failed(
        error: const AuthError(AuthFailure.invalidCode, message: AppStrings.verificationCodeIncomplete),
        phoneNumber: phoneNumber,
      ));
      return;
    }

    // The running countdown is carried through the in-flight state rather than
    // dropped: a wrong code does not lift the server's resend cooldown, so a
    // countdown that reset to zero here would light up a button about to be
    // refused.
    emit(AuthState.verifying(phoneNumber, countdown: state.countdown));

    try {
      final device = await _resolveDevice();
      final session = await api.verifyCode(
        phoneNumber: PhoneNumbers.toDisplay(phoneNumber),
        code: digits,
        deviceId: device?.id,
        deviceLabel: device?.label,
      );

      final now = _now();
      _token = session.accessToken;
      await tokenStore.write(StoredSession(
        accessToken: session.accessToken,
        user: session.user,
        // Only stamped when the server said how long it lasts. Guessing a
        // lifetime would sign the user out early or keep them in after the
        // server had already forgotten them.
        expiresAt: session.expiresInSeconds > 0
            ? now.add(Duration(seconds: session.expiresInSeconds))
            : null,
      ));

      _countdownTimer?.cancel();
      emit(AuthState.signedIn(session.user, verified: true));
    } on AuthError catch (error) {
      // A code that died takes the countdown with it: the resend button should be
      // available immediately, because the code it would resend is the only way
      // forward. The number is unchanged, so the server's cooldown still applies
      // to a resend — but there is no point counting down to a button that would
      // be refused, so it starts free and the refusal, if there is one, arrives
      // with its own remaining seconds.
      final deadCode = error.failure == AuthFailure.codeLocked ||
          error.failure == AuthFailure.codeExpired;
      if (deadCode) {
        _stopCountdown();
      }

      emit(deadCode
          ? AuthState.failed(error: error, phoneNumber: phoneNumber)
          : _failedWithCountdown(error, phoneNumber));
    }
  }

  /// A failure on the code step that keeps the running countdown.
  ///
  /// Needed because [AuthState.failed] starts its countdown at zero, and a merely
  /// wrong code does not lift the server's resend cooldown — a countdown that
  /// reset to zero here would light up a button the server is about to refuse.
  AuthState _failedWithCountdown(AuthError error, String phoneNumber) {
    final running = state.countdown > 0 ? state.countdown : 0;
    return AuthState.failed(
      error: error,
      phoneNumber: phoneNumber,
      countdown: running,
    );
  }

  /// Ticks the countdown down.
  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    if (seconds <= 0) return;

    var remaining = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        // Only clear it where a countdown is meaningful. Emitting into a state
        // that has just moved on — a successful sign-in, say — would put a
        // cooldown on a screen that no longer has one.
        if (_showsCountdown) {
          emit(state.copyWith(countdown: 0));
        }
        return;
      }
      if (_showsCountdown) {
        emit(state.copyWith(countdown: remaining));
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// Clears the last error, so a dismissed message does not come back.
  void clearError() {
    if (state.status == AuthStatus.failed) {
      emit(AuthState.failed());
    }
  }

  /// Goes back from the code step to the number step.
  ///
  /// Stops the countdown: a resend cooldown is a property of the number that was
  /// just texted, and keeping it running for a number the user has abandoned
  /// would block the next attempt for no reason.
  void backToPhoneNumber() {
    if (_busy) return;
    _stopCountdown();
    emit(AuthState.signedOut());
  }

  /// Sets a display name on the signed-in account.
  Future<void> setDisplayName(String name) async {
    final current = state.user;
    final token = _token;
    if (current == null || token == null || _busy) return;

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      emit(AuthState.failedWhileSignedIn(
        const AuthError(AuthFailure.unexpected, message: AppStrings.profileNameEmpty),
        user: current,
        verified: state.verified,
      ));
      return;
    }

    try {
      final updated = await api.updateProfile(
        accessToken: token,
        displayName: trimmed,
      );

      // Rewritten rather than patched: the server's copy is authoritative, and
      // storing a locally-assembled user risks the two drifting.
      await tokenStore.write(StoredSession(accessToken: token, user: updated));
      emit(AuthState.signedIn(updated, verified: true));
    } on AuthError catch (error) {
      // The account stays. A name that would not save is a problem with the name,
      // not a reason to show somebody as signed out.
      emit(AuthState.failedWhileSignedIn(
        error,
        user: current,
        verified: state.verified,
      ));
    }
  }

  /// Forgets the session.
  ///
  /// Local only, and deliberately so. Signing out is not a request: a user on a
  /// plane must be able to sign out, and a sign-out that needs the network is a
  /// sign-out that fails exactly when it is most wanted.
  Future<void> signOut() async {
    _stopCountdown();
    await _endSession();
    emit(const AuthState.signedOut());
  }

  /// Ends the session, and forgets what belonged to the account.
  Future<void> _endSession() async {
    _token = null;
    await tokenStore.clear();
    await onSessionEnded?.call();
  }

  /// This install's own name, or null when it cannot be worked out.
  ///
  /// Failure here costs the device its place in the list, and nothing else. A
  /// sign-in that refused over a missing label would be trading the whole feature
  /// for its least important part.
  Future<LocalDevice?> _resolveDevice() async {
    final identity = deviceIdentity;
    if (identity == null) {
      return null;
    }
    try {
      return await identity.resolve();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _stopCountdown();
    return super.close();
  }
}
