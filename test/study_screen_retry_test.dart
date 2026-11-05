import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/tts/tts_service.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_space_cards_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_review_history_repository.dart';

final _past = DateTime.now().subtract(const Duration(days: 3));

class _Cards implements IFlashcardRepository {
  _Cards(this.cards);
  final List<Flashcard> cards;

  @override
  Future<List<Flashcard>> getAllCards() async => cards;
  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async =>
      cards.where((c) => c.deckId == deckId).toList();
  @override
  Future<List<Flashcard>> getCardsBySpaceId(String spaceId) async => cards;
  @override
  Future<Flashcard> addCard(Flashcard card) async => card;
  @override
  Future<void> deleteCard(String id) async {}
  @override
  Future<Flashcard?> getCardById(String id) async =>
      cards.where((c) => c.id == id).firstOrNull;
  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    final i = cards.indexWhere((c) => c.id == card.id);
    if (i >= 0) cards[i] = card;
    return card;
  }
}

class _Decks implements IDeckRepository {
  final decks = [
    Deck(
      id: 'd1',
      spaceId: 's1',
      name: 'Deck',
      color: DeckColor.mint,
      createdAt: _past,
    ),
  ];

  @override
  Future<List<Deck>> getAllDecks() async => decks;
  @override
  Future<Deck?> getDeckById(String id) async => decks.first;
  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async => decks;
  @override
  Future<Deck> addDeck(Deck deck) async => deck;
  @override
  Future<void> deleteDeck(String id) async {}
  @override
  Future<Deck> updateDeck(Deck deck) async => deck;
}

class _SilentTts implements TtsService {
  @override
  Future<void> stop() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Cards cards;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await sl.reset();
    cards = _Cards([
      for (final id in ['c1', 'c2'])
        Flashcard(
          id: id,
          deckId: 'd1',
          front: 'Word-$id',
          back: 'x',
          box: 2,
          lastReviewed: _past,
          createdAt: _past,
        ),
    ]);
    final decks = _Decks();
    sl.registerSingleton<SpaceSettingsStore>(SpaceSettingsStore(prefs));
    sl.registerSingleton<TtsService>(_SilentTts());
    sl.registerSingleton<SettingsCubit>(
      SettingsCubit(prefs, sl<SpaceSettingsStore>(), cards),
    );
    sl.registerFactoryParam<StudyCubit, StudyConfig, void>(
      (config, _) => StudyCubit(
        config: config,
        getDueCardsUseCase: GetDueCardsUseCase(cards),
        getAllDueCardsUseCase: GetAllDueCardsUseCase(cards),
        getSpaceCardsUseCase: GetSpaceCardsUseCase(cards),
        getCardsByBoxUseCase: GetCardsByBoxUseCase(cards),
        getCardsByDeckUseCase: GetCardsByDeckUseCase(cards),
        getDecksUseCase: GetDecksUseCase(decks),
        reviewCardUseCase: ReviewCardUseCase(
          cards,
          FakeReviewHistoryRepository(),
        ),
        updateCardUseCase: UpdateCardUseCase(cards),
        deleteCardUseCase: DeleteCardUseCase(cards),
      ),
    );
  });

  tearDown(() => sl.reset());

  Future<void> answerEveryCard(WidgetTester tester, String answer) async {
    while (find.text(AppStrings.tapToReveal).evaluate().isNotEmpty ||
        find.textContaining('Word-').evaluate().isNotEmpty) {
      if (find.text(answer).evaluate().isEmpty) {
        await tester.tap(find.textContaining('Word-').first);
        await tester.pumpAndSettle();
      }
      if (find.text(answer).evaluate().isEmpty) break;
      await tester.tap(find.text(answer));
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'the missed cards can be seen, with answers, and retried from there',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        BlocProvider.value(
          value: sl<SettingsCubit>(),
          child: MaterialApp(
            theme: AppTheme.light(AppAccent.lavender),
            home: const StudyScreen(
              config: StudyConfig.deck(spaceId: 's1', deckId: 'd1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await answerEveryCard(tester, AppStrings.dontKnow);

      await tester.tap(find.text(AppStrings.seeMistakes(2)));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sessionMistakesTitle), findsOneWidget);
      expect(find.text('Word-c1'), findsOneWidget);
      expect(find.text('Word-c2'), findsOneWidget);
      expect(find.text('x'), findsNWidgets(2), reason: 'answers are shown');

      // The sheet's own retry button: the one inside the sheet is the last one.
      await tester.tap(find.text(AppStrings.reviewMistakes(2)).last);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.sessionMistakesTitle), findsNothing);
      expect(find.textContaining('Word-'), findsOneWidget);
    },
  );

  for (final (name, config) in [
    ('a deck review', const StudyConfig.deck(spaceId: 's1', deckId: 'd1')),
    ('today\'s review', const StudyConfig.allDue(spaceId: 's1')),
    ('a house review', const StudyConfig.byBox(2, spaceId: 's1')),
    (
      'a house review of overdue cards',
      const StudyConfig.byBox(2, spaceId: 's1', overdueOnly: true),
    ),
  ]) {
    testWidgets('after $name, the mistakes button starts a retry over them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        BlocProvider.value(
          value: sl<SettingsCubit>(),
          child: MaterialApp(
            theme: AppTheme.light(AppAccent.lavender),
            home: StudyScreen(config: config),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await answerEveryCard(tester, AppStrings.dontKnow);

      final retry = find.text(AppStrings.reviewMistakes(2));
      expect(retry, findsOneWidget);

      await tester.tap(retry);
      await tester.pumpAndSettle();

      // A new session over the two missed cards, not the finished screen again.
      expect(find.text(AppStrings.reviewMistakes(2)), findsNothing);
      expect(find.textContaining('Word-'), findsOneWidget);
    });
  }
}
