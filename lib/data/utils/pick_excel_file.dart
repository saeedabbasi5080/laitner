import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/permissions/storage_permission.dart';
import 'package:recall/data/utils/picked_file_bytes.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class PickedExcelFile {
  const PickedExcelFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Requests storage permission (Android) then opens the Excel file picker.
Future<PickedExcelFile?> pickExcelFile(BuildContext context) async {
  final granted = await ensureStoragePermissionForFileAccess();
  if (!context.mounted) return null;

  if (!granted) {
    final permanentlyDenied = await isStoragePermissionPermanentlyDenied();
    if (!context.mounted) return null;

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
    return null;
  }

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'xls'],
    withData: true,
  );

  if (!context.mounted) return null;

  if (result == null || result.files.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.noFileSelected)),
    );
    return null;
  }

  final file = result.files.first;

  Uint8List? bytes;
  try {
    bytes = await readPickedFileBytes(file);
  } catch (_) {
    bytes = null;
  }

  if (!context.mounted) return null;

  if (bytes == null || bytes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.importFailed)),
    );
    return null;
  }

  return PickedExcelFile(name: file.name, bytes: bytes);
}
