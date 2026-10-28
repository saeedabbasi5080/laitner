import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/permissions/media_permission.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/utils/picked_file_bytes.dart';
import 'package:recall/domain/entities/card_media.dart';

enum CardAttachChoice { photo, camera, audio, voice }

Future<CardAttachChoice?> showCardAttachSheet(BuildContext context) {
  return showModalBottomSheet<CardAttachChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final colors = context.recallColors;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 512),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: AppShadows.card(context),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.attachMedia,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text(AppStrings.attachPhoto),
                  onTap: () => Navigator.pop(context, CardAttachChoice.photo),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text(AppStrings.attachCamera),
                  onTap: () => Navigator.pop(context, CardAttachChoice.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.audiotrack_outlined),
                  title: const Text(AppStrings.attachAudio),
                  onTap: () => Navigator.pop(context, CardAttachChoice.audio),
                ),
                ListTile(
                  leading: const Icon(Icons.mic_none_outlined),
                  title: const Text(AppStrings.attachVoice),
                  onTap: () => Navigator.pop(context, CardAttachChoice.voice),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class PickedCardAttachment {
  const PickedCardAttachment({
    required this.kind,
    this.bytes,
    this.filePath,
    required this.fileName,
  });

  final CardMediaKind kind;
  final List<int>? bytes;
  final String? filePath;
  final String fileName;
}

Future<PickedCardAttachment?> pickCardAttachment(
  BuildContext context,
  CardAttachChoice choice,
) async {
  switch (choice) {
    case CardAttachChoice.photo:
      return _pickImage(ImageSource.gallery);
    case CardAttachChoice.camera:
      final granted = await ensureCameraPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.mediaPermissionDenied)),
          );
        }
        return null;
      }
      return _pickImage(ImageSource.camera);
    case CardAttachChoice.audio:
      return _pickAudio(context);
    case CardAttachChoice.voice:
      return null;
  }
}

Future<PickedCardAttachment?> _pickImage(ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 85,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) return null;
  return PickedCardAttachment(
    kind: CardMediaKind.image,
    bytes: bytes,
    fileName: file.name,
  );
}

Future<PickedCardAttachment?> _pickAudio(BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.audio,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  final bytes = await readPickedFileBytes(file);
  if (bytes == null || bytes.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.mediaAttachFailed)),
      );
    }
    return null;
  }
  return PickedCardAttachment(
    kind: CardMediaKind.audio,
    bytes: bytes,
    fileName: file.name,
  );
}
