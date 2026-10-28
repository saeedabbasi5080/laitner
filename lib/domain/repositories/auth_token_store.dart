import 'package:recall/domain/entities/auth_user.dart';

/// Where a session is kept between launches.
///
/// The interface exists because the storage behind it is not the only thing that
/// could be behind it, and because tests should not have to reach into the
/// platform keystore to assert that signing out cleared the token.
abstract class AuthTokenStore {
  /// The stored session, or null when there is none.
  ///
  /// Returns null rather than throwing on unreadable storage: a corrupt entry
  /// must read as "signed out", never as a launch failure.
  Future<StoredSession?> read();

  Future<void> write(StoredSession session);

  Future<void> clear();
}

/// A session as it is written down.
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.user,
    this.expiresAt,
  });

  final String accessToken;
  final AuthUser user;

  /// When the token stops being accepted, if the server said.
  ///
  /// Kept so the app can refuse a token it knows is dead instead of spending a
  /// request finding that out. Null when unknown, which means "assume it works".
  final DateTime? expiresAt;

  /// Whether this token is past its own expiry.
  ///
  /// Judged here rather than by the server so an expired token does not become a
  /// failed sign-in screen. It is only a local shortcut; the server still has the
  /// final word.
  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  factory StoredSession.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expiresAt'];
    return StoredSession(
      accessToken: json['accessToken'] as String? ?? '',
      user: AuthUser.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
      expiresAt: rawExpiry is String ? DateTime.tryParse(rawExpiry) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'user': user.toJson(),
        if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      };
}

/// Keys the token storage uses.
///
/// The values are what they are because this app's data may already be on
/// devices: renaming a key strands whatever was written under the old one.
abstract final class AuthStorageKeys {
  static const String token = 'recall.auth.token';
  static const String user = 'recall.auth.user';
  static const String expiresAt = 'recall.auth.expires_at';
}
