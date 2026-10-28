import 'package:recall/data/utils/card_media_store.dart';
import 'package:recall/domain/entities/card_media.dart';

class WebCardMediaStore implements CardMediaStore {
  @override
  Future<CardMedia> importBytes({
    required String draftId,
    required CardMediaSide side,
    required CardMediaKind kind,
    required List<int> bytes,
    required String fileName,
  }) {
    throw UnsupportedError('پیوست رسانه روی وب پشتیبانی نمی‌شود');
  }

  @override
  Future<CardMedia> importFile({
    required String draftId,
    required CardMediaSide side,
    required CardMediaKind kind,
    required String filePath,
    required String fileName,
  }) {
    throw UnsupportedError('پیوست رسانه روی وب پشتیبانی نمی‌شود');
  }

  @override
  Future<String?> absolutePath(CardMedia media) async => null;

  @override
  Future<void> delete(CardMedia media) async {}
}

CardMediaStore createCardMediaStore() => WebCardMediaStore();
