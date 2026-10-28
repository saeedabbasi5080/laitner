import 'package:recall/domain/entities/card_media.dart';

abstract class CardMediaStore {
  Future<CardMedia> importBytes({
    required String draftId,
    required CardMediaSide side,
    required CardMediaKind kind,
    required List<int> bytes,
    required String fileName,
  });

  Future<CardMedia> importFile({
    required String draftId,
    required CardMediaSide side,
    required CardMediaKind kind,
    required String filePath,
    required String fileName,
  });

  Future<String?> absolutePath(CardMedia media);

  Future<void> delete(CardMedia media);
}
