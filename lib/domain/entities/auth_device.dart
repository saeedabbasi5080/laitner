/// One place an account is signed in, as the app is shown it.
///
/// [current] is what makes a list of these usable. Without it the user is reading
/// names and dates with no way to tell which one they are holding, and "sign this
/// one out" becomes a guess.
class AuthDevice {
  const AuthDevice({
    required this.deviceId,
    required this.lastSeenAt,
    this.label,
    this.current = false,
  });

  final String deviceId;

  /// What the user calls it. Null when the app that signed in could not tell —
  /// which is better than a name invented here, because this list is how somebody
  /// identifies their own phone.
  final String? label;

  /// The server's own clock, so it is a real instant and comes back as UTC.
  final DateTime? lastSeenAt;

  /// Whether this is the device asking.
  final bool current;

  /// What to show for this device.
  ///
  /// Falls back to a shortened id rather than to a generic word: two unlabelled
  /// devices would otherwise be two identical rows, and the user would have no way
  /// to choose between them.
  String get displayName {
    final trimmed = label?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    if (deviceId.length <= 8) return deviceId;
    return deviceId.substring(0, 8);
  }

  factory AuthDevice.fromJson(Map<String, dynamic> json) {
    return AuthDevice(
      deviceId: json['deviceId'] as String? ?? '',
      label: json['label'] as String?,
      lastSeenAt: _parseInstant(json['lastSeenAt']),
      current: json['current'] as bool? ?? false,
    );
  }

  /// Parsed defensively and kept as UTC. A timestamp this app cannot read is not
  /// worth failing a settings screen over — the row still identifies a device, and
  /// the only thing lost is when it was last used.
  static DateTime? _parseInstant(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  String toString() => 'AuthDevice($deviceId, current: $current)';
}
