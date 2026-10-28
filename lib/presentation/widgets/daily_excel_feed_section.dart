import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/daily_feed/daily_feed_cubit.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Settings for the automatic daily Excel feed.
///
/// The section follows the shape of Anki's new-cards-per-day limit: a toggle, a
/// destination deck, the files to draw from, and one number that decides how
/// much of them is released per day. The backlog is shown rather than hidden,
/// because a feed that stopped at the cap looks broken unless it says so.
class DailyExcelFeedSection extends StatelessWidget {
  const DailyExcelFeedSection({
    super.key,
    required this.spaceId,
    required this.settings,
    required this.onChanged,
  });

  final String spaceId;
  final DailyExcelFeedSettings settings;
  final ValueChanged<DailyExcelFeedSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DailyFeedCubit>(param1: spaceId)..load(),
      child: _DailyFeedView(
        spaceId: spaceId,
        settings: settings,
        onChanged: onChanged,
      ),
    );
  }
}

class _DailyFeedView extends StatelessWidget {
  const _DailyFeedView({
    required this.spaceId,
    required this.settings,
    required this.onChanged,
  });

  final String spaceId;
  final DailyExcelFeedSettings settings;
  final ValueChanged<DailyExcelFeedSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyFeedCubit, DailyFeedState>(
      builder: (context, state) {
        final feed = settings;
        final deck = state.deckNamed(feed.deckId);
        final backlog = state.backlogFor(feed);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              value: feed.enabled,
              onChanged: (value) =>
                  onChanged(feed.copyWith(enabled: value)),
              title: const Text(AppStrings.dailyExcelFeed),
              subtitle: const Text(AppStrings.dailyExcelFeedHint),
            ),
            if (feed.needsSetup)
              _FeedWarning(message: AppStrings.dailyFeedPickDeckHint),
            if (feed.enabled) ...[
              const SizedBox(height: 8),
              _DeckPickerTile(
                deckName: deck?.name,
                onPick: () => _pickDeck(context, deck),
              ),
              const SizedBox(height: 12),
              _FilesTile(
                settings: feed,
                imports: state.imports,
                onChanged: onChanged,
              ),
              const SizedBox(height: 12),
              _DailyLimitTile(
                settings: feed,
                onChanged: (limit) =>
                    onChanged(feed.copyWith(dailyLimit: limit)),
              ),
              const SizedBox(height: 12),
              _FeedStatus(
                settings: feed,
                backlog: backlog,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: state.running ||
                          !feed.isConfigured ||
                          state.loading
                      ? null
                      : () => _runNow(context),
                  icon: state.running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    state.running
                        ? AppStrings.dailyFeedRunning
                        : AppStrings.dailyFeedRunNow,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.dailyFeedCatchUpNote,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  color: context.recallColors.mutedForeground,
                ),
              ),
              if (state.lastResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.lastResult!.addedCount > 0
                      ? AppStrings.dailyFeedAddedNow(
                          state.lastResult!.addedCount,
                        )
                      : AppStrings.dailyFeedNothingToAdd,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.accentColor,
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _runNow(BuildContext context) async {
    await context.read<DailyFeedCubit>().runNow();
    // The run wrote the new last-run day and backlog straight to the store, so
    // the surrounding settings state has to be re-read or the status card would
    // keep showing yesterday's numbers.
    if (!context.mounted) return;
    await context.read<SettingsCubit>().loadForSpace(spaceId);
  }

  Future<void> _pickDeck(BuildContext context, Deck? current) async {
    final decks = context.read<DailyFeedCubit>().state.decks;
    if (decks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.dailyFeedNoDeckYet)),
      );
      return;
    }

    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final deck in decks)
              ListTile(
                leading: Icon(
                  deck.id == current?.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(deck.name),
                onTap: () => Navigator.of(context).pop(deck.id),
              ),
          ],
        ),
      ),
    );

    if (picked == null) return;
    onChanged(settings.copyWith(deckId: picked));
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
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: context.recallColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeckPickerTile extends StatelessWidget {
  const _DeckPickerTile({required this.deckName, required this.onPick});

  final String? deckName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      title: AppStrings.dailyFeedPickDeck,
      subtitle: deckName ?? AppStrings.dailyFeedNoDeck,
      icon: Icons.folder_outlined,
      accent: context.accentColor,
      onTap: onPick,
    );
  }
}

class _FilesTile extends StatelessWidget {
  const _FilesTile({
    required this.settings,
    required this.imports,
    required this.onChanged,
  });

  final DailyExcelFeedSettings settings;
  final List<ExcelImport> imports;
  final ValueChanged<DailyExcelFeedSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final chosen = settings.importIds
        .map(
          (id) => imports.where((import) => import.id == id).firstOrNull,
        )
        .whereType<ExcelImport>()
        .toList();

    final subtitle = chosen.isEmpty
        ? AppStrings.dailyFeedNoFiles
        : AppStrings.dailyFeedSelectedFiles(chosen.length);

    return SoftListTile(
      title: AppStrings.dailyFeedPickFiles,
      subtitle: subtitle,
      icon: Icons.table_chart_outlined,
      accent: context.accentColor,
      onTap: () => _chooseFiles(context, chosen),
    );
  }

  Future<void> _chooseFiles(
    BuildContext context,
    List<ExcelImport> chosen,
  ) async {
    if (imports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.dailyFeedNoLibraryFiles)),
      );
      return;
    }

    final selected = chosen.map((import) => import.id).toSet();

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DailyFileChooserSheet(
        imports: imports,
        selected: selected,
      ),
    );

    if (result == null) return;
    onChanged(settings.copyWith(importIds: result));
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
  });

  final List<ExcelImport> imports;
  final Set<String> selected;

  @override
  State<DailyFileChooserSheet> createState() => _DailyFileChooserSheetState();
}

class _DailyFileChooserSheetState extends State<DailyFileChooserSheet> {
  late Set<String> _selected = {...widget.selected};

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
                  Expanded(
                    child: Text(
                      AppStrings.dailyFeedManageFiles,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_selected.toList()),
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
                          style: TextStyle(
                            fontSize: 13,
                            color: context.recallColors.mutedForeground,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final import in widget.imports)
                          CheckboxListTile(
                            value: _selected.contains(import.id),
                            onChanged: (value) => setState(() {
                              if (value ?? false) {
                                _selected.add(import.id);
                              } else {
                                _selected.remove(import.id);
                              }
                            }),
                            title: Text(
                              import.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              AppStrings.dailyFeedFileCounts(
                                import.pendingCount,
                                import.addedCount,
                              ),
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

class _DailyLimitTile extends StatelessWidget {
  const _DailyLimitTile({required this.settings, required this.onChanged});

  final DailyExcelFeedSettings settings;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      title: AppStrings.dailyFeedDailyLimit,
      subtitle: '${settings.dailyLimit}',
      icon: Icons.speed_outlined,
      accent: context.accentColor,
      onTap: () => _edit(context),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final controller = TextEditingController(
      text: settings.dailyLimit.toString(),
    );

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
              decoration: const InputDecoration(
                hintText: AppStrings.dailyFeedDailyLimitHint,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final preset in const [50, 100, 200, 500])
                  ActionChip(
                    label: Text('$preset'),
                    onPressed: () => controller.text = '$preset',
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null) return;
              Navigator.of(context).pop(value);
            },
            child: const Text(AppStrings.done),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;
    // Clamped here rather than at write time so the field can never hold a
    // value the run would treat as "off".
    onChanged(
      result.clamp(
        DailyExcelFeedSettings.minDailyLimit,
        DailyExcelFeedSettings.maxDailyLimit,
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
          _StatusRow(
            label: AppStrings.dailyFeedBacklog,
            value: '$backlog',
          ),
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
    final isToday = that.year == today.year &&
        that.month == today.month &&
        that.day == today.day;
    return isToday
        ? AppStrings.dailyFeedLastRunToday(added)
        : AppStrings.dailyFeedLastRunCount(added);
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
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}