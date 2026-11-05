import 'package:recall/domain/entities/catalog.dart';

/// The server's published word lists. Read-only, and needs no sign-in.
///
/// Every call can throw an `AuthError` (the app's error for anything the
/// service says or fails to say), whose message is ready to show.
abstract interface class CatalogRemote {
  /// The languages with lists for speakers of [sourceLang].
  Future<List<CatalogLanguage>> languages(String sourceLang);

  /// The top of the tree for one pair; a null [targetLang] asks for topics.
  Future<List<CatalogNode>> roots(String sourceLang, String? targetLang);

  Future<CatalogNodeDetail> node(int id);

  /// Every word under [id], by lesson. Large lists take a while.
  Future<CatalogWordList> words(int id);
}
