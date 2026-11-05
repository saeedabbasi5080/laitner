import 'package:recall/domain/entities/catalog.dart';

/// How a ready-made list turns into cards, the same way for a deck and for an
/// Excel file, so a list added directly and one imported from its downloaded
/// file give identical cards.
class CatalogCardOptions {
  const CatalogCardOptions({this.includePronunciation = true, this.tagLessons = true});

  /// The pronunciation goes on the back, under the meaning, as `/…/`. Not on
  /// the front: text-to-speech reads the front, and would read the symbols.
  final bool includePronunciation;

  /// Each card is tagged with its lesson when the list has more than one, so a
  /// course added as one deck can still be studied lesson by lesson.
  final bool tagLessons;
}

typedef CatalogCardRow = ({String front, String back, List<String> tags});

List<CatalogCardRow> catalogCardRows(List<CatalogLesson> lessons, CatalogCardOptions options) {
  final tagged = options.tagLessons && lessons.where((lesson) => lesson.words.isNotEmpty).length > 1;
  final rows = <CatalogCardRow>[];
  for (final lesson in lessons) {
    final tags = tagged ? [lessonTag(lesson.title)] : const <String>[];
    for (final word in lesson.words) {
      final front = word.term.trim();
      final meaning = word.meaning.trim();
      if (front.isEmpty || meaning.isEmpty) continue;
      final ipa = word.pronunciation?.trim() ?? '';
      final back = options.includePronunciation && ipa.isNotEmpty ? '$meaning\n/$ipa/' : meaning;
      rows.add((front: front, back: back, tags: tags));
    }
  }
  return rows;
}

/// A lesson title as one tag: tags are split on spaces and commas, so
/// "درس 1" would otherwise become two tags.
String lessonTag(String title) {
  final tag = title.trim().replaceAll(RegExp(r'[,،\s]+'), '_');
  return tag.isEmpty ? 'lesson' : tag;
}
