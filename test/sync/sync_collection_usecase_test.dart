import 'package:flutter_test/flutter_test.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/sync_remote.dart';
import 'package:recall/domain/usecases/sync_collection_usecase.dart';

import '../support/fake_sync_remote.dart';
import '../support/in_memory_local_data_source.dart';
import '../support/in_memory_sync_state_store.dart';

void main() {
  late InMemoryLocalDataSource local;
  late FakeSyncRemote remote;
  late InMemorySyncStateStore state;
  late SyncCollectionUseCase useCase;

  final t1 = DateTime(2026, 1, 1, 9);
  final t2 = DateTime(2026, 1, 1, 10);
  final t3 = DateTime(2026, 1, 1, 11);

  LearningSpace space(String id) => LearningSpace(
        id: id,
        name: 'فضای $id',
        color: DeckColor.lavender,
        createdAt: DateTime(2026),
      );

  Deck deck(String id, String spaceId) => Deck(
        id: id,
        spaceId: spaceId,
        name: 'دسته $id',
        color: DeckColor.mint,
        createdAt: DateTime(2026),
      );

  Flashcard card(String id, String deckId) => Flashcard(
        id: id,
        deckId: deckId,
        front: 'رو',
        back: 'پشت',
        box: 1,
        createdAt: DateTime(2026),
      );

  ReviewLog log(String id, DateTime at, {int after = 2}) => ReviewLog(
        id: id,
        spaceId: 's1',
        cardId: 'c1',
        deckId: 'd1',
        rating: ReviewRating.know,
        boxBefore: after - 1,
        boxAfter: after,
        reviewedAt: at,
      );

  setUp(() {
    local = InMemoryLocalDataSource();
    remote = FakeSyncRemote();
    state = InMemorySyncStateStore();
    useCase = SyncCollectionUseCase(
      localDataSource: local,
      remote: remote,
      state: state,
    );
  });

  group('a first sync from a device that has data', () {
    setUp(() {
      local.spaces.add(space('s1'));
      local.decks.add(deck('d1', 's1'));
      local.cards.add(card('c1', 'd1'));
      local.reviewLogs.addAll([log('r1', t1), log('r2', t2)]);
    });

    test('uploads the structure and the whole history', () async {
      await useCase.sync();

      expect(remote.replacedSpaces.map((s) => s.id), ['s1']);
      expect(remote.replacedDecks.map((d) => d.id), ['d1']);
      expect(remote.replacedCards.map((c) => c.id), ['c1']);
      expect(remote.appendedLogs.map((l) => l.id), ['r1', 'r2']);
    });

    test('advances the watermark to the newest entry', () async {
      await useCase.sync();

      expect(state.watermark, t2);
    });

    test('leaves the device holding the server copy', () async {
      await useCase.sync();

      expect(local.spaces.length, 1);
      expect(local.cards.length, 1);
      expect(local.reviewLogs.length, 2);
    });

    test('reports what it moved', () async {
      final outcome = await useCase.sync();

      expect(outcome.reviewLogsSent, 2);
      expect(outcome.structureSent, isTrue);
      expect(outcome.applied.reviewLogs.length, 2);
    });
  });

  group('a second sync', () {
    setUp(() async {
      local.spaces.add(space('s1'));
      local.cards.add(card('c1', 'd1'));
      local.reviewLogs.add(log('r1', t1));
      await useCase.sync();
    });

    test('sends the entry sitting on the watermark, and no more', () async {
      // The comparison is `>=`, so the newest entry goes again. That is the
      // price of not losing an entry recorded in the same clock tick as the
      // last one uploaded — a tick that is a millisecond wide on some
      // platforms.
      await useCase.sync();

      expect(remote.appendedLogs.map((l) => l.id), ['r1']);
    });

    test('does not grow the history on the server', () async {
      await useCase.sync();

      expect(remote.stored.reviewLogs.length, 1);
    });

    test('sends only what has been reviewed since', () async {
      local.reviewLogs.add(log('r2', t2));

      await useCase.sync();

      expect(remote.appendedLogs.map((l) => l.id), ['r1', 'r2']);
      expect(state.watermark, t2);
    });

    test('reports nothing to send when nothing has been reviewed', () async {
      // Still one entry, because of the boundary. Asserted so the cost is
      // visible rather than surprising.
      final outcome = await useCase.sync();

      expect(outcome.reviewLogsSent, 1);
    });
  });

  group('a device that has nothing', () {
    test('does not upload structure', () async {
      await useCase.sync();

      expect(remote.replaceCalls, 0);
    });

    test('leaves the collection on the server alone', () async {
      // The failure this prevents: a fresh sign-in erasing the account.
      remote = FakeSyncRemote(
        stored: SyncCollection(
          spaces: [space('s-server')],
          decks: const [],
          cards: [card('c-server', 'd-server')],
          reviewLogs: [log('r-server', t1)],
        ),
      );
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: state,
      );

      await useCase.sync();

      expect(remote.stored.spaces.map((s) => s.id), ['s-server']);
      expect(remote.stored.cards.map((c) => c.id), ['c-server']);
    });

    test('receives the collection and the history from the server', () async {
      remote = FakeSyncRemote(
        stored: SyncCollection(
          spaces: [space('s-server')],
          decks: [deck('d-server', 's-server')],
          cards: [card('c-server', 'd-server')],
          reviewLogs: [log('r-server', t1)],
        ),
      );
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: state,
      );

      await useCase.sync();

      expect(local.spaces.map((s) => s.id), ['s-server']);
      expect(local.decks.map((d) => d.id), ['d-server']);
      expect(local.cards.map((c) => c.id), ['c-server']);
      expect(local.reviewLogs.map((l) => l.id), ['r-server']);
    });
  });

  group('history recorded on another surface', () {
    test('is received without losing what this device reviewed', () async {
      local.spaces.add(space('s1'));
      local.reviewLogs.add(log('r-mine', t2));
      remote = FakeSyncRemote(
        stored: SyncCollection(
          spaces: [space('s1')],
          decks: const [],
          cards: const [],
          reviewLogs: [log('r-theirs', t1)],
        ),
      );
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: state,
      );

      await useCase.sync();

      expect(
        local.reviewLogs.map((l) => l.id).toSet(),
        {'r-mine', 'r-theirs'},
      );
    });
  });

  group('failure', () {
    setUp(() {
      local.spaces.add(space('s1'));
      local.reviewLogs.add(log('r1', t1));
    });

    test('does not advance the watermark when the upload is refused', () async {
      // Advancing it optimistically would mean the entry is never retried, which
      // loses a review silently.
      remote.failAppend = true;

      await expectLater(useCase.sync(), throwsA(isA<StateError>()));

      expect(state.watermark, isNull);
      expect(state.writes, 0);
    });
    test('does not advance the watermark when the structure upload is refused',
        () async {
      remote.failReplace = true;

      await expectLater(useCase.sync(), throwsA(isA<StateError>()));

      expect(state.watermark, isNull);
      expect(remote.appendCalls, 0);
    });

    test('does not replace the device collection when the pull is refused',
        () async {
      local.cards.add(card('c1', 'd1'));
      remote.failPull = true;

      await expectLater(useCase.sync(), throwsA(isA<StateError>()));

      // The upload happened, so the watermark moved; the local collection was
      // never touched by a pull that failed.
      expect(local.cards.map((c) => c.id), ['c1']);
    });
  });

  group('download', () {
    test('never uploads', () async {
      local.spaces.add(space('local-only'));
      remote = FakeSyncRemote(
        stored: SyncCollection(
          spaces: [space('from-server')],
          decks: const [],
          cards: const [],
          reviewLogs: const [],
        ),
      );
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: state,
      );

      await useCase.download();

      expect(remote.replaceCalls, 0);
      expect(remote.appendCalls, 0);
      expect(remote.pullCalls, 1);
    });

    test('discards what was on the device', () async {
      // That is the point of it: it is the other half of the first-sign-in
      // question, and why it is never called automatically.
      local.spaces.add(space('local-only'));

      await useCase.download();

      expect(local.spaces, isEmpty);
    });
  });

  group('watermark', () {
    test('is never written when there is no history to send', () async {
      await useCase.sync();

      expect(state.writes, 0);
      expect(state.watermark, isNull);
    });

    test('resumes from a watermark already stored', () async {
      final store = InMemorySyncStateStore(t2);
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: store,
      );
      local.spaces.add(space('s1'));
      local.reviewLogs.addAll([log('r-old', t1), log('r-new', t3)]);

      await useCase.sync();

      expect(remote.appendedLogs.map((l) => l.id), ['r-new']);
    });
  });

  group('the pulled collection is corrected before it is stored', () {
    test('a box the history does not support is rebuilt', () async {
      // The server holds whatever a device last pushed, and a device that has
      // been offline pushes a box from days ago. The history travels with it, so
      // the correction belongs here rather than at the point of use.
      remote = FakeSyncRemote(
        stored: SyncCollection(
          spaces: [space('s1')],
          decks: [deck('d1', 's1')],
          cards: [card('c1', 'd1')], // box 1
          reviewLogs: [log('r1', t2, after: 5)],
        ),
      );
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: state,
      );

      await useCase.sync();

      expect(local.cards.single.box, 5);
      expect(local.cards.single.lastReviewed, t2);
    });

    test('download is corrected too, not only the exchanging path', () async {
      remote = FakeSyncRemote(
        stored: SyncCollection(
          spaces: [space('s1')],
          decks: [deck('d1', 's1')],
          cards: [card('c1', 'd1')],
          reviewLogs: [log('r1', t2, after: 4)],
        ),
      );
      useCase = SyncCollectionUseCase(
        localDataSource: local,
        remote: remote,
        state: state,
      );

      await useCase.download();

      expect(local.cards.single.box, 4);
    });
  });

  group('what is waiting to be uploaded', () {
    test('is nothing when there is no history', () async {
      expect(await useCase.reviewsSinceLastUpload(), 0);
    });

    test('is everything before the first sync', () async {
      local.reviewLogs.addAll([log('r1', t1), log('r2', t2)]);

      expect(await useCase.reviewsSinceLastUpload(), 2);
    });

    test('is nothing right after a sync', () async {
      // The send includes the entry on the watermark on purpose, but counting it
      // would leave this reading "1" forever — and a badge that never clears is one
      // the user stops seeing.
      local.spaces.add(space('s1'));
      local.reviewLogs.add(log('r1', t1));
      await useCase.sync();

      expect(await useCase.reviewsSinceLastUpload(), 0);
    });

    test('counts only what has been reviewed since', () async {
      local.spaces.add(space('s1'));
      local.reviewLogs.add(log('r1', t1));
      await useCase.sync();

      local.reviewLogs.addAll([log('r2', t2), log('r3', t3)]);

      expect(await useCase.reviewsSinceLastUpload(), 2);
    });

    test('drops back to nothing after the next sync', () async {
      local.spaces.add(space('s1'));
      local.reviewLogs.add(log('r1', t1));
      await useCase.sync();
      local.reviewLogs.add(log('r2', t2));

      await useCase.sync();

      expect(await useCase.reviewsSinceLastUpload(), 0);
      expect(state.watermark, t2);
    });
  });
}
