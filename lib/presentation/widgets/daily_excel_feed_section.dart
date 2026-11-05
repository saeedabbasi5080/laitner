import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/daily_feed/daily_feed_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// The daily Excel feeds of one space: one per deck, each with its own files
/// and its own number of new cards a day, in the shape of Anki's new-cards-per-
/// day limit. Each opens on a page of its own to be set up.
///
/// The backlog is shown rather than hidden, because a feed that stopped at its
/// cap looks broken unless it says so.
class DailyExcelFeedSection extends StatelessWidget {
  const DailyExcelFeedSection({
    super.key,
    required this.spaceId,
    required this.feeds,
    required this.onSave,
    required this.onRemove,
  });

  final String spaceId;
  final List<DailyExcelFeedSettings> feeds;
  final Future<void> Function(DailyExcelFeedSettings feed) onSave;
  final Future<void> Function(String feedId) onRemove;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DailyFeedCubit>(param1: spaceId)..load(),
      child: _FeedList(spaceId: spaceId, feeds: feeds, onSave: onSave, onRemove: onRemove),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.spaceId, required this.feeds, required this.onSave, required this.onRemove});

  final String spaceId;
  final List<DailyExcelFeedSettings> feeds;
  final Future<void> Function(DailyExcelFeedSettings feed) onSave;
  final Future<void> Function(String feedId) onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return BlocBuilder<DailyFeedCubit, DailyFeedState>(
      builder: (context, state) {
        final anyReady = feeds.any((feed) => feed.isConfigured);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.dailyFeedListHint,
              style: TextStyle(fontSize: 12, height: 1.6, color: colors.mutedForeground),
            ),
            const SizedBox(height: 12),
            for (final feed in feeds)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FeedTile(
                  feed: feed,
                  deck: state.deckNamed(feed.deckId),
                  backlog: state.backlogFor(feed),
                  onTap: () => _open(context, feed),
                ),
              ),
            OutlinedButton.icon(
              onPressed: state.loading ? null : () => _open(context, null),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.dailyFeedAdd),
            ),
            if (anyReady) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: state.running || state.loading ? null : () => _runNow(context),
                  icon: state.running
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(state.running ? AppStrings.dailyFeedRunning : AppStrings.dailyFeedRunNow),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.dailyFeedCatchUpNote,
                style: TextStyle(fontSize: 11, height: 1.7, color: colors.mutedForeground),
              ),
              if (state.lastResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.lastResult!.addedCount > 0
                      ? AppStrings.dailyFeedAddedNow(state.lastResult!.addedCount)
                      : AppStrings.dailyFeedNothingToAdd,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.accentColor),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _open(BuildContext context, DailyExcelFeedSettings? feed) async {
    final cubit = context.read<DailyFeedCubit>();
    final state = cubit.state;
    final others = feeds.where((other) => other.id != feed?.id);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DailyFeedEditorScreen(
          feed: feed ?? DailyExcelFeedSettings(id: sl<IdGenerator>().generateId(), enabled: true),
          isNew: feed == null,
          decks: state.decks,
          imports: state.imports,
          takenDeckIds: {for (final other in others) ?other.deckId},
          takenImportIds: {for (final other in others) ...other.importIds},
          onSave: onSave,
          onRemove: onRemove,
        ),
      ),
    );
    await cubit.load();
  }

  Future<void> _runNow(BuildContext context) async {
    await context.read<DailyFeedCubit>().runNow();
    // The run wrote the new last-run day and backlog straight to the store, so
    // the surrounding settings state has to be re-read or the tiles would keep
    // showing yesterday's numbers.
    if (!context.mounted) return;
    await context.read<SettingsCubit>().loadForSpace(spaceId);
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.feed, required this.deck, required this.backlog, required this.onTap});

  final DailyExcelFeedSettings feed;
  final Deck? deck;
  final int backlog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = deck?.name ?? (feed.deckId == null ? AppStrings.dailyFeedNoDeck : AppStrings.dailyFeedDeckMissing);
    final subtitle = feed.enabled
        ? AppStrings.dailyFeedSummary(feed.dailyLimit, backlog)
        : '${AppStrings.dailyFeedPaused} · ${AppStrings.dailyFeedSummary(feed.dailyLimit, backlog)}';
    return SoftListTile(
      title: title,
      subtitle: subtitle,
      icon: feed.enabled ? Icons.schedule_rounded : Icons.pause_circle_outline,
      accent: deck == null ? AppColors.lemon : AppColors.forDeck(deck!.color),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_left),
    );
  }
}

/// One feed on a page of its own: its deck, its files, how many a day, on or
/// off. Nothing is written until "save".
///
/// A deck has at most one feed, and a file feeds at most one deck: two feeds
/// drawing on one file would race for the same rows, so what other feeds use
/// is shown and cannot be picked.
class DailyFeedEditorScreen extends StatefulWidget {
  const DailyFeedEditorScreen({
    super.key,
    required this.feed,
    required this.isNew,
    required this.decks,
    required this.imports,
    required this.takenDeckIds,
    required this.takenImportIds,
    required this.onSave,
    required this.onRemove,
  });

  final DailyExcelFeedSettings feed;
  final bool isNew;
  final List<Deck> decks;
  final List<ExcelImport> imports;
  final Set<String> takenDeckIds;
  final Set<String> takenImportIds;
  final Future<void> Function(DailyExcelFeedSettings feed) onSave;
  final Future<void> Function(String feedId) onRemove;

  @override
  State<DailyFeedEditorScreen> createState() => _DailyFeedEditorScreenState();
}

class _DailyFeedEditorScreenState extends State<DailyFeedEditorScreen> {
  late DailyExcelFeedSettings _feed = widget.feed;
  bool _saving = false;

  Deck? get _deck => widget.decks.where((deck) => deck.id == _feed.deckId).firstOrNull;

  int get _backlog {
    final wanted = _feed.importIds.toSet();
    return widget.imports.where((import) => wanted.contains(import.id)).fold(0, (sum, import) => sum + import.pendingCount);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_feed);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.dailyFeedDelete),
        content: const Text(AppStrings.dailyFeedDeleteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.dailyFeedDelete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    await widget.onRemove(_feed.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            AppPageHeader(
              title: widget.isNew ? AppStrings.dailyFeedNewTitle : AppStrings.dailyFeedEditTitle,
              subtitle: _deck?.name,
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              value: _feed.enabled,
              onChanged: _saving ? null : (value) => setState(() => _feed = _feed.copyWith(enabled: value)),
              title: const Text(AppStrings.dailyFeedEnabled),
              subtitle: const Text(AppStrings.dailyExcelFeedHint),
            ),
            if (_feed.deckId == null) const _FeedWarning(message: AppStrings.dailyFeedPickDeckHint),
            const SizedBox(height: 12),
            SoftListTile(
              title: AppStrings.dailyFeedPickDeck,
              subtitle: _deck?.name ?? (_feed.deckId == null ? AppStrings.dailyFeedNoDeck : AppStrings.dailyFeedDeckMissing),
              icon: Icons.folder_outlined,
              accent: context.accentColor,
              onTap: _saving ? null : _pickDeck,
            ),
            const SizedBox(height: 12),
            SoftListTile(
              title: AppStrings.dailyFeedPickFiles,
              subtitle: _feed.importIds.isEmpty
                  ? AppStrings.dailyFeedNoFiles
                  : AppStrings.dailyFeedSelectedFiles(_feed.importIds.length),
              icon: Icons.table_chart_outlined,
              accent: context.accentColor,
              onTap: _saving ? null : _pickFiles,
            ),
            const SizedBox(height: 12),
            SoftListTile(
              title: AppStrings.dailyFeedDailyLimit,
              subtitle: '${_feed.dailyLimit}',
              icon: Icons.speed_outlined,
              accent: context.accentColor,
              onTap: _saving ? null : _editLimit,
            ),
            const SizedBox(height: 12),
            _FeedStatus(settings: _feed, backlog: _backlog),
            const SizedBox(height: 12),
            Text(
              AppStrings.dailyFeedCatchUpNote,
              style: TextStyle(fontSize: 11, height: 1.7, color: colors.mutedForeground),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving || _feed.deckId == null ? null : _save,
                child: const Text(AppStrings.dailyFeedSave),
              ),
            ),
            if (!widget.isNew) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _saving ? null : _remove,
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                  label: Text(AppStrings.dailyFeedDelete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDeck() async {
    if (widget.decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.dailyFeedNoDeckYet)));
      return;
    }
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final deck in widget.decks)
              ListTile(
                enabled: !widget.takenDeckIds.contains(deck.id),
                leading: Icon(
                  deck.id == _feed.deckId ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                ),
                title: Text(deck.name),
                subtitle: widget.takenDeckIds.contains(deck.id) ? const Text(AppStrings.dailyFeedDeckTaken) : null,
                onTap: () => Navigator.of(context).pop(deck.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _feed = _feed.copyWith(deckId: picked));
  }

  Future<void> _pickFiles() async {
    if (widget.imports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.dailyFeedNoLibraryFiles)));
      return;
    }
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DailyFileChooserSheet(
        imports: widget.imports,
        selected: _feed.importIds.toSet(),
        taken: widget.takenImportIds,
      ),
    );
    if (result == null) return;
    // In the order they were in, then the new ones: the feed drains oldest first.
    final kept = [for (final id in _feed.importIds) if (result.contains(id)) id];
    setState(() => _feed = _feed.copyWith(importIds: [...kept, for (final id in result) if (!kept.contains(id)) id]));
  }

  Future<void> _editLimit() async {
    final controller = TextEditingController(text: _feed.dailyLimit.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.dailyFeedDailyLimit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: AppStrings.dailyFeedDailyLimitHint),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in const [10, 20, 50, 100, 200])
                  ActionChip(label: Text('$preset'), onPressed: () => controller.text = '$preset'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text(AppStrings.cancel)),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value != null) Navigator.of(context).pop(value);
            },
            child: const Text(AppStrings.done),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    // Clamped here so the field can never hold a value the run treats as "off".
    setState(() => _feed = _feed.copyWith(
          dailyLimit: result.clamp(DailyExcelFeedSettings.minDailyLimit, DailyExcelFeedSettings.maxDailyLimit),
        ));
  }
}

class _FeedWarning extends StatelessWidget {
  const _FeedWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lemon.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, height: 1.6, color: context.recallColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Picks which Excel files feed a deck.
///
/// Public and free of the cubit so it can be exercised on its own. The height
/// is stated outright rather than left to a shrink-wrapped list inside a
/// flexible slot: that combination resolves to zero, which is what made this
/// sheet open blank.
class DailyFileChooserSheet extends StatefulWidget {
  const DailyFileChooserSheet({
    super.key,
    required this.imports,
    required this.selected,
    this.taken = const {},
  });

  final List<ExcelImport> imports;
  final Set<String> selected;

  /// Files another deck's feed already draws on; shown, but not pickable.
  final Set<String> taken;

  @override
  State<DailyFileChooserSheet> createState() => _DailyFileChooserSheetState();
}

class _DailyFileChooserSheetState extends State<DailyFileChooserSheet> {
  late final Set<String> _selected = {...widget.selected};

  @override
  Widget build(BuildContext context) {
    // Bounded so a long library scrolls within the sheet instead of pushing
    // the list past the bottom of the screen.
    final available = MediaQuery.sizeOf(context).height;
    final height = (available * 0.7).clamp(220.0, available);

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.dailyFeedManageFiles,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_selected.toList()),
                    child: const Text(AppStrings.done),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.imports.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          AppStrings.dailyFeedNoFiles,
                          style: TextStyle(fontSize: 13, color: context.recallColors.mutedForeground),
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final import in widget.imports)
                          CheckboxListTile(
                            value: _selected.contains(import.id),
                            onChanged: widget.taken.contains(import.id)
                                ? null
                                : (value) => setState(() {
                                      if (value ?? false) {
                                        _selected.add(import.id);
                                      } else {
                                        _selected.remove(import.id);
                                      }
                                    }),
                            title: Text(import.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              widget.taken.contains(import.id)
                                  ? AppStrings.dailyFeedFileTaken
                                  : AppStrings.dailyFeedFileCounts(import.pendingCount, import.addedCount),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedStatus extends StatelessWidget {
  const _FeedStatus({required this.settings, required this.backlog});

  final DailyExcelFeedSettings settings;
  final int backlog;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.field),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusRow(label: AppStrings.dailyFeedBacklog, value: '$backlog'),
          const SizedBox(height: 8),
          _StatusRow(
            label: AppStrings.dailyFeedLastRun,
            value: _lastRunLabel(settings.lastRunDay, settings.lastRunAdded),
          ),
        ],
      ),
    );
  }

  /// Names the day the last run happened rather than a raw day number, which
  /// would be meaningless to anyone but the code that wrote it.
  static String _lastRunLabel(int? lastRunDay, int added) {
    if (lastRunDay == null) return AppStrings.dailyFeedNeverRun;
    final today = DateTime.now();
    final that = DateTime.fromMillisecondsSinceEpoch(lastRunDay * 86400000);
    final isToday = that.year == today.year && that.month == today.month && that.day == today.day;
    return isToday ? AppStrings.dailyFeedLastRunToday(added) : AppStrings.dailyFeedLastRunCount(added);
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: colors.mutedForeground))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
