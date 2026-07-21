import 'package:recall/domain/entities/deck.dart';

abstract class IDeckRepository {
  Future<List<Deck>> getAllDecks();

  Future<List<Deck>> getDecksBySpaceId(String spaceId);

  Future<Deck?> getDeckById(String id);

  Future<Deck> addDeck(Deck deck);

  Future<Deck> updateDeck(Deck deck);

  Future<void> deleteDeck(String id);
}
