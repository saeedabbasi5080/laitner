import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/domain/usecases/catalog_cards.dart';

/// Where the words of a ready-made list go.
sealed class CatalogTarget {
  const CatalogTarget();
}

class ExistingDeckTarget extends CatalogTarget {
  const ExistingDeckTarget(this.deckId);

  final String deckId;
}

class NewDeckTarget extends CatalogTarget {
  const NewDeckTarget({required this.spaceId, required this.name, required this.color});

  final String spaceId;
  final String name;
  final DeckColor color;
}

class CatalogAddResult {
  const CatalogAddResult({required this.deck, required this.added, required this.skipped});

  final Deck deck;
  final int added;

  /// Words the space already had, front and back alike, which were not added again.
  final int skipped;
}

class CatalogDeckNotFoundException implements Exception {
  const CatalogDeckNotFoundException();
}

/// Turns a ready-made list into cards in a deck, new or existing.
///
/// New cards start in the first house, like any card the user writes. A word
/// already anywhere in the deck's space with the same front and back is
/// skipped: a space is one learning environment, and adding a course, then one
/// of its lessons into another deck by mistake, should not double the work.
class AddCatalogWordsUseCase {
  AddCatalogWordsUseCase(this._decks, this._cards, this._ids, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final IDeckRepository _decks;
  final IFlashcardRepository _cards;
  final IdGenerator _ids;
  final DateTime Function() _clock;

  Future<CatalogAddResult> call({
    required CatalogWordList list,
    required CatalogTarget target,
    CatalogCardOptions options = const CatalogCardOptions(),
  }) async {
    final now = _clock();
    final Deck deck;
    switch (target) {
      case ExistingDeckTarget(:final deckId):
        final found = await _decks.getDeckById(deckId);
        if (found == null) throw const CatalogDeckNotFoundException();
        deck = found;
      case NewDeckTarget(:final spaceId, :final name, :final color):
        final trimmed = name.trim();
        deck = await _decks.addDeck(Deck(
          id: _ids.generateId(),
          spaceId: spaceId,
          name: trimmed.isEmpty ? list.node.title : trimmed,
          color: color,
          createdAt: now,
        ));
    }

    final existing = {
      for (final card in await _cards.getCardsBySpaceId(deck.spaceId)) key(card.front, card.back),
    };
    var added = 0;
    var skipped = 0;
    for (final row in catalogCardRows(list.lessons, options)) {
      if (!existing.add(key(row.front, row.back))) {
        skipped++;
        continue;
      }
      await _cards.addCard(Flashcard(
        id: _ids.generateId(),
        deckId: deck.id,
        front: row.front,
        back: row.back,
        tags: row.tags,
        box: 1,
        createdAt: now,
      ));
      added++;
    }
    return CatalogAddResult(deck: deck, added: added, skipped: skipped);
  }

  /// How two cards are judged the same: front and back, ignoring case and the
  /// spaces around them.
  static String key(String front, String back) => '${front.trim().toLowerCase()}\u0000${back.trim().toLowerCase()}';
}
