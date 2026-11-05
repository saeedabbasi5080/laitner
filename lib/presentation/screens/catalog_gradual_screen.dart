import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/usecases/catalog_cards.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/queue_catalog_words_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/widgets/catalog_add_sheet.dart';
import 'package:recall/presentation/widgets/catalog_target_picker.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// The gradual way in, on a page of its own: where the list goes and how many
/// of its cards a day. Pops with the message to show.
class CatalogGradualScreen extends StatefulWidget {
  const CatalogGradualScreen({
    super.key,
    required this.list,
    this.getSpaces,
    this.getDecks,
    this.queueWords,
    this.settingsStore,
  });

  final CatalogWordList list;

  /// Tests pass these; the app uses the registered ones.
  final GetSpacesUseCase? getSpaces;
  final GetDecksUseCase? getDecks;
  final QueueCatalogWordsUseCase? queueWords;
  final SpaceSettingsStore? settingsStore;

  @override
  State<CatalogGradualScreen> createState() => _CatalogGradualScreenState();
}

class _CatalogGradualScreenState extends State<CatalogGradualScreen> {
  static const presets = [10, 20, 30, 50];
  static const defaultPerDay = 20;

  final TextEditingController _custom = TextEditingController();
  CatalogTargetChoice? _choice;

  /// The feed the picked deck already has, if any.
  DailyExcelFeedSettings? _existingFeed;
  int _perDay = defaultPerDay;
  bool _pronunciation = true;
  bool _tagLessons = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  Future<void> _onChoice(CatalogTargetChoice? choice) async {
    setState(() {
      _choice = choice;
      _existingFeed = null;
    });
    final deck = choice?.existingDeck;
    if (deck == null) return;
    final settings = await (widget.settingsStore ?? sl<SpaceSettingsStore>()).load(deck.spaceId);
    if (!mounted || _choice?.existingDeck?.id != deck.id) return;
    setState(() => _existingFeed = settings.dailyExcelFeeds.where((feed) => feed.deckId == deck.id).firstOrNull);
  }

  int get _wordCount => catalogCardRows(
        widget.list.lessons,
        CatalogCardOptions(includePronunciation: _pronunciation, tagLessons: _tagLessons),
      ).length;

  Future<void> _start() async {
    final choice = _choice;
    if (_saving || choice == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await (widget.queueWords ?? sl<QueueCatalogWordsUseCase>())(
        list: widget.list,
        target: choice.target,
        dailyLimit: _perDay,
        options: CatalogCardOptions(includePronunciation: _pronunciation, tagLessons: _tagLessons),
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        result.queued == 0
            ? AppStrings.catalogGradualNothingNew
            : AppStrings.catalogGradualQueued(result.queued, result.addedToday, result.dailyLimit, result.deck.name),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = AppStrings.catalogAddFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final existing = _existingFeed;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            AppPageHeader(
              title: AppStrings.catalogGradual,
              subtitle: '${widget.list.node.title} · ${AppStrings.catalogWords(widget.list.wordCount)}',
            ),
            const SizedBox(height: 8),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule_rounded, color: context.accentColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.catalogGradualHint,
                      style: TextStyle(fontSize: 13, height: 1.7, color: colors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: CatalogTargetPicker(
                defaultName: widget.list.node.title,
                colorSeed: widget.list.node.id,
                enabled: !_saving,
                getSpaces: widget.getSpaces,
                getDecks: widget.getDecks,
                onChanged: _onChoice,
              ),
            ),
            const SizedBox(height: 16),
            SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(AppStrings.catalogGradualPerDay, style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final preset in presets)
                        ChoiceChip(
                          label: Text('$preset'),
                          selected: _perDay == preset && _custom.text.isEmpty,
                          onSelected: _saving
                              ? null
                              : (_) => setState(() {
                                    _custom.clear();
                                    _perDay = preset;
                                  }),
                        ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _custom,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(hintText: AppStrings.catalogGradualCustom, isDense: true),
                          onChanged: (text) {
                            final value = int.tryParse(text);
                            setState(() => _perDay = (value ?? defaultPerDay)
                                .clamp(DailyExcelFeedSettings.minDailyLimit, DailyExcelFeedSettings.maxDailyLimit));
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.catalogGradualEstimate(_wordCount, _perDay),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.accentColor),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.catalogGradualJoins(existing.dailyLimit),
                      style: TextStyle(fontSize: 12, height: 1.7, color: colors.mutedForeground),
                    ),
                  ],
                  CatalogCardOptionTiles(
                    list: widget.list,
                    pronunciation: _pronunciation,
                    tagLessons: _tagLessons,
                    enabled: !_saving,
                    onPronunciation: (value) => setState(() => _pronunciation = value),
                    onTagLessons: (value) => setState(() => _tagLessons = value),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _choice == null || _saving ? null : _start,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(_saving ? AppStrings.catalogAdding : AppStrings.catalogGradualStart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
