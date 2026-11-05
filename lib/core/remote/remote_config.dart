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
  ///
  /// Defaults to the test server so a plain `flutter build apk` reaches it.
  /// Plaintext on purpose for the test period: the release build is allowed to
  /// talk HTTP to this one address by
  /// `android/app/src/main/res/xml/network_security_config.xml`. Moving to
  /// HTTPS means changing this default and deleting that file.
  static const String apiBaseUrl = String.fromEnvironment(
    'ATILEARN_API_BASE_URL',
    defaultValue: testServer,
  );

  /// The test server, by address and port while it has no domain.
  static const String testServer = 'http://185.239.3.63:5050/api/v1';

  /// The Android emulator's name for the host machine's loopback.
  ///
  /// `localhost` inside the emulator is the emulator, not the laptop. Getting
  /// this wrong is the usual reason a sign-in that works on the desktop build
  /// fails on the device.
  ///
  /// Pass it with `--dart-define` to run against a backend on the laptop.
  static const String emulatorLoopback = 'http://10.0.2.2:5070/api/v1';

  /// Whether an address was compiled in at all.
  ///
  /// Only an empty `--dart-define` can make this false. Checked rather than
  /// assumed, because the failure it prevents is silent: the request fails, the
  /// screen says "could not reach the server", and nothing anywhere says the
  /// address was never configured in the first place.
  static bool get isConfigured => apiBaseUrl.isNotEmpty;

  /// `true` when the address points at a plaintext HTTP host.
  ///
  /// Worth surfacing rather than silently allowing: the service sends a
  /// one-time code, and anything on the path can read it. Cleartext is fine on
  /// a laptop talking to a laptop and not fine anywhere else.
  static bool get isCleartext => apiBaseUrl.startsWith('http://');
}
