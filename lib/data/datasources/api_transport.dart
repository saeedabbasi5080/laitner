import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/remote/remote_config.dart';
import 'package:recall/domain/entities/auth_error.dart';

/// One HTTP request, and one place where every way it can fail becomes an
/// [AuthError].
///
/// Pulled out of the sign-in client when sync arrived. Both talk to the same
/// service with the same base address, the same timeout and the same error shape,
/// and a second copy would be a second place for those to drift — which is exactly
/// the kind of drift that shows up as one screen reporting a network failure and
/// another reporting a bug.
///
/// "Auth" in the error type and in the naming below is historical: this is the
/// transport for everything the app says to the Atilearn service.
class ApiTransport {
  ApiTransport({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? RemoteConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Short, because a request that has not answered in eight seconds is not going
  /// to, and a spinner that outlasts the user's patience is worse than an error.
  static const Duration timeout = Duration(seconds: 8);

  /// Whether this knows where to send requests.
  ///
  /// Judged against this instance's own address, not against the compiled-in one.
  /// Consulting the global would make an injected address — a test's, or a future
  /// settings screen's — look unconfigured, which is how a legitimate request ends
  /// up refused before it is made.
  bool get isConfigured => _baseUrl != RemoteConfig.emulatorLoopback;

  void close() => _client.close();

  /// Sends [payload] as JSON and returns the JSON object that comes back.
  ///
  /// An empty body on a success returns an empty map, which is what a `204`
  /// produces. A body that is present but not a JSON object is a failure rather
  /// than an empty result: returning `{}` there would hand the caller a lie it has
  /// no way to detect.
  Future<Map<String, dynamic>> send(
    String method,
    String path, {
    Object? payload,
    String? accessToken,
    required String fallbackMessage,
    required String notConfiguredMessage,
  }) async {
    if (!isConfigured) {
      // Checked before the request so the user is told the address is missing
      // rather than being shown a connection error to a host that was never named.
      throw AuthError(AuthFailure.notConfigured, message: notConfiguredMessage);
    }

    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };

    late final http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (payload != null) request.body = jsonEncode(payload);

      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw AuthError(AuthFailure.network, message: AppStrings.authServerUnreachable);
    } on SocketException {
      throw AuthError(AuthFailure.network, message: AppStrings.authServerUnreachable);
    } on http.ClientException {
      // Covers the client being closed underneath a request, which is what happens
      // when signing out while a request is in flight.
      throw AuthError(AuthFailure.network, message: AppStrings.authServerUnreachable);
    }

    Map<String, dynamic> body = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) body = decoded;
      } on FormatException {
        // Left as an empty map, which the branches below then reject. A body this
        // app cannot parse is not a body it can trust either way.
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty && response.body.isNotEmpty) {
        throw AuthError(
          AuthFailure.unexpected,
          message: AppStrings.authUnexpectedResponse,
        );
      }
      return body;
    }

    throw AuthError.fromServer(
      response.statusCode,
      body,
      fallbackMessage: fallbackMessage,
    );
  }
}
