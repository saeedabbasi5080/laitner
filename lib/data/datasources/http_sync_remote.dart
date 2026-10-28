import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/api_transport.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/entities/review_log.dart';
import 'package:recall/domain/repositories/auth_token_store.dart';
import 'package:recall/domain/repositories/sync_remote.dart';

/// Synchronisation, over HTTP.
///
/// ## Why this is thin
///
/// The entities already know how to write themselves out and read themselves back
/// — `LearningSpace.toJson`, `Flashcard.fromJson` and the rest — and those methods
/// are the same ones the backup file uses. So this class does not describe a
/// second wire format that could drift from the server's; it names the endpoints
/// and lets the entities speak. A field added to a card reaches the server without
/// anybody remembering to add it here.
///
/// ## The token
///
/// Read from the store rather than taken as a parameter, because the port has no
/// place for one and should not: what to send is the coordinator's concern, and
/// proving who is sending is this one's. This is the layer that knows there is an
/// account at all.
class HttpSyncRemote implements SyncRemote {
  HttpSyncRemote({
    required AuthTokenStore tokenStore,
    ApiTransport? transport,
  })  : _tokenStore = tokenStore,
        _transport = transport ?? ApiTransport();

  static const String collectionPath = '/sync/collection';
  static const String reviewLogsPath = '/sync/review-logs';

  final AuthTokenStore _tokenStore;
  final ApiTransport _transport;

  @override
  Future<void> replaceCollection({
    required List<LearningSpace> spaces,
    required List<Deck> decks,
    required List<Flashcard> cards,
  }) async {
    await _send(
      'PUT',
      collectionPath,
      payload: {
        'spaces': [for (final space in spaces) space.toJson()],
        'decks': [for (final deck in decks) deck.toJson()],
        'cards': [for (final card in cards) card.toJson()],
      },
      fallback: AppStrings.syncUploadFailed,
    );
  }

  @override
  Future<void> appendReviewLogs(List<ReviewLog> logs) async {
    // A batch that is already empty is not sent. The caller does not send one
    // either, so this is a second guard rather than the first — but a request that
    // carries nothing would still cost a round trip and, on a bad day, a 400.
    if (logs.isEmpty) return;

    await _send(
      'POST',
      reviewLogsPath,
      // A bare array, which is what the endpoint takes: the entries are the whole
      // body, and wrapping them would be a name for something that has none.
      payload: [for (final log in logs) log.toJson()],
      fallback: AppStrings.syncUploadFailed,
    );
  }

  @override
  Future<SyncCollection> pull() async {
    final body = await _send(
      'GET',
      collectionPath,
      fallback: AppStrings.syncDownloadFailed,
    );

    return SyncCollection(
      spaces: _decode(body['spaces'], LearningSpace.fromJson),
      decks: _decode(body['decks'], Deck.fromJson),
      cards: _decode(body['cards'], Flashcard.fromJson),
      reviewLogs: _decode(body['reviewLogs'], ReviewLog.fromJson),
    );
  }

  /// One request, with the account's token on it.
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? payload,
    required String fallback,
  }) async {
    final token = await _token();
    if (token == null) {
      // Refused here rather than letting the server turn away a request that was
      // never going to be authorized. The message says what to do about it.
      throw const AuthError(
        AuthFailure.unauthorized,
        message: AppStrings.syncNotSignedIn,
      );
    }

    return _transport.send(
      method,
      path,
      payload: payload,
      accessToken: token,
      fallbackMessage: fallback,
      notConfiguredMessage: AppStrings.authServerNotConfigured,
    );
  }

  Future<String?> _token() async {
    try {
      return (await _tokenStore.read())?.accessToken;
    } catch (_) {
      // Storage that will not open is indistinguishable, from here, from having no
      // session.
      return null;
    }
  }

  /// Reads one of the collection's lists.
  ///
  /// A missing or unreadable list reads as empty rather than failing the pull. The
  /// server is the one that decides what an account holds, and refusing the whole
  /// exchange over one malformed entry would leave the device unable to sync at
  /// all — when the alternative is that it holds slightly less than it could.
  static List<T> _decode<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return <T>[];

    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>) fromJson(entry),
    ];
  }
}
