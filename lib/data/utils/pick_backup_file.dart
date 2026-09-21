import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/permissions/storage_permission.dart';
import 'package:recall/data/utils/picked_file_bytes.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

Future<bool> _ensureFileAccess(BuildContext context) async {
  final granted = await ensureStoragePermissionForFileAccess();
  if (!context.mounted) return false;

  if (granted) return true;

  final permanentlyDenied = await isStoragePermissionPermanentlyDenied();
  if (!context.mounted) return false;

  if (permanentlyDenied) {
    final openSettings = await showConfirmDialog(
      context,
      title: AppStrings.storagePermissionTitle,
      message: AppStrings.storagePermissionPermanentlyDenied,
      confirmLabel: AppStrings.openSettings,
    );
    if (openSettings == true) {
      await openStoragePermissionSettings();
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.storagePermissionDenied)),
    );
  }
  return false;
}

Future<bool> saveBackupFile(
  BuildContext context, {
  required String fileName,
  required String jsonText,
}) async {
  if (!await _ensureFileAccess(context)) return false;
  if (!context.mounted) return false;

  final path = await FilePicker.platform.saveFile(
    dialogTitle: AppStrings.exportBackup,
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['json'],
    bytes: Uint8List.fromList(utf8.encode(jsonText)),
  );
  return path != null;
}

Future<String?> pickBackupFile(BuildContext context) async {
  if (!await _ensureFileAccess(context)) return null;
  if (!context.mounted) return null;

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: true,
  );
  if (!context.mounted) return null;
  if (result == null || result.files.isEmpty) return null;

  final bytes = await readPickedFileBytes(result.files.first);
  if (bytes == null || bytes.isEmpty) {
    throw const FormatException();
  }
  return utf8.decode(bytes);
}
