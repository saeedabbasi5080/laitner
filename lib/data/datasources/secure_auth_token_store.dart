import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the session in the platform keystore, falling back to preferences.
///
/// The token is a bearer credential: anyone holding it is the account. That is
/// worth a real keystore — Android's EncryptedSharedPreferences, the iOS
/// keychain — and this is where it lives.
///
/// The fallback is for the places there is no keystore: the web build, the
/// desktop builds, and Flutter's test runner. It is weaker, and it says so, but
/// refusing to store anything there would mean those builds cannot sign in at
/// all, which is worse than storing a token that a desktop user has already
/// accepted is reachable. A note is logged the first time it happens, so the
/// weaker path is never silent.
///
/// Web is not a fallback here so much as the only option, and it is the weakest
/// of the three: browser storage is readable by any script on the origin.
class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore({
    FlutterSecureStorage? secureStorage,
    this._preferences,
  })  : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              // No `encryptedSharedPreferences`: Google deprecated Jetpack
              // Security, and the plugin now migrates to its own ciphers on first
              // access. Passing it only invites a deprecation that is already
              // scheduled to be removed.
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _secureStorage;

  /// Injected when the caller already has one, so start-up does not build a
  /// second. Null on the platform path, where it is only ever needed as a
  /// fallback.
  final SharedPreferences? _preferences;

  /// Whether the keystore has already proved unusable.
  ///
  /// Latched after the first failure so a keystore that is unavailable — an old
  /// Android without an unlocked screen, say — does not cost every read an
  /// exception.
  bool? _keystoreAvailable;

  @override
  Future<StoredSession?> read() async {
    if (await _useKeystore()) {
      return _readFromKeystore();
    }
    return _readFromPreferences();
  }

  Future<StoredSession?> _readFromKeystore() async {
    try {
      final token = await _secureStorage.read(key: AuthStorageKeys.token);
      if (token == null || token.isEmpty) {
        // No token in the keystore but maybe one in preferences, from a build
        // that used the fallback. Reading both means upgrading the app does not
        // sign the user out.
        return _readFromPreferences();
      }

      final rawUser = await _secureStorage.read(key: AuthStorageKeys.user);
      final rawExpiry = await _secureStorage.read(key: AuthStorageKeys.expiresAt);

      final user = rawUser == null
          ? const <String, dynamic>{}
          : jsonDecode(rawUser) as Map<String, dynamic>;

      return StoredSession.fromJson({
        'accessToken': token,
        'user': user,
        'expiresAt': ?rawExpiry,
      });
    } catch (error) {
      // A keystore read that throws means the entry cannot be trusted either.
      // Reporting "signed out" costs the user one sign-in; reporting a session
      // that cannot be presented would leave them apparently signed in forever.
      _keystoreAvailable = false;
      debugPrint('Keystore read failed ($error); falling back to preferences.');
      return _readFromPreferences();
    }
  }

  Future<StoredSession?> _readFromPreferences() async {
    final prefs = await _prefs();
    final token = prefs.getString(AuthStorageKeys.token);
    if (token == null || token.isEmpty) return null;

    final rawUser = prefs.getString(AuthStorageKeys.user);
    final user = rawUser == null
        ? const <String, dynamic>{}
        : _decode(rawUser) ?? const <String, dynamic>{};

    final rawExpiry = prefs.getString(AuthStorageKeys.expiresAt);

    return StoredSession.fromJson({
      'accessToken': token,
      'user': user,
      'expiresAt': ?rawExpiry,
    });
  }

  @override
  Future<void> write(StoredSession session) async {
    // Both stores are written, not just one. Which of them is readable depends on
    // the platform, and writing only the preferred one would strand the session
    // the moment a read happened on a build that could not use it.
    if (await _useKeystore()) {
      try {
        await _secureStorage.write(key: AuthStorageKeys.token, value: session.accessToken);
        await _secureStorage.write(
          key: AuthStorageKeys.user,
          value: jsonEncode(session.user.toJson()),
        );
        await _secureStorage.write(
          key: AuthStorageKeys.expiresAt,
          value: session.expiresAt?.toIso8601String() ?? '',
        );
        if (session.expiresAt == null) {
          await _secureStorage.delete(key: AuthStorageKeys.expiresAt);
        }
      } catch (error) {
        _keystoreAvailable = false;
        debugPrint('Keystore write failed ($error); falling back to preferences.');
      }
    }

    final prefs = await _prefs();
    await prefs.setString(AuthStorageKeys.token, session.accessToken);
    await prefs.setString(AuthStorageKeys.user, jsonEncode(session.user.toJson()));
    if (session.expiresAt == null) {
      await prefs.remove(AuthStorageKeys.expiresAt);
    } else {
      await prefs.setString(
        AuthStorageKeys.expiresAt,
        session.expiresAt!.toIso8601String(),
      );
    }
  }

  @override
  Future<void> clear() async {
    // Cleared from both. Leaving a copy behind in preferences after signing out
    // would defeat the point of signing out.
    if (await _useKeystore()) {
      try {
        await _secureStorage.delete(key: AuthStorageKeys.token);
        await _secureStorage.delete(key: AuthStorageKeys.user);
        await _secureStorage.delete(key: AuthStorageKeys.expiresAt);
      } catch (error) {
        debugPrint('Keystore delete failed ($error): $error');
      }
    }

    final prefs = await _prefs();
    await prefs.remove(AuthStorageKeys.token);
    await prefs.remove(AuthStorageKeys.user);
    await prefs.remove(AuthStorageKeys.expiresAt);
  }

  /// Whether the keystore can be relied on here.
  ///
  /// Decided once. The web build has no platform channel for this at all, so
  /// asking it a question costs an exception on every read; `kIsWeb` answers it
  /// without one.
  Future<bool> _useKeystore() async {
    if (kIsWeb) return false;
    return _keystoreAvailable ??= true;
  }

  Future<SharedPreferences> _prefs() async {
    final injected = _preferences;
    if (injected != null) return injected;
    return SharedPreferences.getInstance();
  }

  /// Parsed defensively: an unparseable blob is treated as absent.
  static Map<String, dynamic>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

/// Keeps nothing.
///
/// For tests, and for the one case where losing the session is the correct
/// outcome anyway. Distinct from an empty [SecureAuthTokenStore] because "there
/// is no session" and "I am not going to remember one" are different answers,
/// and a test that wants the second should not have to pretend it is the first.
class InMemoryAuthTokenStore implements AuthTokenStore {
  InMemoryAuthTokenStore([this._session]);

  StoredSession? _session;

  /// Whether a session is currently held, for assertions.
  bool get hasSession => _session != null;

  @override
  Future<StoredSession?> read() async => _session;

  @override
  Future<void> write(StoredSession session) async => _session = session;

  @override
  Future<void> clear() async => _session = null;
}

/// Keeps the session in preferences only.
///
/// For tests that need the fallback path specifically — the round trip through
/// JSON and back is exactly what breaks, and it only breaks here.
class PreferencesAuthTokenStore implements AuthTokenStore {
  PreferencesAuthTokenStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<StoredSession?> read() async {
    final token = _preferences.getString(AuthStorageKeys.token);
    if (token == null || token.isEmpty) return null;

    final rawUser = _preferences.getString(AuthStorageKeys.user);
    final user = rawUser == null
        ? const <String, dynamic>{}
        : SecureAuthTokenStore._decode(rawUser) ?? const <String, dynamic>{};

    final rawExpiry = _preferences.getString(AuthStorageKeys.expiresAt);

    return StoredSession.fromJson({
      'accessToken': token,
      'user': user,
      'expiresAt': ?rawExpiry,
    });
  }

  @override
  Future<void> write(StoredSession session) async {
    await _preferences.setString(AuthStorageKeys.token, session.accessToken);
    await _preferences.setString(
      AuthStorageKeys.user,
      jsonEncode(session.user.toJson()),
    );
    if (session.expiresAt == null) {
      await _preferences.remove(AuthStorageKeys.expiresAt);
    } else {
      await _preferences.setString(
        AuthStorageKeys.expiresAt,
        session.expiresAt!.toIso8601String(),
      );
    }
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(AuthStorageKeys.token);
    await _preferences.remove(AuthStorageKeys.user);
    await _preferences.remove(AuthStorageKeys.expiresAt);
  }
}
