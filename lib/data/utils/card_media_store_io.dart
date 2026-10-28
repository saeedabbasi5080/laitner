import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:recall/data/utils/card_media_store.dart';
import 'package:recall/domain/entities/card_media.dart';

class IoCardMediaStore implements CardMediaStore {
  static const _rootName = 'card_media';

  Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _rootName));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<CardMedia> importBytes({
    required String draftId,
    required CardMediaSide side,
    required CardMediaKind kind,
    required List<int> bytes,
    required String fileName,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final ext = p.extension(fileName).replaceAll('.', '').toLowerCase();
    final safeExt = ext.isEmpty
        ? (kind == CardMediaKind.image ? 'jpg' : 'm4a')
        : ext;
    final relativePath = p.join(draftId, '$id.$safeExt');
    final root = await _root();
    final file = File(p.join(root.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(Uint8List.fromList(bytes), flush: true);
    return CardMedia(
      id: id,
      side: side,
      kind: kind,
      relativePath: relativePath.replaceAll('\\', '/'),
      originalName: fileName,
    );
  }

  @override
  Future<CardMedia> importFile({
    required String draftId,
    required CardMediaSide side,
    required CardMediaKind kind,
    required String filePath,
    required String fileName,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    return importBytes(
      draftId: draftId,
      side: side,
      kind: kind,
      bytes: bytes,
      fileName: fileName,
    );
  }

  @override
  Future<String?> absolutePath(CardMedia media) async {
    final root = await _root();
    final file = File(p.join(root.path, media.relativePath));
    if (!file.existsSync()) return null;
    return file.path;
  }

  @override
  Future<void> delete(CardMedia media) async {
    final path = await absolutePath(media);
    if (path == null) return;
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

CardMediaStore createCardMediaStore() => IoCardMediaStore();
