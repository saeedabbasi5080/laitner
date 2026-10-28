import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/tts/tts_service.dart';
import 'package:recall/data/datasources/auth_api_client.dart';
import 'package:recall/data/datasources/device_identity.dart';
import 'package:recall/data/datasources/http_sync_remote.dart';
import 'package:recall/data/datasources/preferences_sync_state_store.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/data/utils/card_media_store_factory.dart';
import 'package:recall/data/utils/uuid_id_generator.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/datasources/storage_setup.dart';
import 'package:recall/data/migration/review_log_migration.dart';
import 'package:recall/data/migration/space_migration.dart';
import 'package:recall/data/repositories/deck_repository_impl.dart';
import 'package:recall/data/repositories/excel_import_repository_impl.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/data/repositories/review_history_repository_impl.dart';
import 'package:recall/data/repositories/space_repository_impl.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/device_remote.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/repositories/space_repository.dart';
import 'package:recall/domain/repositories/sync_remote.dart';
import 'package:recall/domain/repositories/sync_state_store.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/delete_excel_import_usecase.dart';
import 'package:recall/domain/usecases/delete_space_usecase.dart';
import 'package:recall/domain/usecases/export_collection_backup_usecase.dart';
import 'package:recall/domain/usecases/export_deck_excel_usecase.dart';
import 'package:recall/domain/usecases/restore_collection_backup_usecase.dart';
import 'package:recall/domain/usecases/find_duplicate_card_usecase.dart';
import 'package:recall/domain/usecases/find_excel_row_duplicates_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_space_cards_usecase.dart';
import 'package:recall/domain/usecases/get_todays_mistakes_usecase.dart';
import 'package:recall/domain/usecases/run_daily_excel_feed_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/move_cards_to_deck_usecase.dart';
import 'package:recall/domain/usecases/parse_and_save_excel_import_usecase.dart';
import 'package:recall/domain/usecases/remove_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/sync_reminders_usecase.dart';
import 'package:recall/domain/usecases/sync_collection_usecase.dart';
import 'package:recall/domain/usecases/sync_excel_import_added_status_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';
import 'package:recall/domain/usecases/update_excel_row_usecase.dart';
import 'package:recall/domain/usecases/update_space_usecase.dart';
import 'package:recall/presentation/blocs/add_card/add_card_cubit.dart';
import 'package:recall/presentation/blocs/auth/auth_cubit.dart';
import 'package:recall/presentation/blocs/deck_detail/deck_detail_cubit.dart';
import 'package:recall/presentation/blocs/deck_list/deck_list_cubit.dart';
import 'package:recall/presentation/blocs/devices/active_devices_cubit.dart';
import 'package:recall/presentation/blocs/excel_library/excel_library_cubit.dart';
import 'package:recall/presentation/blocs/daily_feed/daily_feed_cubit.dart';
import 'package:recall/presentation/blocs/mistakes/mistakes_cubit.dart';
import 'package:recall/presentation/blocs/reminder/reminder_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_cubit.dart';
import 'package:recall/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:recall/presentation/blocs/sync/sync_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final localDataSource = await createLocalDataSource(prefs);
  sl.registerSingleton<LocalDataSource>(localDataSource);

  sl.registerLazySingleton<ExcelImportStore>(() => ExcelImportStore(sl()));
  sl.registerLazySingleton<SpaceSettingsStore>(() => SpaceSettingsStore(sl()));

  // Registered before the migrations below, which need it: a first run has no
  // spaces and has to mint an id for the one it creates.
  sl.registerLazySingleton<IdGenerator>(() => const UuidIdGenerator());

  // Sign-in is optional and the app works with none of this. Everything here is
  // lazy and nothing is read at start-up, so a misconfigured server address
  // costs the user a failed sign-in and nothing more — no cards, no study
  // session, no reminder.
  sl.registerLazySingleton<AuthApiClient>(() => AuthApiClient());
  sl.registerLazySingleton<AuthTokenStore>(
    () => SecureAuthTokenStore(preferences: prefs),
  );

  // The same client answers both. Devices belong to the same service and the same
  // authorization, and a second HTTP client against the same host would only be
  // another place for the base URL and the error handling to drift apart.
  sl.registerLazySingleton<DeviceRemote>(() => sl<AuthApiClient>());
  sl.registerLazySingleton<DeviceIdentity>(
    () => StoredDeviceIdentity(preferences: prefs, ids: sl()),
  );

  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(
      api: sl(),
      tokenStore: sl(),
      deviceIdentity: sl(),
      // The sync watermark belongs to an account, not to a device. Left behind on a
      // sign-out, it would make the next account's first upload skip every review
      // older than the previous account's last sync — silently, because those
      // entries look like ones the server already has.
      onSessionEnded: () => sl<SyncStateStore>().clear(),
    ),
  );
  sl.registerLazySingleton<ActiveDevicesCubit>(
    () => ActiveDevicesCubit(remote: sl(), tokenStore: sl()),
  );

  // Synchronisation. Registered but not run from anywhere yet: something has to
  // decide when, and that is the next piece rather than this one.
  sl.registerLazySingleton<SyncStateStore>(
    () => PreferencesSyncStateStore(prefs: prefs),
  );
  sl.registerLazySingleton<SyncRemote>(() => HttpSyncRemote(tokenStore: sl()));
  sl.registerLazySingleton<SyncCollectionUseCase>(
    () => SyncCollectionUseCase(
      localDataSource: sl(),
      remote: sl(),
      state: sl(),
    ),
  );

  // The sync cubit hands a removed device straight to sign-out rather than telling
  // the screen about it: the token is worth nothing at that point, and a screen
  // that had to react would be a screen that could forget to.
  sl.registerLazySingleton<SyncCubit>(
    () => SyncCubit(
      sync: sl(),
      state: sl(),
      tokenStore: sl(),
      onSignedOutElsewhere: () => sl<AuthCubit>().signOut(),
    ),
  );

  await runReviewLogMigration(localDataSource: localDataSource, prefs: prefs);
  await runSpaceMigration(
    localDataSource: localDataSource,
    idGenerator: sl(),
    prefs: prefs,
    excelImportStore: sl(),
    spaceSettingsStore: sl(),
  );

  sl.registerLazySingleton<IDeckRepository>(() => DeckRepositoryImpl(sl()));
  sl.registerLazySingleton<IFlashcardRepository>(
    () => FlashcardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ISpaceRepository>(() => SpaceRepositoryImpl(sl()));
  sl.registerLazySingleton<IReviewHistoryRepository>(
    () => ReviewHistoryRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<IExcelImportRepository>(
    () => ExcelImportRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(
    () => ExportCollectionBackupUseCase(
      localDataSource: sl(),
      excelImportStore: sl(),
      spaceSettingsStore: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => RestoreCollectionBackupUseCase(
      localDataSource: sl(),
      excelImportStore: sl(),
      spaceSettingsStore: sl(),
      prefs: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetSpacesUseCase(sl()));
  sl.registerLazySingleton(() => AddSpaceUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSpaceUseCase(sl()));
  sl.registerLazySingleton(
    () => DeleteSpaceUseCase(sl(), sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => GetDecksUseCase(sl()));
  sl.registerLazySingleton(() => GetDeckUseCase(sl()));
  sl.registerLazySingleton(() => AddDeckUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDeckUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDeckUseCase(sl(), sl()));
  sl.registerLazySingleton(() => GetCardsByDeckUseCase(sl()));
  sl.registerLazySingleton(
    () => ExportDeckExcelUseCase(
      getDeckUseCase: sl(),
      getCardsByDeckUseCase: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetDueCardsUseCase(sl()));
  sl.registerLazySingleton(
    () => GetTodaysMistakesUseCase(sl(), sl()),  );
  sl.registerLazySingleton(() => GetAllDueCardsUseCase(sl()));
  sl.registerLazySingleton(() => GetSpaceCardsUseCase(sl()));
  sl.registerLazySingleton(() => GetCardsByBoxUseCase(sl()));
  sl.registerLazySingleton(() => ReviewCardUseCase(sl(), sl()));
  sl.registerLazySingleton(() => FindDuplicateCardUseCase(sl(), sl()));
  sl.registerLazySingleton(() => AddCardUseCase(sl(), sl()));
  sl.registerLazySingleton(() => UpdateCardUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCardUseCase(sl()));
  sl.registerLazySingleton(() => MoveCardsToDeckUseCase(sl()));
  sl.registerLazySingleton(() => ParseAndSaveExcelImportUseCase(sl()));
  sl.registerLazySingleton(() => GetExcelImportsUseCase(sl()));
  sl.registerLazySingleton(() => GetExcelImportUseCase(sl()));
  sl.registerLazySingleton(() => FindExcelRowDuplicatesUseCase(sl(), sl()));
  sl.registerLazySingleton(() => AddSelectedExcelRowsUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => SyncExcelImportAddedStatusUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RemoveExcelRowsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExcelRowUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExcelImportUseCase(sl()));

  sl.registerLazySingleton(
    () => SettingsCubit(sl(), sl(), sl(), sl()),
  );

  sl.registerLazySingleton<NotificationService>(() => NotificationService());
  sl.registerLazySingleton(
    () => SyncRemindersUseCase(
      localDataSource: sl(),
      spaceSettingsStore: sl(),
      notificationService: sl(),
    ),
  );
  sl.registerFactory(
    () => ReminderCubit(notificationService: sl()),
  );
  sl.registerLazySingleton(
    () => RunDailyExcelFeedUseCase(
      localDataSource: sl(),
      spaceSettingsStore: sl(),
      excelRepository: sl(),
      addSelectedRows: sl(),
      generateId: sl<IdGenerator>().generateId,
    ),
  );

  sl.registerLazySingleton<TtsService>(() => TtsService(FlutterTts()));
  sl.registerLazySingleton<CardMediaStore>(createCardMediaStore);

  sl.registerFactory(
    () => SpaceListCubit(
      getSpacesUseCase: sl(),
      getDecksUseCase: sl(),
      getDueCardsUseCase: sl(),
      getCardsByDeckUseCase: sl(),
      addSpaceUseCase: sl(),
      updateSpaceUseCase: sl(),
      deleteSpaceUseCase: sl(),
      idGenerator: sl(),
      spaceSettingsStore: sl(),
    ),
  );

  sl.registerFactoryParam<DeckListCubit, String, void>(
    (spaceId, _) => DeckListCubit(
      spaceId: spaceId,
      getDecksUseCase: sl(),
      getDueCardsUseCase: sl(),
      getCardsByDeckUseCase: sl(),
      addDeckUseCase: sl(),
      updateDeckUseCase: sl(),
      deleteDeckUseCase: sl(),
      flashcardRepository: sl(),
      idGenerator: sl(),
      spaceSettingsStore: sl(),
    ),
  );

  sl.registerFactoryParam<DailyFeedCubit, String, void>(
    (spaceId, _) => DailyFeedCubit(
      getDecksUseCase: sl(),
      getImportsUseCase: sl(),
      runFeedUseCase: sl(),
      spaceId: spaceId,
    ),
  );

  sl.registerFactoryParam<StatisticsCubit, String, void>(
    (spaceId, _) => StatisticsCubit(sl(), sl(), spaceId, sl()),
  );

  sl.registerFactoryParam<MistakesCubit, String, void>(
    (spaceId, _) => MistakesCubit(
      getMistakesUseCase: sl(),
      getDecksUseCase: sl(),
      spaceId: spaceId,
    ),  );

  sl.registerFactoryParam<StudyCubit, StudyConfig, void>(
    (config, _) => StudyCubit(
      config: config,
      getDueCardsUseCase: sl(),
      getAllDueCardsUseCase: sl(),
      getSpaceCardsUseCase: sl(),
      getCardsByBoxUseCase: sl(),
      getCardsByDeckUseCase: sl(),
      getDecksUseCase: sl(),
      reviewCardUseCase: sl(),
      updateCardUseCase: sl(),
      deleteCardUseCase: sl(),
      onScheduleChanged: sl<SyncRemindersUseCase>().call,
    ),
  );

  sl.registerFactoryParam<AddCardCubit, String, String>(
    (deckId, spaceId) => AddCardCubit(
      deckId: deckId,
      spaceId: spaceId,
      addCardUseCase: sl(),
      addDeckUseCase: sl(),
      getDecksUseCase: sl(),
      idGenerator: sl(),
      mediaStore: sl(),
    ),
  );

  sl.registerFactoryParam<DeckDetailCubit, String, String>(
    (deckId, spaceId) => DeckDetailCubit(
      deckId: deckId,
      spaceId: spaceId,
      getDeckUseCase: sl(),
      getDecksUseCase: sl(),
      getCardsByDeckUseCase: sl(),
      getDueCardsUseCase: sl(),
      updateDeckUseCase: sl(),
      deleteDeckUseCase: sl(),
      updateCardUseCase: sl(),
      deleteCardUseCase: sl(),
      moveCardsToDeckUseCase: sl(),
      spaceSettingsStore: sl(),
    ),
  );

  sl.registerFactoryParam<ExcelLibraryCubit, String, void>(
    (spaceId, _) => ExcelLibraryCubit(
      spaceId: spaceId,
      getImportsUseCase: sl(),
      parseAndSaveUseCase: sl(),
      deleteImportUseCase: sl(),
      idGenerator: sl(),
    ),
  );
}
