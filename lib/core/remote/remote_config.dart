/// Where the sign-in service lives.
///
/// Signing in is optional, so nothing else in the app may import this: a wrong
/// address here must cost the user a failed sign-in attempt and nothing more.
///
/// Set at build time with `--dart-define`:
///
/// ```
/// flutter build apk --dart-define=ATILEARN_API_BASE_URL=https://api.atilearn.ir/api/v1
/// ```
library;

/// The base URL of the sign-in service, without a trailing slash.
///
/// Compiled in rather than fetched at run time. The alternative — reading it
/// from the server — needs a server to read it from, so the first launch after
/// an install could not sign in without first failing to reach the server that
/// would have told it where to go.
abstract final class RemoteConfig {
  /// Overridable at build time; see the doc comment above.
  static const String apiBaseUrl = String.fromEnvironment(
    'ATILEARN_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5070/api/v1',
  );

  /// The Android emulator's name for the host machine's loopback.
  ///
  /// `localhost` inside the emulator is the emulator, not the laptop. Getting
  /// this wrong is the usual reason a sign-in that works on the desktop build
  /// fails on the device.
  ///
  /// Public because it is also the marker for "never configured": it is the
  /// default, so a build that still has it was never told where the server is.
  static const String emulatorLoopback = 'http://10.0.2.2:5070/api/v1';

  /// Whether the compiled-in address is one that cannot possibly work.
  ///
  /// Checked rather than assumed, because the failure this prevents is silent:
  /// the request fails, the screen says "could not reach the server", and nothing
  /// anywhere says the address was never configured in the first place.
  static bool get isConfigured => apiBaseUrl != emulatorLoopback;

  /// `true` when the address points at a plaintext HTTP host.
  ///
  /// Worth surfacing rather than silently allowing: the service sends a
  /// one-time code, and anything on the path can read it. Cleartext is fine on
  /// a laptop talking to a laptop and not fine anywhere else.
  static bool get isCleartext => apiBaseUrl.startsWith('http://');
}
