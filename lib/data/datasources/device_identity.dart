import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How this install names itself to the server.
class LocalDevice {
  const LocalDevice({required this.id, this.label});

  /// Minted once, on first use, and kept. It is what the server lists and what a
  /// user removes when they sign a device out, so it has to survive restarts —
  /// a device that renamed itself each launch could never be removed.
  final String id;

  /// What a person would call this device. Null when it cannot be determined.
  final String? label;
}

/// Where this device's own name is decided and kept.
abstract class DeviceIdentity {
  /// This install's id and, when it can be worked out, its name.
  Future<LocalDevice> resolve();
}

/// A name for the device, when the platform will give one.
///
/// Its own type so that tests never reach a platform channel, and so the app can
/// run where the answer is simply unavailable rather than failing.
abstract class DeviceLabelSource {
  Future<String?> label();
}

class StoredDeviceIdentity implements DeviceIdentity {
  StoredDeviceIdentity({
    required SharedPreferences preferences,
    required IdGenerator ids,
    DeviceLabelSource? labels,
  })  : _prefs = preferences,
        _ids = ids,
        _labels = labels ?? const PlatformDeviceLabelSource();

  /// Deliberately not under the auth namespace. The device is this install, not
  /// this session: signing out and back in must not produce a new device, or the
  /// list would grow a row every time somebody signed in again.
  static const String storageKey = 'recall.device.id';

  final SharedPreferences _prefs;
  final IdGenerator _ids;
  final DeviceLabelSource _labels;

  @override
  Future<LocalDevice> resolve() async {
    return LocalDevice(id: await _id(), label: await _labels.label());
  }

  Future<String> _id() async {
    final existing = _prefs.getString(storageKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }

    final created = _ids.generateId();
    await _prefs.setString(storageKey, created);
    return created;
  }
}

/// Asks the platform, and gives up quietly when it will not say.
class PlatformDeviceLabelSource implements DeviceLabelSource {
  const PlatformDeviceLabelSource();

  @override
  Future<String?> label() async {
    // The web build has no device to name, and on the desktop builds the answer
    // would be the machine rather than the person. Returning nothing lets the
    // server's list fall back to a shortened id, which is still enough to pick
    // between two rows.
    if (kIsWeb) return null;

    try {
      final plugin = DeviceInfoPlugin();

      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return deviceLabelFrom(info.brand, info.model);
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await plugin.iosInfo;
        final name = info.name.trim();
        return name.isNotEmpty ? name : info.model;
      }

      return null;
    } catch (error) {
      // A plugin that is missing, a denied permission, a platform that answers
      // with something unexpected. None of it is worth failing a sign-in over:
      // the label is a convenience, never a requirement.
      debugPrint('Could not read this device\'s name ($error).');
      return null;
    }
  }
}

/// A readable name from a brand and a model.
///
/// A top-level function rather than a method, because it is the one part of
/// naming a device that is pure and worth testing on its own — everything else in
/// the class reaches for a platform channel.
///
/// Skips a brand already contained in the model, which is what Android usually
/// reports: without that the list reads "Samsung Samsung SM-G991B".
String? deviceLabelFrom(String brand, String model) {
  final cleanBrand = brand.trim();
  final cleanModel = model.trim();

  if (cleanModel.isEmpty) {
    return cleanBrand.isEmpty ? null : cleanBrand;
  }
  if (cleanBrand.isEmpty ||
      cleanModel.toLowerCase().contains(cleanBrand.toLowerCase())) {
    return cleanModel;
  }
  return '$cleanBrand $cleanModel';
}
