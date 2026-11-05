import 'package:equatable/equatable.dart';

/// Ready-made word lists published on the Atilearn server.
///
/// A list belongs to a language pair: [CatalogNode.sourceLang] is the language
/// the learner already speaks (the meanings are in it), [CatalogNode.targetLang]
/// the one they are learning. Both are BCP-47 tags (`fa`, `en`, `en-US`). A null
/// target is a topic that is not a language.
///
/// Under a pair the lists form a tree that keeps the shape of the site they
/// came from: groups hold other nodes, a lesson holds words.

enum CatalogNodeKind {
  group,
  course,
  lesson;

  static CatalogNodeKind parse(Object? raw) => switch (raw) {
        'course' => CatalogNodeKind.course,
        'lesson' => CatalogNodeKind.lesson,
        _ => CatalogNodeKind.group,
      };
}

/// One language a learner can pick, with how much there is to learn in it.
class CatalogLanguage extends Equatable {
  const CatalogLanguage({required this.targetLang, required this.lists, required this.words});

  final String? targetLang;
  final int lists;
  final int words;

  @override
  List<Object?> get props => [targetLang, lists, words];
}

class CatalogNode extends Equatable {
  const CatalogNode({
    required this.id,
    required this.kind,
    required this.sourceLang,
    required this.targetLang,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    required this.wordCount,
    required this.hasChildren,
  });

  final int id;
  final CatalogNodeKind kind;
  final String sourceLang;
  final String? targetLang;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final int wordCount;
  final bool hasChildren;

  bool get isLesson => kind == CatalogNodeKind.lesson;

  @override
  List<Object?> get props => [id, kind, sourceLang, targetLang, title, subtitle, description, imageUrl, wordCount, hasChildren];
}

/// A node with where it sits and what is under it.
class CatalogNodeDetail extends Equatable {
  const CatalogNodeDetail({required this.node, required this.path, required this.children});

  final CatalogNode node;

  /// Titles from the root down to [node], for a breadcrumb.
  final List<({int id, String title})> path;
  final List<CatalogNode> children;

  @override
  List<Object?> get props => [node, path, children];
}

class CatalogWord extends Equatable {
  const CatalogWord({required this.term, required this.meaning, this.pronunciation});

  final String term;
  final String meaning;
  final String? pronunciation;

  @override
  List<Object?> get props => [term, meaning, pronunciation];
}

class CatalogLesson extends Equatable {
  const CatalogLesson({required this.id, required this.title, required this.words});

  final int id;
  final String title;
  final List<CatalogWord> words;

  @override
  List<Object?> get props => [id, title, words];
}

/// Every word under one node, lesson by lesson.
class CatalogWordList extends Equatable {
  const CatalogWordList({required this.node, required this.lessons});

  final CatalogNode node;
  final List<CatalogLesson> lessons;

  int get wordCount => lessons.fold(0, (sum, lesson) => sum + lesson.words.length);

  @override
  List<Object?> get props => [node, lessons];
}
