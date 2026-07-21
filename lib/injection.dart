import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';
import 'package:recall/core/tts/tts_service.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/datasources/storage_setup.dart';
import 'package:recall/data/migration/space_migration.dart';
import 'package:recall/data/repositories/deck_repository_impl.dart';
import 'package:recall/data/repositories/excel_import_repository_impl.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/data/repositories/review_history_repository_impl.dart';
import 'package:recall/data/repositories/space_repository_impl.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/repositories/space_repository.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/delete_excel_import_usecase.dart';
import 'package:recall/domain/usecases/delete_space_usecase.dart';
import 'package:recall/domain/usecases/find_duplicate_card_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/parse_and_save_excel_import_usecase.dart';
import 'package:recall/domain/usecases/remove_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/sync_excel_import_added_status_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';
import 'package:recall/domain/usecases/update_space_usecase.dart';
import 'package:recall/presentation/blocs/add_card/add_card_cubit.dart';
import 'package:recall/presentation/blocs/deck_detail/deck_detail_cubit.dart';
import 'package:recall/presentation/blocs/deck_list/deck_list_cubit.dart';
import 'package:recall/presentation/blocs/excel_library/excel_library_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_cubit.dart';
import 'package:recall/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final localDataSource = await createLocalDataSource(prefs);
  sl.registerSingleton<LocalDataSource>(localDataSource);

  sl.registerLazySingleton<ReviewHistoryStore>(() => ReviewHistoryStore(sl()));
  sl.registerLazySingleton<ExcelImportStore>(() => ExcelImportStore(sl()));
  sl.registerLazySingleton<SpaceSettingsStore>(() => SpaceSettingsStore(sl()));

  await runSpaceMigration(
    localDataSource: localDataSource,
    prefs: prefs,
    reviewHistoryStore: sl(),
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

  sl.registerLazySingleton(() => GetSpacesUseCase(sl()));
  sl.registerLazySingleton(() => AddSpaceUseCase(sl()));
  sl.registerLazySingleton(() => UpdateSpaceUseCase(sl()));
  sl.registerLazySingleton(
    () => DeleteSpaceUseCase(sl(), sl(), sl(), sl()),
  );
  sl.registerLazySingleton(() => GetDecksUseCase(sl()));
  sl.registerLazySingleton(() => GetDeckUseCase(sl()));
  sl.registerLazySingleton(() => AddDeckUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDeckUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDeckUseCase(sl()));
  sl.registerLazySingleton(() => GetCardsByDeckUseCase(sl()));
  sl.registerLazySingleton(() => GetDueCardsUseCase(sl()));
  sl.registerLazySingleton(() => GetAllDueCardsUseCase(sl()));
  sl.registerLazySingleton(() => GetCardsByBoxUseCase(sl()));
  sl.registerLazySingleton(() => ReviewCardUseCase(sl(), sl()));
  sl.registerLazySingleton(() => FindDuplicateCardUseCase(sl(), sl()));
  sl.registerLazySingleton(() => AddCardUseCase(sl(), sl()));
  sl.registerLazySingleton(() => UpdateCardUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCardUseCase(sl()));
  sl.registerLazySingleton(() => ParseAndSaveExcelImportUseCase(sl()));
  sl.registerLazySingleton(() => GetExcelImportsUseCase(sl()));
  sl.registerLazySingleton(() => GetExcelImportUseCase(sl()));
  sl.registerLazySingleton(() => AddSelectedExcelRowsUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(() => SyncExcelImportAddedStatusUseCase(sl(), sl()));
  sl.registerLazySingleton(() => RemoveExcelRowsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExcelImportUseCase(sl()));

  sl.registerLazySingleton(() => SettingsCubit(sl(), sl()));

  sl.registerLazySingleton<TtsService>(() => TtsService(FlutterTts()));

  sl.registerFactory(
    () => SpaceListCubit(
      getSpacesUseCase: sl(),
      getDecksUseCase: sl(),
      getDueCardsUseCase: sl(),
      getCardsByDeckUseCase: sl(),
      addSpaceUseCase: sl(),
      updateSpaceUseCase: sl(),
      deleteSpaceUseCase: sl(),
      localDataSource: sl(),
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
      localDataSource: sl(),
    ),
  );

  sl.registerFactoryParam<StatisticsCubit, String, void>(
    (spaceId, _) => StatisticsCubit(sl(), sl(), spaceId),
  );

  sl.registerFactoryParam<StudyCubit, StudyConfig, void>(
    (config, _) => StudyCubit(
      config: config,
      getDueCardsUseCase: sl(),
      getAllDueCardsUseCase: sl(),
      getCardsByBoxUseCase: sl(),
      reviewCardUseCase: sl(),
      updateCardUseCase: sl(),
      deleteCardUseCase: sl(),
    ),
  );

  sl.registerFactoryParam<AddCardCubit, String, String>(
    (deckId, spaceId) => AddCardCubit(
      deckId: deckId,
      spaceId: spaceId,
      addCardUseCase: sl(),
      localDataSource: sl(),
    ),
  );

  sl.registerFactoryParam<DeckDetailCubit, String, void>(
    (deckId, _) => DeckDetailCubit(
      deckId: deckId,
      getDeckUseCase: sl(),
      getCardsByDeckUseCase: sl(),
      getDueCardsUseCase: sl(),
      updateDeckUseCase: sl(),
      deleteDeckUseCase: sl(),
      updateCardUseCase: sl(),
      deleteCardUseCase: sl(),
    ),
  );

  sl.registerFactoryParam<ExcelLibraryCubit, String, void>(
    (spaceId, _) => ExcelLibraryCubit(
      spaceId: spaceId,
      getImportsUseCase: sl(),
      parseAndSaveUseCase: sl(),
      deleteImportUseCase: sl(),
      localDataSource: sl(),
    ),
  );
}
