import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/tts/auto_speak_side.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';

void main() {
  group('AutoSpeakSide.shouldSpeak', () {
    test('front speaks on first face, not after flip', () {
      expect(
        AutoSpeakSide.front.shouldSpeak(isFlipped: false, reversed: false),
        isTrue,
      );
      expect(
        AutoSpeakSide.front.shouldSpeak(isFlipped: true, reversed: false),
        isFalse,
      );
    });

    test('back waits until the back is shown', () {
      expect(
        AutoSpeakSide.back.shouldSpeak(isFlipped: false, reversed: false),
        isFalse,
      );
      expect(
        AutoSpeakSide.back.shouldSpeak(isFlipped: true, reversed: false),
        isTrue,
      );
    });

    test('reversed review shows back first', () {
      expect(
        AutoSpeakSide.back.shouldSpeak(isFlipped: false, reversed: true),
        isTrue,
      );
      expect(
        AutoSpeakSide.front.shouldSpeak(isFlipped: false, reversed: true),
        isFalse,
      );
      expect(
        AutoSpeakSide.front.shouldSpeak(isFlipped: true, reversed: true),
        isTrue,
      );
    });
  });

  group('StudyConfig.applySpaceSettings', () {
    test('normal review uses the space default direction', () {
      const config = StudyConfig.deck(spaceId: 's1', deckId: 'd1');
      final applied = config.applySpaceSettings(
        randomOrder: true,
        defaultReversed: true,
      );

      expect(applied.reversed, isTrue);
      expect(applied.randomOrder, isTrue);
      expect(applied.isBoxReview, isFalse);
    });

    test('free review keeps its own reverse setting', () {
      const config = StudyConfig.byBox(2, spaceId: 's1', reversed: false);
      final applied = config.applySpaceSettings(
        randomOrder: true,
        defaultReversed: true,
      );

      expect(applied.reversed, isFalse);
      expect(applied.randomOrder, isTrue);
      expect(applied.isBoxReview, isTrue);
    });
  });
}
