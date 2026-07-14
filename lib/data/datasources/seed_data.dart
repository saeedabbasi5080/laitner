import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';

class SeedData {
  static ({List<Deck> decks, List<Flashcard> cards}) sample(DateTime now) {
    final decks = [
      Deck(
        id: 'd1',
        name: 'واژگان انگلیسی',
        color: DeckColor.lavender,
        createdAt: now,
      ),
      Deck(
        id: 'd2',
        name: 'مصاحبه فنی',
        color: DeckColor.mint,
        createdAt: now,
      ),
      Deck(
        id: 'd3',
        name: 'اسپانیایی مقدماتی',
        color: DeckColor.peach,
        createdAt: now,
      ),
    ];

    final cards = [
      Flashcard(
        id: 'c1',
        deckId: 'd1',
        front: 'Ephemeral',
        back: 'Lasting for a very short time.',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c2',
        deckId: 'd1',
        front: 'Ubiquitous',
        back: 'Present, appearing, or found everywhere.',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c3',
        deckId: 'd1',
        front: 'Serendipity',
        back: 'Finding something good without looking for it.',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c4',
        deckId: 'd2',
        front: 'Big-O of binary search?',
        back: 'O(log n)',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c5',
        deckId: 'd2',
        front: 'What is a closure?',
        back: 'A function that captures variables from its lexical scope.',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c6',
        deckId: 'd3',
        front: 'Hello',
        back: 'Hola',
        box: 1,
        createdAt: now,
      ),
      Flashcard(
        id: 'c7',
        deckId: 'd3',
        front: 'Thank you',
        back: 'Gracias',
        box: 1,
        createdAt: now,
      ),
    ];

    return (decks: decks, cards: cards);
  }
}
