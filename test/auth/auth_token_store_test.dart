import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/domain/entities/auth_user.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// The fallback store, not the keystore one.
  ///
  /// This is the round trip that matters and the one that has broken before: a
  /// session written has to come back identical, because a value that reads back
  /// differently is indistinguishable from one that was never saved.
  late PreferencesAuthTokenStore store;

  const user = AuthUser(
    id: 'user-1',
    phoneNumber: '0912 123 4567',
    displayName: 'سارا',
    createdAt: null,
    lastLoginAt: null,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = PreferencesAuthTokenStore(await SharedPreferences.getInstance());
  });

  group('round trip', () {
    test('reads back exactly what was written', () async {
      final session = StoredSession(
        accessToken: 'token-abc',
        user: user,
        expiresAt: DateTime(2026, 3, 1, 12),
      );

      await store.write(session);
      final read = await store.read();

      expect(read, isNotNull);
      expect(read!.accessToken, 'token-abc');
      expect(read.user.id, 'user-1');
      expect(read.user.phoneNumber, '0912 123 4567');
      expect(read.user.displayName, 'سارا');
      expect(read.expiresAt, DateTime(2026, 3, 1, 12));
    });

    test('round-trips a session with no expiry', () async {
      await store.write(StoredSession(accessToken: 't', user: user));

      expect((await store.read())!.expiresAt, isNull);
    });

    test('round-trips a user with no display name', () async {
      await store.write(StoredSession(
        accessToken: 't',
        user: const AuthUser(id: 'u', phoneNumber: '0912 000 0000'),
      ));

      expect((await store.read())!.user.displayName, isNull);
    });
  });

  group('empty state', () {
    test('reads null when nothing was ever written', () async {
      expect(await store.read(), isNull);
    });

    test('reads null when the token is an empty string', () async {
      // A half-written entry should read as "no session", not as a session with
      // no token — which would look signed in and fail on the first request.
      SharedPreferences.setMockInitialValues({AuthStorageKeys.token: ''});
      final prefs = await SharedPreferences.getInstance();

      expect(await PreferencesAuthTokenStore(prefs).read(), isNull);
    });

    test('reads null when the token exists but the user blob is corrupt', () async {
      SharedPreferences.setMockInitialValues({
        AuthStorageKeys.token: 'token-abc',
        AuthStorageKeys.user: 'not json at all',
      });
      final prefs = await SharedPreferences.getInstance();

      // The token is kept and the user degrades to empty. Losing the whole
      // session over a damaged profile would be a worse outcome than a settings
      // tile missing a name.
      final read = await PreferencesAuthTokenStore(prefs).read();
      expect(read, isNotNull);
      expect(read!.accessToken, 'token-abc');
      expect(read.user.phoneNumber, isEmpty);
    });

    test('reads null when the expiry is unparseable', () async {
      SharedPreferences.setMockInitialValues({
        AuthStorageKeys.token: 't',
        AuthStorageKeys.expiresAt: 'the thirtieth',
      });
      final prefs = await SharedPreferences.getInstance();

      expect((await PreferencesAuthTokenStore(prefs).read())!.expiresAt, isNull);
    });
  });

  group('clear', () {
    test('removes every key, so nothing is left behind', () async {
      await store.write(StoredSession(
        accessToken: 'token-abc',
        user: user,
        expiresAt: DateTime(2026, 3, 1),
      ));

      await store.clear();

      // Leaving a copy behind after signing out would defeat the point of it.
      expect(await store.read(), isNull);
    });

    test('is safe to call when nothing is stored', () async {
      await store.clear();

      expect(await store.read(), isNull);
    });
  });

  group('expiry', () {
    test('a session with no expiry never reads as expired', () async {
      // Unknown lifetime means "assume it works": guessing would sign the user
      // out, or keep them in after the server had forgotten them.
      expect(const StoredSession(accessToken: 't', user: user).isExpired, isFalse);
    });

    test('a session whose expiry has passed reads as expired', () {
      final session = StoredSession(
        accessToken: 't',
        user: user,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(session.isExpired, isTrue);
    });

    test('a session whose expiry is ahead reads as current', () {
      final session = StoredSession(
        accessToken: 't',
        user: user,
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(session.isExpired, isFalse);
    });
  });

  group('JSON encoding', () {
    test('survives a round trip through real JSON text', () {
      // The store persists text, so the value has to be right as text too. This
      // is the assertion that catches an encoder which works in memory and loses
      // something on disk — which is exactly the failure that is invisible until
      // a user's token stops working.
      final session = StoredSession(
        accessToken: 'token-with-quotes-"and-backslashes-\\',
        user: user,
        expiresAt: DateTime(2026, 3, 1, 12),
      );

      final text = jsonEncode(session.toJson());
      final decoded =
          StoredSession.fromJson(jsonDecode(text) as Map<String, dynamic>);

      expect(decoded.accessToken, session.accessToken);
      expect(decoded.user.id, 'user-1');
      expect(decoded.user.displayName, 'سارا');
      expect(decoded.expiresAt, session.expiresAt);
    });

    test('omits the expiry key entirely when there is none', () {
      // Not null, absent: a stored null would be read back as the string "null".
      final text = jsonEncode(
        const StoredSession(accessToken: 't', user: user).toJson(),
      );

      expect(text.contains('expiresAt'), isFalse);
    });
  });
}
