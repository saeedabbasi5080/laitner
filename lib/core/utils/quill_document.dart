import 'package:flutter_quill/flutter_quill.dart';
import 'package:recall/core/utils/card_style_codec.dart';

Document documentFromCardSide({
  required String plain,
  required String style,
}) {
  final json = CardStyleCodec.tryDecode(style);
  if (json != null) {
    try {
      return Document.fromJson(json);
    } catch (_) {}
  }
  final text = plain.trim();
  return Document.fromJson([
    {'insert': text.isEmpty ? '\n' : '$text\n'},
  ]);
}

String plainFromDocument(Document document) => document.toPlainText().trim();

String styleFromDocument(Document document) =>
    CardStyleCodec.encode(document.toDelta().toJson());
