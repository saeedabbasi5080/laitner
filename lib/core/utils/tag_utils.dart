class TagUtils {
  static final _separators = RegExp(r'[,،\s]+');

  static List<String> normalize(Iterable<String> raw) {
    final seen = <String>{};
    final tags = <String>[];
    for (final value in raw) {
      final tag = value.trim();
      if (tag.isEmpty) continue;
      if (seen.add(tag.toLowerCase())) {
        tags.add(tag);
      }
    }
    return tags;
  }

  static List<String> splitInput(String text) => normalize(text.split(_separators));
}
