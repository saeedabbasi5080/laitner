import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/usecases/add_catalog_words_usecase.dart';
import 'package:recall/domain/usecases/catalog_cards.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/widgets/catalog_target_picker.dart';

/// The direct way in: every word of a ready-made list becomes a card now, in
/// a new deck or an existing one. Pops with the message to show, or nothing if
/// the learner closed it.
///
/// More than [AppStrings.catalogBulkWarnAbove] cards are asked about first:
/// all of them start in the first house, which is a large review tomorrow.
class CatalogAddSheet extends StatefulWidget {
  const CatalogAddSheet({
    super.key,
    required this.list,
    this.getSpaces,
    this.getDecks,
    this.addWords,
  });

  final CatalogWordList list;

  /// Tests pass these; the app uses the registered ones.
  final GetSpacesUseCase? getSpaces;
  final GetDecksUseCase? getDecks;
  final AddCatalogWordsUseCase? addWords;

  @override
  State<CatalogAddSheet> createState() => _CatalogAddSheetState();
}

class _CatalogAddSheetState extends State<CatalogAddSheet> {
  CatalogTargetChoice? _choice;
  bool _pronunciation = true;
  bool _tagLessons = true;
  bool _saving = false;
  String? _error;

  bool get _canSave => !_saving && _choice != null;

  Future<void> _save() async {
    final choice = _choice;
    if (!_canSave || choice == null) return;
    final options = CatalogCardOptions(includePronunciation: _pronunciation, tagLessons: _tagLessons);
    final count = catalogCardRows(widget.list.lessons, options).length;
    // Asked, not refused: some learners want exactly that.
    if (count > AppStrings.catalogBulkWarnAbove && !await _confirmBulk(count)) return;
    if (!mounted) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await (widget.addWords ?? sl<AddCatalogWordsUseCase>())(
        list: widget.list,
        target: choice.target,
        options: options,
      );
      if (mounted) Navigator.pop(context, AppStrings.catalogAdded(result.added, result.skipped, result.deck.name));
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppStrings.catalogAddFailed;
        });
      }
    }
  }

  Future<bool> _confirmBulk(int count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(AppStrings.catalogBulkTitle),
        content: Text(AppStrings.catalogBulkWarning(count), style: const TextStyle(height: 1.7)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.catalogBulkConfirm)),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.catalogBulkTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${widget.list.node.title} · ${AppStrings.catalogWords(widget.list.wordCount)}',
                  style: TextStyle(fontSize: 13, color: colors.mutedForeground),
                ),
                const SizedBox(height: 18),
                CatalogTargetPicker(
                  defaultName: widget.list.node.title,
                  colorSeed: widget.list.node.id,
                  enabled: !_saving,
                  getSpaces: widget.getSpaces,
                  getDecks: widget.getDecks,
                  onChanged: (choice) => setState(() => _choice = choice),
                ),
                CatalogCardOptionTiles(
                  list: widget.list,
                  pronunciation: _pronunciation,
                  tagLessons: _tagLessons,
                  enabled: !_saving,
                  onPronunciation: (value) => setState(() => _pronunciation = value),
                  onTagLessons: (value) => setState(() => _tagLessons = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    child: Text(_saving ? AppStrings.catalogAdding : AppStrings.catalogAdd),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The two card options, shown only when they would change anything.
class CatalogCardOptionTiles extends StatelessWidget {
  const CatalogCardOptionTiles({
    super.key,
    required this.list,
    required this.pronunciation,
    required this.tagLessons,
    required this.onPronunciation,
    required this.onTagLessons,
    this.enabled = true,
  });

  final CatalogWordList list;
  final bool pronunciation;
  final bool tagLessons;
  final ValueChanged<bool> onPronunciation;
  final ValueChanged<bool> onTagLessons;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasPronunciation =
        list.lessons.any((lesson) => lesson.words.any((word) => (word.pronunciation ?? '').trim().isNotEmpty));
    final hasLessons = list.lessons.where((lesson) => lesson.words.isNotEmpty).length > 1;
    return Column(
      children: [
        if (hasPronunciation)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: pronunciation,
            title: const Text(AppStrings.catalogIncludePronunciation),
            onChanged: enabled ? (value) => onPronunciation(value ?? true) : null,
          ),
        if (hasLessons)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: tagLessons,
            title: const Text(AppStrings.catalogTagLessons),
            onChanged: enabled ? (value) => onTagLessons(value ?? true) : null,
          ),
      ],
    );
  }
}
