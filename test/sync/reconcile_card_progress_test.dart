import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/reconcile_card_progress.dart';

void main() {
  final t1 = DateTime(2026, 1, 1, 9);
  final t2 = DateTime(2026, 1, 2, 9);
  final t3 = DateTime(2026, 1, 3, 9);

  Flashcard card(
    String id, {
    required int box,
    DateTime? lastReviewed,
    String deckId = 'd1',
  }) {
    return Flashcard(
      id: id,
      deckId: deckId,
      front: 'رو',
      back: 'پشت',
      box: box,
      lastReviewed: lastReviewed,
      createdAt: DateTime(2026),
    );
  }

  ReviewLog log(
    String id, {
    required String cardId,
    required int boxAfter,
    required DateTime at,
  }) {
    return ReviewLog(
      id: id,
      spaceId: 's1',
      cardId: cardId,
      deckId: 'd1',
      rating: ReviewRating.know,
      boxBefore: boxAfter - 1,
      boxAfter: boxAfter,
      reviewedAt: at,
    );
  }

  group('a card that has fallen behind its history', () {
    test('is moved to the box the newest review produced', () {
      // The failure this prevents: a device that has been offline pushes a
      // week-old box, and without this the card slides back through the boxes
      // with no sign that the reviews ever happened.
      final cards = [card('c1', box: 1, lastReviewed: t1)];
      final logs = [
        log('l1', cardId: 'c1', boxAfter: 2, at: t1),
        log('l2', cardId: 'c1', boxAfter: 5, at: t3),
      ];

      final result = reconcileCardProgress(cards: cards, reviewLogs: logs);

      expect(result.single.box, 5);
    });

    test('takes its date from the newest review', () {
      final cards = [card('c1', box: 1, lastReviewed: t1)];
      final logs = [
        log('l1', cardId: 'c1', boxAfter: 2, at: t1),
        log('l2', cardId: 'c1', boxAfter: 5, at: t3),
      ];

      final result = reconcileCardProgress(cards: cards, reviewLogs: logs);

      expect(result.single.lastReviewed, t3);
    });

    test('is corrected even when it claims a box no review ever produced', () {
      final cards = [card('c1', box: 8, lastReviewed: t3)];
      final logs = [log('l1', cardId: 'c1', boxAfter: 2, at: t1)];

      final result = reconcileCardProgress(cards: cards, reviewLogs: logs);

      expect(result.single.box, 2);
      expect(result.single.lastReviewed, t1);
    });
  });

  group('the newest review decides, not the order of the list', () {
    test('works when the history arrives newest first', () {
      final cards = [card('c1', box: 1)];
      final logs = [
        log('l2', cardId: 'c1', boxAfter: 5, at: t3),
        log('l1', cardId: 'c1', boxAfter: 2, at: t1),
      ];

      expect(reconcileCardProgress(cards: cards, reviewLogs: logs).single.box, 5);
    });

    test('breaks a tie by id, so the result never depends on arrival order', () {
      // Two entries can share a timestamp: the app's clock has millisecond
      // resolution on some platforms. A rebuild whose answer changed between runs
      // would be a cache that disagreed with itself.
      final cards = [card('c1', box: 1)];
      final forward = [
        log('aaa', cardId: 'c1', boxAfter: 2, at: t2),
        log('bbb', cardId: 'c1', boxAfter: 7, at: t2),
      ];
      final backward = forward.reversed.toList();

      final a = reconcileCardProgress(cards: cards, reviewLogs: forward).single.box;
      final b = reconcileCardProgress(cards: cards, reviewLogs: backward).single.box;

      expect(a, b);
      expect(a, 7); // the greater id wins
    });
  });

  group('what is deliberately left alone', () {
    test('a card with no history keeps the box it has', () {
      // There is nothing to rebuild such a card from, and treating "no history"
      // as "box 1" would reset every card somebody had created but not studied.
      final cards = [card('c-fresh', box: 1), card('c-old', box: 6, lastReviewed: t2)];
      final logs = [log('l1', cardId: 'c-old', boxAfter: 6, at: t2)];

      final result = reconcileCardProgress(cards: cards, reviewLogs: logs);

      expect(result.firstWhere((c) => c.id == 'c-fresh').box, 1);
    });

    test('a card already in step is not rewritten', () {
      final cards = [card('c1', box: 2, lastReviewed: t1)];
      final logs = [log('l1', cardId: 'c1', boxAfter: 2, at: t1)];

      final result = reconcileCardProgress(cards: cards, reviewLogs: logs);

      // Identity, not equality: the common case allocates nothing.
      expect(identical(result, cards), isTrue);
    });

    test('an empty history returns the cards unchanged', () {
      final cards = [card('c1', box: 3)];

      expect(identical(reconcileCardProgress(cards: cards, reviewLogs: []), cards), isTrue);
    });

    test('no cards is no work', () {
      expect(
        reconcileCardProgress(cards: [], reviewLogs: [log('l1', cardId: 'c1', boxAfter: 2, at: t1)]),
        isEmpty,
      );
    });
  });

  group('several cards at once', () {
    test('each is corrected against its own history', () {
      final cards = [
        card('c1', box: 1),
        card('c2', box: 1),
        card('c3', box: 4, lastReviewed: t2),
      ];
      final logs = [
        log('l1', cardId: 'c1', boxAfter: 2, at: t1),
        log('l2', cardId: 'c2', boxAfter: 6, at: t3),
        log('l3', cardId: 'c2', boxAfter: 7, at: t3),
        log('l4', cardId: 'c3', boxAfter: 4, at: t2),
      ];

      final byId = {
        for (final c in reconcileCardProgress(cards: cards, reviewLogs: logs)) c.id: c,
      };

      expect(byId['c1']!.box, 2);
      expect(byId['c2']!.box, 7);
      expect(byId['c3']!.box, 4);
      expect(byId['c3']!.lastReviewed, t2);
    });
  });
}
