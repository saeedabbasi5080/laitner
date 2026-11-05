import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/datasources/api_transport.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/repositories/catalog_remote.dart';

/// `/catalog/*` on the Atilearn service. No token: the lists are public.
class HttpCatalogRemote implements CatalogRemote {
  HttpCatalogRemote({ApiTransport? transport}) : _transport = transport ?? ApiTransport();

  final ApiTransport _transport;

  /// A course of a thousand words is a few hundred kilobytes; the sign-in
  /// timeout is too short for it on a slow connection.
  static const Duration wordsTimeout = Duration(seconds: 45);

  Future<Map<String, dynamic>> _get(String path, {Duration? within}) => _transport.send(
        'GET',
        path,
        fallbackMessage: AppStrings.catalogLoadFailed,
        notConfiguredMessage: AppStrings.catalogNotConfigured,
        within: within,
      );

  @override
  Future<List<CatalogLanguage>> languages(String sourceLang) async {
    final body = await _get('/catalog/languages?source=${Uri.encodeQueryComponent(sourceLang)}');
    return [
      for (final item in _list(body['languages']))
        CatalogLanguage(
          targetLang: item['targetLang'] as String?,
          lists: _int(item['lists']),
          words: _int(item['words']),
        ),
    ];
  }

  @override
  Future<List<CatalogNode>> roots(String sourceLang, String? targetLang) async {
    final query = 'source=${Uri.encodeQueryComponent(sourceLang)}&target=${Uri.encodeQueryComponent(targetLang ?? '-')}';
    final body = await _get('/catalog/nodes?$query');
    return _list(body['nodes']).map(_node).toList();
  }

  @override
  Future<CatalogNodeDetail> node(int id) async {
    final body = await _get('/catalog/nodes/$id');
    return CatalogNodeDetail(
      node: _node(_map(body['node'])),
      path: [
        for (final item in _list(body['path'])) (id: _int(item['id']), title: item['title'] as String? ?? ''),
      ],
      children: _list(body['children']).map(_node).toList(),
    );
  }

  @override
  Future<CatalogWordList> words(int id) async {
    final body = await _get('/catalog/nodes/$id/words', within: wordsTimeout);
    return CatalogWordList(
      node: _node(_map(body['node'])),
      lessons: [
        for (final lesson in _list(body['lessons']))
          CatalogLesson(
            id: _int(lesson['id']),
            title: lesson['title'] as String? ?? '',
            words: [
              for (final word in _list(lesson['words']))
                CatalogWord(
                  term: word['term'] as String? ?? '',
                  meaning: word['meaning'] as String? ?? '',
                  pronunciation: word['pronunciation'] as String?,
                ),
            ],
          ),
      ],
    );
  }

  static CatalogNode _node(Map<String, dynamic> json) => CatalogNode(
        id: _int(json['id']),
        kind: CatalogNodeKind.parse(json['kind']),
        sourceLang: json['sourceLang'] as String? ?? '',
        targetLang: json['targetLang'] as String?,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        description: json['description'] as String?,
        imageUrl: json['imageUrl'] as String?,
        wordCount: _int(json['wordCount']),
        hasChildren: json['hasChildren'] == true,
      );

  /// A field of the wrong shape is the server breaking its contract, not an
  /// empty list: saying so beats showing "nothing here".
  static List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List) throw _unexpected();
    return [for (final item in value) _map(item)];
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map<String, dynamic>) throw _unexpected();
    return value;
  }

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static AuthError _unexpected() =>
      const AuthError(AuthFailure.unexpected, message: AppStrings.authUnexpectedResponse);
}
