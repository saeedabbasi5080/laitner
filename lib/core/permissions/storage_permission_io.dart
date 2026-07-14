import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Ensures storage access is available before reading files from disk on Android.
///
/// Android 13+ uses the system document picker (SAF) and does not require
/// legacy storage permission. Older Android versions need [Permission.storage].
Future<bool> ensureStoragePermissionForFileAccess() async {
  if (!Platform.isAndroid) return true;

  final sdkInt = await _androidSdkInt();
  if (sdkInt >= 33) return true;

  var status = await Permission.storage.status;
  if (status.isGranted) return true;

  status = await Permission.storage.request();
  return status.isGranted;
}

Future<bool> isStoragePermissionPermanentlyDenied() async {
  if (!Platform.isAndroid) return false;

  final sdkInt = await _androidSdkInt();
  if (sdkInt >= 33) return false;

  final status = await Permission.storage.status;
  return status.isPermanentlyDenied;
}

Future<void> openStoragePermissionSettings() => openAppSettings();

Future<int> _androidSdkInt() async {
  final info = await DeviceInfoPlugin().androidInfo;
  return info.version.sdkInt;
}
