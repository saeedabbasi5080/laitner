import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/core/theme/card_font_size.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyTtsLanguageKey = 'tts_language';
const _legacyRandomReviewOrderKey = 'random_review_order';
const _legacyCardFontSizeKey = 'card_font_size';
const _legacyAutoSpeakKey = 'auto_speak';

Future<void> runSpaceMigration({
  required LocalDataSource localDataSource,
  required IdGenerator idGenerator,
  required SharedPreferences prefs,
  required ExcelImportStore excelImportStore,
  required SpaceSettingsStore spaceSettingsStore,
}) async {
  if (prefs.getBool(defaultSpaceMigrationKey) == true) return;

  var spaces = await localDataSource.getAllSpaces();
  final defaultSpaceId = spaces.isNotEmpty
      ? spaces.first.id
      : idGenerator.generateId();

  if (spaces.isEmpty) {
    final defaultSpace = LearningSpace(
      id: defaultSpaceId,
      name: 'فضای من',
      color: DeckColor.lavender,
      createdAt: DateTime.now(),
      sortOrder: 0,
    );
    await localDataSource.addSpace(defaultSpace);
    spaces = [defaultSpace];
  }

  for (final deck in await localDataSource.getAllDecks()) {
    if (deck.spaceId.isEmpty) {
      await localDataSource.updateDeck(
        deck.copyWith(spaceId: defaultSpaceId),
      );
    }
  }

  final deckSpaceById = {
    for (final deck in await localDataSource.getAllDecks())
      deck.id: deck.spaceId,
  };

  final reviewLogs = await localDataSource.getAllReviewLogs();
  final migratedLogs = reviewLogs
      .map(
        (log) => log.spaceId.isNotEmpty
            ? log
            : ReviewLog(
                id: log.id,
                spaceId: deckSpaceById[log.deckId] ?? defaultSpaceId,
                cardId: log.cardId,
                deckId: log.deckId,
                rating: log.rating,
                boxBefore: log.boxBefore,
                boxAfter: log.boxAfter,
                reviewedAt: log.reviewedAt,
              ),
      )
      .toList();
  if (reviewLogs.any((log) => log.spaceId.isEmpty)) {
    await localDataSource.replaceReviewLogs(migratedLogs);
  }

  final excelImports = await excelImportStore.getAll();
  if (excelImports.any((import) => import.spaceId.isEmpty)) {
    await excelImportStore.replaceAll(
      excelImports
          .map(
            (import) => import.spaceId.isNotEmpty
                ? import
                : import.copyWith(spaceId: defaultSpaceId),
          )
          .toList(),
    );
  }

  final existingSettings = await spaceSettingsStore.load(defaultSpaceId);
  final hasLegacySettings = prefs.containsKey(_legacyTtsLanguageKey) ||
      prefs.containsKey(_legacyRandomReviewOrderKey) ||
      prefs.containsKey(_legacyCardFontSizeKey) ||
      prefs.containsKey(_legacyAutoSpeakKey);
  if (hasLegacySettings && existingSettings == const SpaceSettingsData()) {
    await spaceSettingsStore.save(
      defaultSpaceId,
      SpaceSettingsData(
        ttsLanguage: TtsLanguage.fromCode(
          prefs.getString(_legacyTtsLanguageKey),
        ),
        randomReviewOrder: prefs.getBool(_legacyRandomReviewOrderKey) ?? false,
        cardFontSize: CardFontSize.fromName(
          prefs.getString(_legacyCardFontSizeKey),
        ),
        autoSpeak: prefs.getBool(_legacyAutoSpeakKey) ?? false,
      ),
    );
  }

  await prefs.setBool(defaultSpaceMigrationKey, true);
}
