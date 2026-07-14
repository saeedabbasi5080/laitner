import 'package:isar/isar.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/seed_data.dart';
import 'package:recall/data/models/deck_model.dart';
import 'package:recall/data/models/flashcard_model.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:uuid/uuid.dart';

class IsarLocalDataSource implements LocalDataSource {
  IsarLocalDataSource(this._isar);

  final Isar _isar;
  final _uuid = const Uuid();

  @override
  Future<void> seedIfEmpty() async {
    final count = await _isar.deckModels.count();
    if (count > 0) return;

    final sample = SeedData.sample(DateTime.now());

    await _isar.writeTxn(() async {
      await _isar.deckModels.putAll(
        sample.decks.map(DeckModelMapper.fromEntity).toList(),
      );
      await _isar.flashcardModels.putAll(
        sample.cards.map(FlashcardModelMapper.fromEntity).toList(),
      );
    });
  }

  @override
  Future<List<Deck>> getAllDecks() async {
    final models =
        await _isar.deckModels.where().sortByCreatedAtDesc().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Deck?> getDeckById(String id) async {
    final model = await _isar.deckModels.filter().uuidEqualTo(id).findFirst();
    return model?.toEntity();
  }

  @override
  Future<Deck> addDeck(Deck deck) async {
    final model = DeckModelMapper.fromEntity(deck);
    await _isar.writeTxn(() async {
      await _isar.deckModels.put(model);
    });
    return model.toEntity();
  }

  @override
  Future<Deck> updateDeck(Deck deck) async {
    final existing =
        await _isar.deckModels.filter().uuidEqualTo(deck.id).findFirst();
    final model = DeckModelMapper.fromEntity(deck);
    if (existing != null) {
      model.isarId = existing.isarId;
    }
    await _isar.writeTxn(() async {
      await _isar.deckModels.put(model);
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteDeck(String id) async {
    await _isar.writeTxn(() async {
      final deck = await _isar.deckModels.filter().uuidEqualTo(id).findFirst();
      if (deck != null) {
        await _isar.deckModels.delete(deck.isarId);
      }
      final cards =
          await _isar.flashcardModels.filter().deckIdEqualTo(id).findAll();
      await _isar.flashcardModels
          .deleteAll(cards.map((c) => c.isarId).toList());
    });
  }

  @override
  Future<List<Flashcard>> getAllCards() async {
    final models = await _isar.flashcardModels.where().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Flashcard>> getCardsByDeckId(String deckId) async {
    final models =
        await _isar.flashcardModels.filter().deckIdEqualTo(deckId).findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<Flashcard?> getCardById(String id) async {
    final model =
        await _isar.flashcardModels.filter().uuidEqualTo(id).findFirst();
    return model?.toEntity();
  }

  @override
  Future<Flashcard> addCard(Flashcard card) async {
    final model = FlashcardModelMapper.fromEntity(card);
    await _isar.writeTxn(() async {
      await _isar.flashcardModels.put(model);
    });
    return model.toEntity();
  }

  @override
  Future<Flashcard> updateCard(Flashcard card) async {
    final existing =
        await _isar.flashcardModels.filter().uuidEqualTo(card.id).findFirst();
    final model = FlashcardModelMapper.fromEntity(card);
    if (existing != null) {
      model.isarId = existing.isarId;
    }
    await _isar.writeTxn(() async {
      await _isar.flashcardModels.put(model);
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteCard(String id) async {
    await _isar.writeTxn(() async {
      final card =
          await _isar.flashcardModels.filter().uuidEqualTo(id).findFirst();
      if (card != null) {
        await _isar.flashcardModels.delete(card.isarId);
      }
    });
  }

  @override
  String generateId() => _uuid.v4();
}
