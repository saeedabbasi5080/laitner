import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<Uint8List?> readPickedFileBytes(PlatformFile file) async {
  return file.bytes;
}
