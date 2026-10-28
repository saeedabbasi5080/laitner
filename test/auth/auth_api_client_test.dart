import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/remote/remote_config.dart';
import 'package:recall/data/datasources/auth_api_client.dart';
import 'package:recall/domain/entities/auth_error.dart';

/// The base address used by every client under test.
///
/// A real one, so the tests exercise URL building rather than bypassing it.
const _baseUrl = 'http://localhost:5070/api/v1';

void main() {
  /// A client whose transport answers from [handler].
  ///
  /// Injected rather than a real socket: the point is to check what the client
  /// does with an answer, not that a socket can be opened. And `MockClient`
  /// refuses connections that a test machine may not allow, which would turn a
  /// unit test into a networking test.
  AuthApiClient clientFor(
    Future<http.Response> Function(http.Request request) handler,
  ) {
    return AuthApiClient(
      client: MockClient(handler),
      baseUrl: _baseUrl,
    );
  }

  /// The success answer for a code request.
  http.Response codeSent({int resendAfter = 120, int expiresIn = 300}) {
    return http.Response(
      jsonEncode({
        'sent': true,
        'expiresInSeconds': expiresIn,
        'resendAfterSeconds': resendAfter,
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// The success answer for a verified session.
  http.Response sessionIssued({int expiresIn = 2592000}) {
    return http.Response(
      jsonEncode({
        'accessToken': 'token-abc',
        'tokenType': 'Bearer',
        'issuedAt': '2026-01-01T12:00:00Z',
        'expiresInSeconds': expiresIn,
        'user': {
          'id': 'user-1',
          'phoneNumber': '0912 123 4567',
          'displayName': null,
          'createdAt': '2026-01-01T12:00:00Z',
          'lastLoginAt': '2026-01-01T12:00:00Z',
        },
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// A 200 carrying [body] as UTF-8.
  ///
  /// Bytes rather than a string, because `http.Response`'s string constructor
  /// encodes as Latin-1 and throws on a Persian character. That is a limitation
  /// of the test helper, not of the client under test.
  http.Response jsonBody(Object body) {
    return http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  /// A refusal, in the shape the server uses.
  http.Response refusal(
    int status,
    String code,
    String message, {
    Map<String, dynamic> extra = const {},
  }) {
    return http.Response(
      jsonEncode({'error': message, 'code': code, ...extra}),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  group('requestCode', () {
    test('posts the number to the right path', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return codeSent();
      });

      await client.requestCode('0912 123 4567');

      expect(seen.method, 'POST');
      expect(seen.url.toString(), '$_baseUrl/auth/otp/request');
      expect(jsonDecode(seen.body)['phoneNumber'], '0912 123 4567');
    });

    test('reads the two durations off the answer', () async {
      final client = clientFor((_) async => codeSent());

      final dispatch = await client.requestCode('0912 123 4567');

      expect(dispatch.expiresInSeconds, 300);
      expect(dispatch.resendAfterSeconds, 120);
    });

    test('falls back to the code lifetime when no resend delay comes back',
        () async {
      // Without this the countdown is zero and the button invites a refusal.
      final client = clientFor((_) async => codeSent(resendAfter: 0));

      expect((await client.requestCode('0912 123 4567')).effectiveCooldown, 300);
    });

    test('surfaces the cooldown a refusal carries', () async {
      final client = clientFor((_) async => refusal(
            429,
            'otp_cooldown',
            'کمی بعد دوباره تلاش کنید.',
            extra: {'cooldown': 45},
          ));

      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.cooldown)
            .having((e) => e.cooldownSeconds, 'cooldownSeconds', 45)),
      );
    });

    test('prefers the server message over one composed locally', () async {
      // The server knows why it refused; anything written here would be a guess.
      final client = clientFor((_) async => refusal(400, 'invalid_phone', 'شماره نامعتبر است.'));

      await expectLater(
        client.requestCode('12345'),
        throwsA(isA<AuthError>()
            .having((e) => e.message, 'message', 'شماره نامعتبر است.')),
      );
    });

    test('falls back to its own message when the server sent none', () async {
      final client = clientFor((_) async => refusal(400, 'invalid_phone', ''));

      await expectLater(
        client.requestCode('12345'),
        throwsA(isA<AuthError>()
            .having((e) => e.message, 'message', AppStrings.authRequestFailed)),
      );
    });
  });

  group('verifyCode', () {
    test('posts both fields to the right path', () async {
      late http.Request seen;
      final client = clientFor((request) async {
        seen = request;
        return sessionIssued();
      });

      await client.verifyCode(phoneNumber: '0912 123 4567', code: '453478');

      expect(seen.url.toString(), '$_baseUrl/auth/otp/verify');
      expect(jsonDecode(seen.body)['code'], '453478');
    });

    test('reads the token and the user', () async {
      final client = clientFor((_) async => sessionIssued());

      final session =
          await client.verifyCode(phoneNumber: '0912 123 4567', code: '453478');

      expect(session.accessToken, 'token-abc');
      expect(session.expiresInSeconds, 2592000);
      expect(session.user.id, 'user-1');
      expect(session.user.phoneNumber, '0912 123 4567');
    });

    test('refuses a 200 that carries no token', () async {
      // Treated as a failure rather than a success: a user shown as signed in
      // with no way to prove it is worse than an error message.
      final client = clientFor((_) async => http.Response('{}', 200));

      await expectLater(
        client.verifyCode(phoneNumber: '0912 123 4567', code: '453478'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unexpected)
            .having((e) => e.message, 'message', AppStrings.authUnexpectedResponse)),
      );
    });

    test('refuses a 200 whose user is not an object', () async {
      final client = clientFor((_) async => http.Response(
            jsonEncode({'accessToken': 't', 'user': 'nonsense'}),
            200,
          ));

      await expectLater(
        client.verifyCode(phoneNumber: '0912 123 4567', code: '453478'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unexpected)),
      );
    });

    test('reads a Persian error body without mangling it', () async {
      // The bytes matter, not just the decoded string: a client that assumed
      // Latin-1 would show the user a row of replacement characters.
      final client = clientFor((_) async => http.Response.bytes(
            utf8.encode(
                jsonEncode({'error': 'کد اشتباه است.', 'code': 'invalid_otp'})),
            401,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ));

      await expectLater(
        client.verifyCode(phoneNumber: '0912 123 4567', code: '000000'),
        throwsA(isA<AuthError>()
            .having((e) => e.message, 'message', 'کد اشتباه است.')
            .having((e) => e.failure, 'failure', AuthFailure.invalidCode)),
      );
    });
  });

  group('token header', () {
    test('is sent on me and on profile, and not on the open endpoints', () async {
      // Only written when a header is actually present: with `??= []` every path
      // would get an empty entry and the "not sent" assertions below would pass
      // without checking anything.
      final authorization = <String, String>{};

      Future<http.Response> record(http.Request request) async {
        for (final entry in request.headers.entries) {
          if (entry.key.toLowerCase() == 'authorization') {
            authorization[request.url.path] = entry.value;
          }
        }

        // Bytes, not a string: `http.Response`'s string constructor encodes as
        // Latin-1 and throws on a Persian character, which is a limitation of the
        // test helper rather than of the client.
        if (request.url.path.endsWith('/me')) {
          return jsonBody({
            'id': 'u',
            'phoneNumber': '0912 123 4567',
          });
        }
        if (request.url.path.endsWith('/profile')) {
          return jsonBody({
            'id': 'u',
            'phoneNumber': '0912 123 4567',
            'displayName': 'سارا',
          });
        }
        if (request.url.path.endsWith('/otp/verify')) {
          return sessionIssued();
        }

        return codeSent();
      }

      final client = clientFor(record);

      await client.me('token-xyz');
      await client.updateProfile(accessToken: 'token-xyz', displayName: 'سارا');
      await client.requestCode('0912 123 4567');
      await client.verifyCode(phoneNumber: '0912 123 4567', code: '453478');

      expect(authorization['/api/v1/auth/me'], 'Bearer token-xyz');
      expect(authorization['/api/v1/auth/profile'], 'Bearer token-xyz');
      // The two open endpoints must not carry a token. Sending one anyway would
      // put a credential into a request that does not need it, where it ends up
      // in whatever logs the path.
      expect(authorization.containsKey('/api/v1/auth/otp/request'), isFalse);
      expect(authorization.containsKey('/api/v1/auth/otp/verify'), isFalse);
    });
  });

  group('transport failures', () {
    test('a dropped connection reads as a network failure', () async {
      final client = clientFor((_) async {
        throw const SocketException('connection refused');
      });

      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.network)
            .having((e) => e.message, 'message', AppStrings.authServerUnreachable)),
      );
    });

    test('a body that is not JSON does not become a different error', () async {
      // An HTML error page from a proxy is not a sign-in failure; it is a
      // response this app cannot read, and saying so is more useful than guessing.
      final client = clientFor((_) async => http.Response('<html>502</html>', 200));

      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unexpected)),
      );
    });

    test('an empty body on a success is rejected, not read as empty', () async {
      final client = clientFor((_) async => http.Response('', 200));

      await expectLater(
        client.verifyCode(phoneNumber: '0912 123 4567', code: '453478'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unexpected)),
      );
    });

    test('a 500 with an unreadable body still reads as a server problem', () async {
      final client = clientFor((_) async => http.Response('gateway timeout', 504));

      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.network)),
      );
    });
  });

  group('error mapping', () {
    /// Every documented code, and what it has to become.
    const cases = {
      'invalid_phone': AuthFailure.invalidPhone,
      'invalid_otp': AuthFailure.invalidCode,
      'otp_expired': AuthFailure.codeExpired,
      'otp_locked': AuthFailure.codeLocked,
      'otp_cooldown': AuthFailure.cooldown,
      'sms_failed': AuthFailure.smsFailed,
      'user_inactive': AuthFailure.userInactive,
      'unauthorized': AuthFailure.unauthorized,
      'rate_limited': AuthFailure.rateLimited,
    };

    cases.forEach((code, failure) {
      test('maps $code to ${failure.name}', () async {
        final client = clientFor((_) async => refusal(400, code, 'x'));

        await expectLater(
          client.requestCode('0912 123 4567'),
          throwsA(isA<AuthError>()
              .having((e) => e.failure, 'failure', failure)
              .having((e) => e.code, 'code', code)),
        );
      });
    });

    test('an unmapped code on a 400 falls back to the status, not to success',
        () async {
      // The server knowing something this build does not should still be a
      // failure. The status is what carries the meaning here — 400 means the
      // request was wrong — and the unknown code is passed through so the app
      // can log it and a future build can learn it.
      final client = clientFor((_) async => refusal(400, 'a_code_from_the_future', 'خطا'));

      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.invalidCode)
            .having((e) => e.code, 'code', 'a_code_from_the_future')),
      );
    });

    test('an unmapped code on an unrecognised status reads as unexpected', () async {
      // 418 carries no meaning this build knows. It is still a failure — never a
      // silent success — and it is reported as something this app does not
      // understand rather than guessed at.
      final client = clientFor((_) async => refusal(418, 'teapot', 'خطا'));

      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.unexpected)),
      );
    });

    test('a 401 with no code at all still reads as a bad code', () async {
      final client = clientFor((_) async => refusal(401, '', 'خطا'));

      await expectLater(
        client.verifyCode(phoneNumber: '0912 123 4567', code: '000000'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.invalidCode)),
      );
    });
  });

  group('canRetryImmediately', () {
    test('is false for the failures a retry cannot fix', () {
      for (final failure in [
        AuthFailure.invalidCode,
        AuthFailure.codeLocked,
        AuthFailure.codeExpired,
      ]) {
        expect(AuthError(failure, message: 'x').canRetryImmediately, isFalse,
            reason: '$failure');
      }
    });

    test('is true for the failures waiting might fix', () {
      for (final failure in [
        AuthFailure.network,
        AuthFailure.smsFailed,
        AuthFailure.notConfigured,
        AuthFailure.rateLimited,
      ]) {
        expect(AuthError(failure, message: 'x').canRetryImmediately, isTrue,
            reason: '$failure');
      }
    });
  });

  group('configured address', () {
    test('the compiled-in address is the emulator loopback by default', () {
      // Not asserting the value is wrong — asserting that the app knows it is
      // the value it has to be told to change, which is what stops the failure
      // from being silent.
      expect(RemoteConfig.isConfigured, isFalse);
      expect(RemoteConfig.apiBaseUrl, RemoteConfig.emulatorLoopback);
    });

    test('flags a plaintext address, because the code travels over it', () {
      expect(RemoteConfig.isCleartext, isTrue);
    });

    test('a client with a real address is configured, even though the global is not',
        () async {
      // The check has to be about this client's address. Judging it against the
      // global would refuse every request from a test, and from any future
      // caller that supplied its own.
      final client = clientFor((_) async => codeSent());

      expect(client.isConfigured, isTrue);
      await client.requestCode('0912 123 4567');
    });

    test('a client left on the emulator loopback refuses before making a request',
        () async {
      // Refused up front, so the user is told the address is missing rather than
      // shown a connection error to a host that was never named.
      var called = false;
      final client = AuthApiClient(
        client: MockClient((_) async {
          called = true;
          return codeSent();
        }),
        baseUrl: RemoteConfig.emulatorLoopback,
      );

      expect(client.isConfigured, isFalse);
      await expectLater(
        client.requestCode('0912 123 4567'),
        throwsA(isA<AuthError>()
            .having((e) => e.failure, 'failure', AuthFailure.notConfigured)
            .having((e) => e.message, 'message', AppStrings.authServerNotConfigured)),
      );
      expect(called, isFalse);
    });
  });
}
