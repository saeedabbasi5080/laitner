import 'package:isar/isar.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/models/deck_model.dart';
import 'package:recall/data/models/flashcard_model.dart';
import 'package:recall/data/models/space_model.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:uuid/uuid.dart';

class IsarLocalDataSource implements LocalDataSource {
  IsarLocalDataSource(this._isar);

  final Isar _isar;
  final _uuid = const Uuid();

  @override
  Future<List<LearningSpace>> getAllSpaces() async {
    final models = await _isar.spaceModels.where().findAll();
    models.sort((a, b) {
      final orderCompare = a.sortOrder.compareTo(b.sortOrder);
      if (orderCompare != 0) return orderCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<LearningSpace?> getSpaceById(String id) async {
    final model =
        await _isar.spaceModels.filter().uuidEqualTo(id).findFirst();
    return model?.toEntity();
  }

  @override
  Future<int> getSpaceCount() async => _isar.spaceModels.count();

  @override
  Future<LearningSpace> addSpace(LearningSpace space) async {
    final model = SpaceModelMapper.fromEntity(space);
    await _isar.writeTxn(() async {
      await _isar.spaceModels.put(model);
    });
    return model.toEntity();
  }

  @override
  Future<LearningSpace> updateSpace(LearningSpace space) async {
    final existing =
        await _isar.spaceModels.filter().uuidEqualTo(space.id).findFirst();
    final model = SpaceModelMapper.fromEntity(space);
    if (existing != null) {
      model.isarId = existing.isarId;
    }
    await _isar.writeTxn(() async {
      await _isar.spaceModels.put(model);
    });
    return model.toEntity();
  }

  @override
  Future<void> deleteSpace(String id) async {
    final decks =
        await _isar.deckModels.filter().spaceIdEqualTo(id).findAll();
    for (final deck in decks) {
      await deleteDeck(deck.uuid);
    }
    await _isar.writeTxn(() async {
      final space =
          await _isar.spaceModels.filter().uuidEqualTo(id).findFirst();
      if (space != null) {
        await _isar.spaceModels.delete(space.isarId);
      }
    });
  }

  @override
  Future<List<Deck>> getAllDecks() async {
    final models =
        await _isar.deckModels.where().sortByCreatedAtDesc().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<Deck>> getDecksBySpaceId(String spaceId) async {
    final models = await _isar.deckModels
        .filter()
        .spaceIdEqualTo(spaceId)
        .sortByCreatedAtDesc()
        .findAll();
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
