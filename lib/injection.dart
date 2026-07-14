import 'package:get_it/get_it.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/storage_setup.dart';
import 'package:recall/data/repositories/deck_repository_impl.dart';
import 'package:recall/data/repositories/excel_import_repository_impl.dart';
import 'package:recall/data/repositories/flashcard_repository_impl.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/add_card_usecase.dart';
import 'package:recall/domain/usecases/add_deck_usecase.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/domain/usecases/delete_card_usecase.dart';
import 'package:recall/domain/usecases/delete_deck_usecase.dart';
import 'package:recall/domain/usecases/delete_excel_import_usecase.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/parse_and_save_excel_import_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/sync_excel_import_added_status_usecase.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/domain/usecases/update_deck_usecase.dart';
import 'package:recall/presentation/blocs/add_card/add_card_cubit.dart';
import 'package:recall/presentation/blocs/deck_detail/deck_detail_cubit.dart';
import 'package:recall/presentation/blocs/deck_list/deck_list_cubit.dart';
import 'package:recall/presentation/blocs/excel_import_detail/excel_import_detail_cubit.dart';
import 'package:recall/presentation/blocs/excel_library/excel_library_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  final localDataSource = await createLocalDataSource(prefs);
  sl.registerSingleton<LocalDataSource>(localDataSource);

  sl.registerLazySingleton<IDeckRepository>(
    () => DeckRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<IFlashcardRepository>(
    () => FlashcardRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ExcelImportStore>(() => ExcelImportStore(sl()));
  sl.registerLazySingleton<IExcelImportRepository>(
    () => ExcelImportRepositoryImpl(sl()),
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
  sl.registerLazySingleton(() => ReviewCardUseCase(sl()));
  sl.registerLazySingleton(() => AddCardUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCardUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCardUseCase(sl()));
  sl.registerLazySingleton(() => ParseAndSaveExcelImportUseCase(sl()));
  sl.registerLazySingleton(() => GetExcelImportsUseCase(sl()));
  sl.registerLazySingleton(() => GetExcelImportUseCase(sl()));
  sl.registerLazySingleton(() => AddSelectedExcelRowsUseCase(sl(), sl()));
  sl.registerLazySingleton(() => SyncExcelImportAddedStatusUseCase(sl(), sl()));
  sl.registerLazySingleton(() => DeleteExcelImportUseCase(sl()));

  sl.registerLazySingleton(() => SettingsCubit(sl()));

  sl.registerFactory(() => DeckListCubit(
        getDecksUseCase: sl(),
        getDueCardsUseCase: sl(),
        getCardsByDeckUseCase: sl(),
        addDeckUseCase: sl(),
        updateDeckUseCase: sl(),
        deleteDeckUseCase: sl(),
        flashcardRepository: sl(),
        localDataSource: sl(),
      ));

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

  sl.registerFactoryParam<AddCardCubit, String, void>(
    (deckId, _) => AddCardCubit(
      deckId: deckId,
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

  sl.registerFactory(() => ExcelLibraryCubit(
        getImportsUseCase: sl(),
        parseAndSaveUseCase: sl(),
        deleteImportUseCase: sl(),
        localDataSource: sl(),
      ));

  sl.registerFactoryParam<ExcelImportDetailCubit, String, String?>(
    (importId, initialDeckId) => ExcelImportDetailCubit(
      importId: importId,
      initialDeckId: initialDeckId,
      getImportUseCase: sl(),
      getDecksUseCase: sl(),
      addSelectedRowsUseCase: sl(),
      syncAddedStatusUseCase: sl(),
      deleteImportUseCase: sl(),
      localDataSource: sl(),
    ),
  );

  await sl<LocalDataSource>().seedIfEmpty();
}
