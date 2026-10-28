import 'dart:convert';

class CardStyleCodec {
  static String encode(List<dynamic> delta) {
    if (delta.isEmpty) return '';
    return jsonEncode(delta);
  }

  static List<dynamic>? tryDecode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return null;
  }
}
