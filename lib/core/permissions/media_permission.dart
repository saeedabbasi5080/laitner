import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureCameraPermission() => _request(Permission.camera);

Future<bool> ensureMicrophonePermission() => _request(Permission.microphone);

Future<bool> _request(Permission permission) async {
  try {
    var status = await permission.status;
    if (status.isGranted || status.isLimited) return true;
    status = await permission.request();
    return status.isGranted || status.isLimited;
  } catch (_) {
    return true;
  }
}
