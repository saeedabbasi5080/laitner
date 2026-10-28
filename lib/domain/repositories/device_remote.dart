import 'package:recall/domain/entities/auth_device.dart';

/// The server's record of where an account is being used from.
///
/// A port rather than the HTTP client so the screen that shows this can be tested
/// against a list, without a network and without a server that has to be made to
/// have two devices.
abstract interface class DeviceRemote {
  /// Every device on the account, most recently used first.
  Future<List<AuthDevice>> listDevices(String accessToken);

  /// Signs a device out.
  ///
  /// Idempotent, and the device itself is not told: it finds out on its next call.
  /// That is not a shortcoming — the device most likely to need removing is one
  /// the user is not holding.
  Future<void> signOutDevice({required String accessToken, required String deviceId});
}
