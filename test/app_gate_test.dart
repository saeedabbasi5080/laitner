import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/app_gate/app_gate.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/sync_app_gate_due_usecase.dart';
import 'package:recall/domain/usecases/get_app_gate_cards_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/data/repositories/space_repository_impl.dart';
import 'package:recall/presentation/screens/gate_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/presentation/blocs/gate/gate_cubit.dart';
import 'package:recall/presentation/screens/app_gate_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_review_history_repository.dart';
import 'support/in_memory_local_data_source.dart';

class FakeGatePlatform implements AppGatePlatform {
  AppGateConfig config = const AppGateConfig();
  AppGateStatus currentStatus = const AppGateStatus(
    accessibility: true,
    overlay: true,
  );
  GateTarget? gateTarget = const GateTarget(
    package: 'com.instagram.android',
    label: 'Instagram',
  );
  final opened = <String>[];
  var wentHome = 0;
  ({int count, DateTime day})? due;
  final saved = <AppGateConfig>[];
  bool isSupported = true;

  @override
  bool get supported => isSupported;
  @override
  Future<AppGateConfig> loadConfig() async => config;
  @override
  Future<void> saveConfig(AppGateConfig c) async {
    config = c;
    saved.add(c);
  }

  @override
  Future<void> setDueState(int count, DateTime day) async =>
      due = (count: count, day: day);
  @override
  Future<AppGateStatus> status() async => currentStatus;
  @override
  Future<void> openAccessibilitySettings() async => accessibilityOpened++;
  @override
  Future<void> openOverlaySettings() async => overlayOpened++;
  @override
  Future<void> openAppInfo() async => appInfoOpened++;
  var accessibilityOpened = 0;
  var overlayOpened = 0;
  var appInfoOpened = 0;
  @override
  Future<List<InstalledApp>> listApps() async => const [
    InstalledApp(package: 'com.instagram.android', label: 'Instagram'),
    InstalledApp(package: 'org.telegram.messenger', label: 'Telegram'),
  ];
  @override
  Future<GateTarget?> target() async => gateTarget;
  @override
  Future<void> unlockAndOpen(String package) async => opened.add(package);
  @override
  Future<void> goHome() async => wentHome++;
  @override
  void onTargetChanged(void Function() callback) {}
}

void main() {
  group('settings', () {
    test('survive the trip to the native side and back', () {
      const config = AppGateConfig(
        enabled: true,
        packages: {'b', 'a'},
        mode: AppGateMode.allDue,
        cardsPerOpen: 4,
        graceEnabled: true,
        graceMinutes: 7,
        allSpaces: false,
        spaceIds: {'s1'},
      );
      final json = config.toJson();
      // The keys the native GateDecider reads.
      expect(json['enabled'], true);
      expect(json['packages'], ['a', 'b']);
      expect(json['graceEnabled'], true);
      expect(json['graceMinutes'], 7);
      expect(AppGateConfig.fromJson(json), config);
    });

    test('keep counts within range and default the free window to off', () {
      final config = AppGateConfig.fromJson({
        'cardsPerOpen': 50,
        'graceMinutes': 0,
      });
      expect(config.cardsPerOpen, AppGateConfig.maxCards);
      expect(config.graceMinutes, AppGateConfig.minGrace);
      expect(const AppGateConfig().graceEnabled, isFalse);
    });

    test('the day key matches the native one', () {
      expect(gateDayKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
    });
  });

  group('the gate', () {
    late FakeGatePlatform platform;
    late InMemoryLocalDataSource local;
    late FakeReviewHistoryRepository history;
    late SpaceSettingsStore settings;
    final past = DateTime.now().subtract(const Duration(days: 10));

    Flashcard card(String id, String deck) => Flashcard(
      id: id,
      deckId: deck,
      front: 'front-$id',
      back: 'back-$id',
      box: 1,
      lastReviewed: past,
      createdAt: past,
    );

    /// Two spaces: `s1` (deck `d1`) and `s2` (deck `d2`).
    Future<GateCubit> build({
      required int due,
      int dueInS2 = 0,
      AppGateConfig? config,
    }) async {
      SharedPreferences.setMockInitialValues({});
      settings = SpaceSettingsStore(await SharedPreferences.getInstance());
      platform = FakeGatePlatform()
        ..config =
            config ?? const AppGateConfig(enabled: true, cardsPerOpen: 2);
      local = InMemoryLocalDataSource(
        spaces: [
          for (final id in ['s1', 's2'])
            LearningSpace(
              id: id,
              name: id,
              color: DeckColor.mint,
              createdAt: past,
            ),
        ],
        decks: [
          for (final (id, space) in [('d1', 's1'), ('d2', 's2')])
            Deck(
              id: id,
              spaceId: space,
              name: id,
              color: DeckColor.mint,
              createdAt: past,
            ),
        ],
        cards: [
          for (var i = 0; i < due; i++) card('a$i', 'd1'),
          for (var i = 0; i < dueInS2; i++) card('b$i', 'd2'),
        ],
      );
      history = FakeReviewHistoryRepository();
      final cards = FlashcardRepositoryImpl(local);
      final getCards = GetAppGateCardsUseCase(
        getSpaces: GetSpacesUseCase(SpaceRepositoryImpl(local)),
        getAllDueCards: GetAllDueCardsUseCase(cards),
        spaceSettingsStore: settings,
      );
      return GateCubit(
        platform: platform,
        getCards: getCards,
        reviewCard: ReviewCardUseCase(cards, history),
        spaceSettingsStore: settings,
        syncDue: SyncAppGateDueUseCase(platform: platform, getCards: getCards),
      );
    }

    Future<void> answerAll(GateCubit cubit, ReviewRating rating) async {
      while (cubit.state.status == GateStatus.asking) {
        cubit.flip();
        await cubit.answer(rating);
      }
    }

    test('asks the chosen number of cards, then opens the app', () async {
      final cubit = await build(due: 5);
      await cubit.load();

      expect(cubit.state.status, GateStatus.asking);
      expect(cubit.state.cards, hasLength(2));
      await answerAll(cubit, ReviewRating.know);

      expect(platform.opened, ['com.instagram.android']);
      expect(history.logs, hasLength(2), reason: 'due cards: real reviews');
      expect(platform.due?.count, 3, reason: 'the lock is told what is left');
    });

    test('a wrong answer counts too: the app still opens', () async {
      final cubit = await build(due: 1);
      await cubit.load();
      await answerAll(cubit, ReviewRating.dontKnow);
      expect(platform.opened, hasLength(1));
    });

    test('asks fewer when fewer are due', () async {
      final cubit = await build(due: 1);
      await cubit.load();
      expect(cubit.state.cards, hasLength(1));
    });

    test('in all-of-today mode asks every due card', () async {
      final cubit = await build(
        due: 4,
        config: const AppGateConfig(enabled: true, mode: AppGateMode.allDue),
      );
      await cubit.load();
      expect(cubit.state.cards, hasLength(4));
      await answerAll(cubit, ReviewRating.know);
      expect(platform.due?.count, 0);
    });

    test('with all spaces, cards come from every space', () async {
      final cubit = await build(
        due: 1,
        dueInS2: 2,
        config: const AppGateConfig(enabled: true, mode: AppGateMode.allDue),
      );
      await cubit.load();
      expect(cubit.state.cards.map((c) => c.deckId).toSet(), {'d1', 'd2'});

      await answerAll(cubit, ReviewRating.know);
      // Each answer is logged under the card's own space.
      expect(
        {for (final log in history.logs) log.cardId: log.spaceId},
        {'a0': 's1', 'b0': 's2', 'b1': 's2'},
      );
    });

    test('with chosen spaces, only those', () async {
      final cubit = await build(
        due: 3,
        dueInS2: 2,
        config: const AppGateConfig(
          enabled: true,
          mode: AppGateMode.allDue,
          allSpaces: false,
          spaceIds: {'s2'},
        ),
      );
      await cubit.load();
      expect(cubit.state.cards.map((c) => c.deckId).toSet(), {'d2'});
      expect(cubit.state.cards, hasLength(2));
    });

    test('with nothing due, opens the app without asking anything', () async {
      final cubit = await build(due: 0);
      await cubit.load();
      expect(platform.opened, ['com.instagram.android']);
      expect(history.logs, isEmpty);
    });

    test('an answer needs the card turned over first', () async {
      final cubit = await build(due: 2);
      await cubit.load();
      await cubit.answer(ReviewRating.know);
      expect(history.logs, isEmpty);
      expect(cubit.state.index, 0);
    });

    test('back goes to the home screen, not into the app', () async {
      final cubit = await build(due: 2);
      await cubit.load();
      await cubit.leave();
      expect(platform.wentHome, 1);
      expect(platform.opened, isEmpty);
    });

    testWidgets('turned over, the card shows its back only', (tester) async {
      late GateCubit cubit;
      await tester.runAsync(() async {
        cubit = await build(due: 1);
        await cubit.load();
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppAccent.lavender),
          home: BlocProvider.value(value: cubit, child: const GateScreen()),
        ),
      );
      expect(find.text('front-a0'), findsOneWidget);
      expect(find.text('back-a0'), findsNothing);

      await tester.tap(find.text('front-a0'));
      await tester.pump();

      expect(find.text('back-a0'), findsOneWidget);
      expect(find.text('front-a0'), findsNothing);
    });
  });

  group('the due count', () {
    test('is not sent while the lock is off', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SpaceSettingsStore(
        await SharedPreferences.getInstance(),
      );
      final platform = FakeGatePlatform();
      final local = InMemoryLocalDataSource();
      await SyncAppGateDueUseCase(
        platform: platform,
        getCards: GetAppGateCardsUseCase(
          getSpaces: GetSpacesUseCase(SpaceRepositoryImpl(local)),
          getAllDueCards: GetAllDueCardsUseCase(FlashcardRepositoryImpl(local)),
          spaceSettingsStore: settings,
        ),
      )();
      expect(platform.due, isNull);
    });
  });

  group('the settings screen', () {
    Future<FakeGatePlatform> pump(
      WidgetTester tester, {
      AppGateStatus status = const AppGateStatus(
        accessibility: false,
        overlay: false,
      ),
      AppGateConfig config = const AppGateConfig(),
      bool supported = true,
    }) async {
      final platform = FakeGatePlatform()
        ..currentStatus = status
        ..config = config
        ..isSupported = supported;
      final past = DateTime(2026);
      // Tall enough that the whole settings list is built at once.
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppAccent.lavender),
          home: AppGateSettingsScreen(
            platform: platform,
            loadSpaces: () async => [
              LearningSpace(
                id: 's1',
                name: 'English',
                color: DeckColor.mint,
                createdAt: past,
              ),
            ],
            syncDue: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      return platform;
    }

    testWidgets('explains the accessibility service before turning on', (
      tester,
    ) async {
      final platform = await pump(tester);

      await tester.tap(find.text(AppStrings.appGateEnable));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.appGateDisclosureTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.appGateDisclosureDecline));
      await tester.pumpAndSettle();
      expect(platform.config.enabled, isFalse, reason: 'declined: stays off');

      await tester.tap(find.text(AppStrings.appGateEnable));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.appGateDisclosureAccept));
      await tester.pumpAndSettle();
      expect(platform.config.enabled, isTrue);
      expect(
        platform.config.allSpaces,
        isTrue,
        reason: 'all spaces by default',
      );
    });

    testWidgets('chosen apps are saved straight away', (tester) async {
      final platform = await pump(
        tester,
        status: const AppGateStatus(accessibility: true, overlay: true),
        config: const AppGateConfig(enabled: true),
      );

      await tester.tap(find.text('Telegram'));
      await tester.pumpAndSettle();

      expect(platform.config.packages, {'org.telegram.messenger'});
    });

    testWidgets('the free window is off until ticked', (tester) async {
      final platform = await pump(
        tester,
        status: const AppGateStatus(accessibility: true, overlay: true),
        config: const AppGateConfig(enabled: true),
      );
      expect(find.text(AppStrings.appGateGraceMinutes(5)), findsNothing);

      await tester.tap(find.text(AppStrings.appGateGrace));
      await tester.pumpAndSettle();

      expect(platform.config.graceEnabled, isTrue);
      expect(find.text(AppStrings.appGateGraceMinutes(5)), findsOneWidget);
    });

    testWidgets(
      'each missing permission has a button straight to its setting',
      (tester) async {
        final platform = await pump(tester);

        final buttons = find.text(AppStrings.appGateOpenSettings);
        expect(buttons, findsNWidgets(2));

        // Accessibility: the disclosure first, then the phone's setting.
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(AppStrings.appGateDisclosureAccept));
        await tester.pumpAndSettle();
        expect(platform.accessibilityOpened, 1);

        await tester.tap(buttons.last);
        await tester.pumpAndSettle();
        expect(platform.overlayOpened, 1);

        await tester.tap(find.text(AppStrings.appGateOpenAppInfo));
        expect(platform.appInfoOpened, 1);
      },
    );

    testWidgets('a permission already on shows no button', (tester) async {
      await pump(
        tester,
        status: const AppGateStatus(accessibility: true, overlay: true),
      );
      expect(find.text(AppStrings.appGateOpenSettings), findsNothing);
      expect(find.text(AppStrings.appGateGranted), findsNWidgets(2));
    });

    testWidgets(
      'spaces: all by default, a few chosen, the last one unticked is all',
      (tester) async {
        final platform = await pump(
          tester,
          status: const AppGateStatus(accessibility: true, overlay: true),
          config: const AppGateConfig(enabled: true),
        );
        expect(platform.config.allSpaces, isTrue);

        // Choosing particular spaces starts from untick "all".
        await tester.tap(find.text(AppStrings.appGateAllSpaces));
        await tester.pumpAndSettle();
        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(platform.config.allSpaces, isFalse);
        expect(platform.config.spaceIds, {'s1'});

        await tester.tap(find.text('English'));
        await tester.pumpAndSettle();
        expect(platform.config.allSpaces, isTrue, reason: 'never no space');
      },
    );

    testWidgets('says so on platforms other than Android', (tester) async {
      await pump(tester, supported: false);
      expect(find.text(AppStrings.appGateAndroidOnly), findsOneWidget);
      expect(find.text(AppStrings.appGateEnable), findsNothing);
    });
  });
}
