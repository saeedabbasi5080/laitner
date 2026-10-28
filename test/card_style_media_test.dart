import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/card_style_codec.dart';
import 'package:recall/domain/entities/card_media.dart';
import 'package:recall/domain/entities/flashcard.dart';

void main() {
  test('style codec round-trips quill delta json', () {
    const delta = [
      {
        'insert': 'hello',
        'attributes': {'bold': true},
      },
      {'insert': '\n'},
    ];
    final encoded = CardStyleCodec.encode(delta);
    expect(encoded, isNotEmpty);
    expect(CardStyleCodec.tryDecode(encoded), delta);
    expect(CardStyleCodec.tryDecode(''), isNull);
    expect(CardStyleCodec.tryDecode('not-json'), isNull);
  });

  test('old card json without style or media still loads', () {
    final card = Flashcard.fromJson({
      'id': 'c1',
      'deckId': 'd1',
      'front': 'hello',
      'back': 'سلام',
      'box': 1,
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    });
    expect(card.frontStyle, isEmpty);
    expect(card.backStyle, isEmpty);
    expect(card.media, isEmpty);
  });

  test('card media json round-trips on flashcard', () {
    const media = CardMedia(
      id: 'm1',
      side: CardMediaSide.back,
      kind: CardMediaKind.voice,
      relativePath: 'draft/m1.m4a',
      originalName: 'voice.m4a',
    );
    final card = Flashcard(
      id: 'c1',
      deckId: 'd1',
      front: 'hello',
      back: 'سلام',
      box: 1,
      createdAt: DateTime(2026, 1, 1),
      frontStyle: '[{"insert":"hello\\n"}]',
      media: const [media],
    );
    final restored = Flashcard.fromJson(card.toJson());
    expect(restored.frontStyle, card.frontStyle);
    expect(restored.media, [media]);
    expect(restored.mediaFor(CardMediaSide.back), [media]);
    expect(restored.mediaFor(CardMediaSide.front), isEmpty);
  });
}
