/// The signed-in user, as the server describes them.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;

  /// Grouped for reading, e.g. `0912 123 4567`. The server sends it this way and
  /// sends it this way deliberately — a number is read far more often than it is
  /// typed, and grouping is only for the reader.
  final String phoneNumber;

  final String? displayName;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// What to call the user in the interface.
  ///
  /// Falls back to the phone number rather than to a generic word, so the
  /// settings tile identifies the account instead of saying "account".
  String get label => (displayName != null && displayName!.trim().isNotEmpty)
      ? displayName!.trim()
      : phoneNumber;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      displayName: json['displayName'] as String?,
      createdAt: _parseInstant(json['createdAt']),
      lastLoginAt: _parseInstant(json['lastLoginAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'phoneNumber': phoneNumber,
        if (displayName != null) 'displayName': displayName,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (lastLoginAt != null) 'lastLoginAt': lastLoginAt!.toIso8601String(),
      };

  /// Parsed defensively: a timestamp this app cannot read is not worth crashing
  /// a settings tile over, and the only thing it feeds is a "last seen" line
  /// that can be omitted.
  static DateTime? _parseInstant(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          other.id == id &&
          other.phoneNumber == phoneNumber &&
          other.displayName == displayName &&
          other.createdAt == createdAt &&
          other.lastLoginAt == lastLoginAt;

  @override
  int get hashCode =>
      Object.hash(id, phoneNumber, displayName, createdAt, lastLoginAt);

  @override
  String toString() => 'AuthUser($id, $phoneNumber)';
}
