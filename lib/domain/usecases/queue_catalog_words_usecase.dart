import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/excel_import_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/domain/usecases/add_catalog_words_usecase.dart';
import 'package:recall/domain/usecases/catalog_cards.dart';
import 'package:recall/domain/usecases/run_daily_excel_feed_usecase.dart';

class CatalogQueueResult {
  const CatalogQueueResult({
    required this.deck,
    required this.queued,
    required this.skipped,
    required this.addedToday,
    required this.dailyLimit,
  });

  final Deck deck;

  /// Words put in the queue, today's share included.
  final int queued;

  /// Words the space already had, left out of the queue.
  final int skipped;

  /// How many of them entered the deck right away.
  final int addedToday;
  final int dailyLimit;
}

/// The gradual way in: a ready-made list becomes a file in the space's Excel
/// library, and the deck's daily feed releases it [dailyLimit] cards a day.
///
/// A deck with a feed already gets the list at the end of that feed's queue,
/// and the feed takes the new daily number; a deck without one gets a new
/// feed. Today's share is released at once, unless the deck's feed already ran
/// today, so the learner sees the first cards without waiting for tomorrow.
///
/// Words already in the space are left out of the file, for the same reason the
/// direct add skips them.
class QueueCatalogWordsUseCase {
  QueueCatalogWordsUseCase({
    required IDeckRepository decks,
    required IFlashcardRepository cards,
    required IExcelImportRepository library,
    required SpaceSettingsStore settings,
    required RunDailyExcelFeedUseCase runFeed,
    required IdGenerator ids,
    DateTime Function()? clock,
  })  : _decks = decks,
        _cards = cards,
        _library = library,
        _settings = settings,
        _runFeed = runFeed,
        _ids = ids,
        _clock = clock ?? DateTime.now;

  final IDeckRepository _decks;
  final IFlashcardRepository _cards;
  final IExcelImportRepository _library;
  final SpaceSettingsStore _settings;
  final RunDailyExcelFeedUseCase _runFeed;
  final IdGenerator _ids;
  final DateTime Function() _clock;

  Future<CatalogQueueResult> call({
    required CatalogWordList list,
    required CatalogTarget target,
    required int dailyLimit,
    CatalogCardOptions options = const CatalogCardOptions(),
  }) async {
    final now = _clock();
    final limit = dailyLimit.clamp(DailyExcelFeedSettings.minDailyLimit, DailyExcelFeedSettings.maxDailyLimit);
    final deck = await _deckFor(target, list, now);

    final known = {
      for (final card in await _cards.getCardsBySpaceId(deck.spaceId)) AddCatalogWordsUseCase.key(card.front, card.back),
    };
    final rows = <ExcelImportRow>[];
    var skipped = 0;
    for (final row in catalogCardRows(list.lessons, options)) {
      if (!known.add(AddCatalogWordsUseCase.key(row.front, row.back))) {
        skipped++;
        continue;
      }
      rows.add(ExcelImportRow(id: _ids.generateId(), front: row.front, back: row.back, tags: row.tags));
    }
    if (rows.isEmpty) {
      return CatalogQueueResult(deck: deck, queued: 0, skipped: skipped, addedToday: 0, dailyLimit: limit);
    }

    final file = await _library.saveImport(ExcelImport(
      id: _ids.generateId(),
      spaceId: deck.spaceId,
      fileName: list.node.title,
      createdAt: now,
      rows: rows,
    ));

    final settings = await _settings.load(deck.spaceId);
    final existing = settings.dailyExcelFeeds.where((feed) => feed.deckId == deck.id).firstOrNull;
    final feed = (existing ?? DailyExcelFeedSettings(id: _ids.generateId(), deckId: deck.id)).copyWith(
      enabled: true,
      importIds: [...?existing?.importIds, file.id],
      dailyLimit: limit,
    );
    await _settings.save(deck.spaceId, settings.withFeed(feed));

    final run = await _runFeed.runForFeed(spaceId: deck.spaceId, feedId: feed.id, now: now);
    return CatalogQueueResult(
      deck: deck,
      queued: rows.length,
      skipped: skipped,
      addedToday: run?.addedCount ?? 0,
      dailyLimit: limit,
    );
  }

  Future<Deck> _deckFor(CatalogTarget target, CatalogWordList list, DateTime now) async {
    switch (target) {
      case ExistingDeckTarget(:final deckId):
        final found = await _decks.getDeckById(deckId);
        if (found == null) throw const CatalogDeckNotFoundException();
        return found;
      case NewDeckTarget(:final spaceId, :final name, :final color):
        final trimmed = name.trim();
        return _decks.addDeck(Deck(
          id: _ids.generateId(),
          spaceId: spaceId,
          name: trimmed.isEmpty ? list.node.title : trimmed,
          color: color,
          createdAt: now,
        ));
    }
  }
}
