import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recall/data/datasources/api_transport.dart';
import 'package:recall/data/datasources/http_sync_remote.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';

const _baseUrl = 'http://localhost:5070/api/v1';

void main() {
  final space = LearningSpace(
    id: 'space-1',
    name: 'فضای من',
    color: DeckColor.lavender,
    createdAt: DateTime(2026, 1, 1, 9, 30),
    sortOrder: 2,
  );
  final deck = Deck(
    id: 'deck-1',
    spaceId: 'space-1',
    name: 'دسته',
    color: DeckColor.mint,
    createdAt: DateTime(2026, 1, 1, 9, 31),
  );
  final card = Flashcard(
    id: 'card-1',
    deckId: 'deck-1',
    front: 'رو',
    back: 'پشت',
    box: 2,
    lastReviewed: DateTime(2026, 1, 2, 10),
    createdAt: DateTime(2026, 1, 1, 9, 32),
    tags: const ['لغت'],
  );
  final log = ReviewLog(
    id: '1735689600000000-card-1',
    spaceId: 'space-1',
    cardId: 'card-1',
    deckId: 'deck-1',
    rating: ReviewRating.know,
    boxBefore: 1,
    boxAfter: 2,
    reviewedAt: DateTime(2026, 1, 2, 10),
  );

  /// A remote with a token in the store, and a transport over [handler].
  HttpSyncRemote remoteFor(
    Future<http.Response> Function(http.Request request) handler, {
    bool signedIn = true,
  }) {
    return HttpSyncRemote(
      tokenStore: signedIn
          ? InMemoryAuthTokenStore(
              const StoredSession(
                accessToken: 'token-abc',
                user: AuthUser(id: 'u', phoneNumber: '0912 123 4567'),
              ),
            )
          : InMemoryAuthTokenStore(),
      transport: ApiTransport(client: MockClient(handler), baseUrl: _baseUrl),
    );
  }

  http.Response ok(Object body) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  http.Response empty() => http.Response('', 204);

  http.Response refusal(int status, String code) => http.Response.bytes(
        utf8.encode(jsonEncode({'error': 'x', 'code': code})),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  group('replaceCollection', () {
    test('puts the structure on the collection path', () async {
      late http.Request seen;
      final remote = remoteFor((request) async {
        seen = request;
        return empty();
      });

      await remote.replaceCollection(
        spaces: [space],
        decks: [deck],
        cards: [card],
      );

      expect(seen.method, 'PUT');
      expect(seen.url.toString(), '$_baseUrl/sync/collection');

      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect((body['spaces'] as List).single['id'], 'space-1');
      expect((body['decks'] as List).single['id'], 'deck-1');
      expect((body['cards'] as List).single['id'], 'card-1');
    });

    test('sends the entities own JSON, not a second format', () async {
      // The point of leaning on `toJson`: a field added to a card reaches the
      // server without anybody remembering to add it here.
      late http.Request seen;
      final remote = remoteFor((request) async {
        seen = request;
        return empty();
      });

      await remote.replaceCollection(spaces: [space], decks: [], cards: []);

      final sent = (jsonDecode(seen.body) as Map<String, dynamic>)['spaces'] as List;
      expect(sent.single, space.toJson());
    });

    test('carries the account token', () async {
      late http.Request seen;
      final remote = remoteFor((request) async {
        seen = request;
        return empty();
      });

      await remote.replaceCollection(spaces: [space], decks: [], cards: []);

      expect(seen.headers['Authorization'], 'Bearer token-abc');
    });

    test('refuses without a session, and does not call the server', () async {
      var called = false;
      final remote = remoteFor((_) async {
        called = true;
        return empty();
      }, signedIn: false);

      await expectLater(
        remote.replaceCollection(spaces: [space], decks: [], cards: []),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unauthorized)),
      );
      expect(called, isFalse);
    });
  });

  group('appendReviewLogs', () {
    test('posts a bare array to the review-log path', () async {
      late http.Request seen;
      final remote = remoteFor((request) async {
        seen = request;
        return empty();
      });

      await remote.appendReviewLogs([log]);

      expect(seen.method, 'POST');
      expect(seen.url.toString(), '$_baseUrl/sync/review-logs');

      final body = jsonDecode(seen.body);
      expect(body, isA<List>());
      expect((body as List).single['id'], log.id);
    });

    test('sends nothing at all for an empty batch', () async {
      // A request that carries nothing still costs a round trip.
      var called = false;
      final remote = remoteFor((_) async {
        called = true;
        return empty();
      });

      await remote.appendReviewLogs(const []);

      expect(called, isFalse);
    });
  });

  group('pull', () {
    test('reads the whole collection back', () async {
      final remote = remoteFor((_) async => ok({
            'spaces': [space.toJson()],
            'decks': [deck.toJson()],
            'cards': [card.toJson()],
            'reviewLogs': [log.toJson()],
          }));

      final pulled = await remote.pull();

      expect(pulled.spaces.single.id, 'space-1');
      expect(pulled.decks.single.id, 'deck-1');
      expect(pulled.cards.single.id, 'card-1');
      expect(pulled.reviewLogs.single.id, log.id);
    });

    test('round-trips a card exactly, including its local times', () async {
      // The app sends wall clock with no offset. A server that read it as an
      // instant would shift every time, so this asserts the value survives the
      // shape it travels in.
      final remote = remoteFor((_) async => ok({
            'spaces': <Object>[],
            'decks': <Object>[],
            'cards': [card.toJson()],
            'reviewLogs': <Object>[],
          }));

      final pulled = await remote.pull();

      expect(pulled.cards.single.createdAt, card.createdAt);
      expect(pulled.cards.single.lastReviewed, card.lastReviewed);
      expect(pulled.cards.single.tags, card.tags);
    });

    test('treats a missing list as empty rather than failing', () async {
      // Refusing the whole exchange over one absent field would leave the device
      // unable to sync at all.
      final remote = remoteFor((_) async => ok({'spaces': <Object>[]}));

      final pulled = await remote.pull();

      expect(pulled.cards, isEmpty);
      expect(pulled.reviewLogs, isEmpty);
    });

    test('skips entries that are not objects', () async {
      final remote = remoteFor((_) async => ok({
            'spaces': ['not an object', space.toJson()],
          }));

      final pulled = await remote.pull();

      expect(pulled.spaces.single.id, 'space-1');
    });
  });

  group('refusals', () {
    test('reads a signed-out device as its own failure', () async {
      // Its own case, because the app has to forget the token rather than retry.
      final remote = remoteFor((_) async => refusal(401, 'device_signed_out'));

      await expectLater(
        remote.pull(),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.deviceSignedOut)),
      );
    });

    test('a signed-out device is not worth retrying', () {
      const error = AuthError(AuthFailure.deviceSignedOut, message: 'x');

      expect(error.canRetryImmediately, isFalse);
    });

    test('reads a plain unauthorized as unauthorized', () async {
      final remote = remoteFor((_) async => refusal(401, 'unauthorized'));

      await expectLater(
        remote.pull(),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unauthorized)),
      );
    });

    test('an unrecognised server error reads as a network failure', () async {
      final remote = remoteFor((_) async => refusal(500, 'something_new'));

      await expectLater(
        remote.pull(),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.network)),
      );
    });
  });
}
