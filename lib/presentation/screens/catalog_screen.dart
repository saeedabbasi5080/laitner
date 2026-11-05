import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/utils/pick_excel_file.dart';
import 'package:recall/domain/entities/auth_error.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/entities/deck_color.dart';
import 'package:recall/domain/repositories/catalog_remote.dart';
import 'package:recall/domain/usecases/export_catalog_excel_usecase.dart';
import 'package:recall/domain/usecases/export_deck_excel_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/screens/catalog_gradual_screen.dart';
import 'package:recall/presentation/widgets/catalog_add_sheet.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// The language the app speaks, and so the language of the meanings. When the
/// app gains another interface language, this follows it.
const String catalogSourceLanguage = 'fa';

/// The ready-made lists: first a language, then the tree under it, as deep as
/// the list goes. Any node with words can be added to a deck or saved as Excel.
class CatalogLanguagesScreen extends StatefulWidget {
  const CatalogLanguagesScreen({super.key, this.remote});

  /// Tests pass one; the app uses the registered client.
  final CatalogRemote? remote;

  @override
  State<CatalogLanguagesScreen> createState() => _CatalogLanguagesScreenState();
}

class _CatalogLanguagesScreenState extends State<CatalogLanguagesScreen> {
  late Future<List<CatalogLanguage>> _languages;

  CatalogRemote get _remote => widget.remote ?? sl<CatalogRemote>();

  @override
  void initState() {
    super.initState();
    _languages = _remote.languages(catalogSourceLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<CatalogLanguage>>(
          future: _languages,
          builder: (context, snapshot) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              const AppPageHeader(title: AppStrings.catalogTitle, subtitle: AppStrings.catalogPickLanguage),
              const SizedBox(height: 8),
              ..._body(context, snapshot),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, AsyncSnapshot<List<CatalogLanguage>> snapshot) {
    if (snapshot.hasError) {
      return [
        _Failure(
          error: snapshot.error,
          onRetry: () => setState(() => _languages = _remote.languages(catalogSourceLanguage)),
        ),
      ];
    }
    final languages = snapshot.data;
    if (languages == null) return const [_Loading()];
    if (languages.isEmpty) return const [_Message(AppStrings.catalogEmpty)];
    return [
      for (final (index, language) in languages.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftListTile(
            title: AppStrings.languageName(language.targetLang),
            subtitle: '${AppStrings.catalogLists(language.lists)} · ${AppStrings.catalogWords(language.words)}',
            icon: Icons.translate_rounded,
            accent: _accent(index),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CatalogNodeScreen.roots(
                  targetLang: language.targetLang,
                  remote: widget.remote,
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

/// One level of the tree: the roots of a language, or the children of a node.
class CatalogNodeScreen extends StatefulWidget {
  const CatalogNodeScreen.roots({super.key, required this.targetLang, this.remote}) : nodeId = null;

  const CatalogNodeScreen.node({super.key, required int this.nodeId, this.remote}) : targetLang = null;

  final String? targetLang;
  final int? nodeId;
  final CatalogRemote? remote;

  @override
  State<CatalogNodeScreen> createState() => _CatalogNodeScreenState();
}

class _NodePage {
  const _NodePage({required this.title, this.subtitle, this.node, required this.children, this.preview});

  final String title;
  final String? subtitle;
  final CatalogNode? node;
  final List<CatalogNode> children;

  /// The words of a lesson, shown on its page.
  final CatalogWordList? preview;
}

class _CatalogNodeScreenState extends State<CatalogNodeScreen> {
  late Future<_NodePage> _page;
  bool _busy = false;

  CatalogRemote get _remote => widget.remote ?? sl<CatalogRemote>();

  @override
  void initState() {
    super.initState();
    _page = _load();
  }

  Future<_NodePage> _load() async {
    final id = widget.nodeId;
    if (id == null) {
      final roots = await _remote.roots(catalogSourceLanguage, widget.targetLang);
      return _NodePage(title: AppStrings.languageName(widget.targetLang), children: roots);
    }
    final detail = await _remote.node(id);
    final node = detail.node;
    final trail = detail.path.length > 1
        ? detail.path.sublist(0, detail.path.length - 1).map((p) => p.title).join(' › ')
        : node.subtitle;
    return _NodePage(
      title: node.title,
      subtitle: trail,
      node: node,
      children: detail.children,
      preview: node.isLesson ? await _remote.words(id) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_NodePage>(
          future: _page,
          builder: (context, snapshot) {
            final page = snapshot.data;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                AppPageHeader(title: page?.title ?? AppStrings.catalogTitle, subtitle: page?.subtitle),
                const SizedBox(height: 8),
                if (snapshot.hasError)
                  _Failure(error: snapshot.error, onRetry: () => setState(() => _page = _load()))
                else if (page == null)
                  const _Loading()
                else ...[
                  if (page.node != null && page.node!.wordCount > 0) ...[
                    _Actions(node: page.node!, busy: _busy, onGradual: _gradual, onAdd: _add, onExcel: _excel),
                    const SizedBox(height: 16),
                  ],
                  if (page.preview != null) _Preview(list: page.preview!),
                  if (page.children.isEmpty && page.preview == null) const _Message(AppStrings.catalogNodeEmpty),
                  for (final (index, child) in page.children.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SoftListTile(
                        title: child.title,
                        subtitle: [
                          if (child.subtitle != null && child.subtitle!.isNotEmpty) child.subtitle!,
                          AppStrings.catalogWords(child.wordCount),
                        ].join(' · '),
                        icon: switch (child.kind) {
                          CatalogNodeKind.lesson => Icons.style_outlined,
                          CatalogNodeKind.course => Icons.school_outlined,
                          CatalogNodeKind.group => Icons.folder_outlined,
                        },
                        accent: _accent(index),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CatalogNodeScreen.node(nodeId: child.id, remote: widget.remote),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Every word under the node; the lesson page already has them.
  Future<CatalogWordList?> _words() async {
    final page = await _page;
    if (page.preview != null) return page.preview;
    try {
      return await _remote.words(widget.nodeId!);
    } catch (error) {
      if (mounted) _snack(_message(error));
      return null;
    }
  }

  Future<void> _gradual() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final list = await _words();
      if (list == null || !mounted) return;
      if (list.wordCount == 0) {
        _snack(AppStrings.catalogNoWords);
        return;
      }
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CatalogGradualScreen(list: list)),
      );
      if (result != null && mounted) _snack(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final list = await _words();
      if (list == null || !mounted) return;
      if (list.wordCount == 0) {
        _snack(AppStrings.catalogNoWords);
        return;
      }
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CatalogAddSheet(list: list),
      );
      if (result != null && mounted) _snack(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _excel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final list = await _words();
      if (list == null || !mounted) return;
      final exported = sl<ExportCatalogExcelUseCase>()(list);
      final saved = await saveExcelFile(context, fileName: exported.fileName, bytes: exported.bytes);
      if (saved && mounted) _snack(AppStrings.catalogExcelSaved);
    } on DeckExportEmptyException {
      if (mounted) _snack(AppStrings.catalogNoWords);
    } catch (_) {
      if (mounted) _snack(AppStrings.catalogExcelFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.node,
    required this.busy,
    required this.onGradual,
    required this.onAdd,
    required this.onExcel,
  });

  final CatalogNode node;
  final bool busy;
  final VoidCallback onGradual;
  final VoidCallback onAdd;
  final VoidCallback onExcel;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.catalogWords(node.wordCount),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (node.description != null && node.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(node.description!, style: TextStyle(fontSize: 13, height: 1.5, color: colors.mutedForeground)),
          ],
          const SizedBox(height: 14),
          if (busy)
            const Row(
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 10),
                Text(AppStrings.catalogLoadingWords),
              ],
            )
          else ...[
            // Gradual first: it is the way that does not bury tomorrow's review.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onGradual,
                icon: const Icon(Icons.schedule_rounded),
                label: const Text(AppStrings.catalogGradual),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(AppStrings.catalogBulkTitle),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onExcel,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text(AppStrings.catalogDownloadExcel),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A lesson's words, so the learner sees what they would add.
class _Preview extends StatelessWidget {
  const _Preview({required this.list});

  final CatalogWordList list;

  static const int shown = 60;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final words = [for (final lesson in list.lessons) ...lesson.words];
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (final (index, word) in words.take(shown).indexed) ...[
            if (index > 0) Divider(height: 1, color: colors.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(word.term, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (word.pronunciation != null && word.pronunciation!.isNotEmpty)
                            Text('/${word.pronunciation}/', style: TextStyle(fontSize: 12, color: colors.mutedForeground)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(word.meaning, style: const TextStyle(height: 1.5))),
                ],
              ),
            ),
          ],
          if (words.length > shown)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(AppStrings.catalogPreviewMore(words.length - shown),
                  style: TextStyle(color: colors.mutedForeground)),
            ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.recallColors.mutedForeground, height: 1.6),
        ),
      );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(_message(error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
          ],
        ),
      );
}

String _message(Object? error) => error is AuthError ? error.message : AppStrings.catalogLoadFailed;

Color _accent(int index) => AppColors.forDeck(DeckColor.values[index % DeckColor.values.length]);
