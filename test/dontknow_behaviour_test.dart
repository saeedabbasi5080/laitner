import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/entities/review_settings.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_review_history_repository.dart';

Flashcard _card({int box = 1}) => Flashcard(
      id: 'c1',
      deckId: 'd1',
      front: 'Apple',
      back: 'سیب',
      box: box,
      createdAt: DateTime(2026, 3, 1),
    );

void main() {
  late _Repo repo;
  late ReviewCardUseCase useCase;

  setUp(() {
    repo = _Repo();
    useCase = ReviewCardUseCase(repo, FakeReviewHistoryRepository());
  });

  int boxAfter(ReviewRating rating, int fromBox, ReviewSettings settings) {
    return useCase
        .applyReview(
          _card(box: fromBox),
          rating,
          now: DateTime(2026, 3, 11),
          settings: settings,
        )
        .box;
  }

  group('dontKnow behaviour', () {
    test('resetToFirst sends every house back to 1', () {
      const settings = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.resetToFirst,
      );

      for (final box in [1, 2, 3, 4, 5]) {
        expect(boxAfter(ReviewRating.dontKnow, box, settings), 1);
      }
    });

    test('stepBack drops exactly one house', () {
      const settings = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.stepBack,
      );

      expect(boxAfter(ReviewRating.dontKnow, 5, settings), 4);
      expect(boxAfter(ReviewRating.dontKnow, 3, settings), 2);
      expect(boxAfter(ReviewRating.dontKnow, 2, settings), 1);
    });

    test('stepBack never goes below house 1', () {
      const settings = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.stepBack,
      );

      expect(boxAfter(ReviewRating.dontKnow, 1, settings), 1);
    });

    test('stepBack respects the enabled house count', () {
      // With six houses the ladder is longer, so house 6 should fall to 5.
      const settings = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.stepBack,
      );

      expect(boxAfter(ReviewRating.dontKnow, 6, settings), 5);
    });

    test('know always advances regardless of the behaviour', () {
      for (final behaviour in DontKnowBehaviour.values) {
        final settings = ReviewSettings(dontKnowBehaviour: behaviour);
        expect(boxAfter(ReviewRating.know, 1, settings), 2);
        expect(boxAfter(ReviewRating.know, 4, settings), 5);
      }
    });

    test('the default is unchanged for existing users', () {
      const settings = ReviewSettings();
      expect(settings.dontKnowBehaviour, DontKnowBehaviour.resetToFirst);
      expect(boxAfter(ReviewRating.dontKnow, 4, settings), 1);
    });

    test('know in the last house still graduates the card', () {
      final updated = useCase.applyReview(
        _card(box: 5),
        ReviewRating.know,
        now: DateTime(2026, 3, 11),
      );

      expect(updated.box, 6);
    });

    test('the next review date shortens when stepping back', () {
      const stepBack = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.stepBack,
      );
      const reset = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.resetToFirst,
      );
      final card = _card(box: 5);

      final stepped = useCase.computeNextReviewDate(
        card,
        ReviewRating.dontKnow,
        now: DateTime(2026, 3, 11),
        settings: stepBack,
      );
      final restarted = useCase.computeNextReviewDate(
        card,
        ReviewRating.dontKnow,
        now: DateTime(2026, 3, 11),
        settings: reset,
      );

      // Stepping back lands in house 4 (an eight day gap), while restarting
      // lands in house 1 (a one day gap), so the reset comes back sooner.
      expect(stepped.isAfter(restarted), isTrue);
    });
  });

  group('ReviewSettings', () {
    test('survives a json round trip', () {
      const settings = ReviewSettings(
        dontKnowBehaviour: DontKnowBehaviour.stepBack,
      );

      expect(ReviewSettings.fromJson(settings.toJson()), settings);
    });

    test('falls back to the default for unknown names', () {
      expect(
        ReviewSettings.fromJson({'dontKnowBehaviour': 'nonsense'})
            .dontKnowBehaviour,
        DontKnowBehaviour.resetToFirst,
      );
      expect(
        ReviewSettings.fromJson(null).dontKnowBehaviour,
        DontKnowBehaviour.resetToFirst,
      );
    });
  });

  group('per-space persistence', () {
    late SpaceSettingsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = SpaceSettingsStore(await SharedPreferences.getInstance());
    });

    test('a space without settings keeps the original behaviour', () async {
      final settings = await store.load('space-1');
      expect(
        settings.reviewSettings.dontKnowBehaviour,
        DontKnowBehaviour.resetToFirst,
      );
    });

    test('the choice is remembered per space', () async {
      await store.save(
        'space-1',
        const SpaceSettingsData().copyWith(
          reviewSettings: ReviewSettings(
            dontKnowBehaviour: DontKnowBehaviour.stepBack,
          ),
        ),
      );
      await store.save('space-2', const SpaceSettingsData());

      expect(
        (await store.load('space-1')).reviewSettings.dontKnowBehaviour,
        DontKnowBehaviour.stepBack,
      );
      expect(
        (await store.load('space-2')).reviewSettings.dontKnowBehaviour,
        DontKnowBehaviour.resetToFirst,
      );
    });
  });
}

class _Repo implements IFlashcardRepository {
  @override
  Future<List<Flashcard>> getAllCards() async => const [];

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async => const [];

  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => const [];

  @override
  Future<Flashcard> addCard(Flashcard card) async => card;

  @override
  Future<void> deleteCard(String id) async {}

  @override
  Future<Flashcard?> getCardById(String id) async => null;

  @override
  Future<Flashcard> updateCard(Flashcard card) async => card;
}