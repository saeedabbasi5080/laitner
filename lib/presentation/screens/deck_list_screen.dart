import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/responsive.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/deck_list/deck_list_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/add_card_screen.dart';
import 'package:recall/presentation/screens/box_cards_screen.dart';
import 'package:recall/presentation/screens/deck_detail_screen.dart';
import 'package:recall/presentation/screens/excel_library_screen.dart';
import 'package:recall/presentation/screens/learned_cards_screen.dart';
import 'package:recall/presentation/screens/settings_screen.dart';
import 'package:recall/presentation/screens/statistics_screen.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';
import 'package:recall/presentation/widgets/free_review_sheet.dart';

class DeckListScreen extends StatelessWidget {
  const DeckListScreen({super.key, required this.space});

  final LearningSpace space;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeckListCubit>(param1: space.id)..load(),
      child: _DeckListView(space: space),
    );
  }
}

class _DeckListView extends StatefulWidget {
  const _DeckListView({required this.space});

  final LearningSpace space;

  @override
  State<_DeckListView> createState() => _DeckListViewState();
}

class _DeckListViewState extends State<_DeckListView>
    with WidgetsBindingObserver {
  Timer? _dayBoundaryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayBoundaryRefresh();
  }

  @override
  void dispose() {
    _dayBoundaryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DeckListCubit>().load();
      _scheduleDayBoundaryRefresh();
    }
  }

  void _scheduleDayBoundaryRefresh() {
    _dayBoundaryTimer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _dayBoundaryTimer = Timer(
      nextDay.difference(now) + const Duration(seconds: 1),
      () {
        if (!mounted) return;
        context.read<DeckListCubit>().load();
        _scheduleDayBoundaryRefresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DeckListCubit, DeckListState>(
          builder: (context, state) {
            if (state.status == DeckListStatus.loading && state.decks.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    context.pageHorizontalPadding,
                    24,
                    context.pageHorizontalPadding,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleIconButton(
                            back: true,
                            icon: Icons.arrow_back,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.today,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.space.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: context.isCompactWidth ? 24 : 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              CircleIconButton(
                                icon: Icons.insights_outlined,
                                label: AppStrings.statistics,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StatisticsScreen(
                                      spaceId: widget.space.id,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              CircleIconButton(
                                icon: Icons.settings_outlined,
                                label: AppStrings.settings,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SettingsScreen(
                                      spaceId: widget.space.id,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      StatCard(
                        label: AppStrings.dueToday,
                        value: state.totalDue,
                        accent: true,
                        onTap: () => _openAllDueStudy(context),
                      ),
                      const SizedBox(height: 24),
                      const SectionLabel(AppStrings.boxOverview),
                      const SizedBox(height: 12),
                      _BoxOverviewRow(
                        boxCounts: state.boxCounts,
                        onBoxTap: (box) => _openBoxCards(context, box),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _openLearnedCards(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.workspace_premium_outlined,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppStrings.learnedCards,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onTertiaryContainer,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${state.learnedCount}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onTertiaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_left,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onTertiaryContainer,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (state.boxCounts.values.any((c) => c > 0)) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await showFreeReviewSheet(
                                context,
                                spaceId: widget.space.id,
                                boxCounts: state.boxCounts,
                              );
                              if (context.mounted) {
                                context.read<DeckListCubit>().load();
                              }
                            },
                            icon: const Icon(Icons.replay, size: 18),
                            label: const Text(AppStrings.freeReview),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      if (state.decks.isEmpty)
                        _EmptyDecks()
                      else
                        ...state.decks.map(
                          (deck) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DeckCard(
                              deck: deck,
                              total: state.totalCounts[deck.id] ?? 0,
                              due: state.dueCounts[deck.id] ?? 0,
                              onStudy: () => _openStudy(context, deck.id),
                              onEdit: () => _editDeck(context, deck),
                              onOpenDetail: () => _openDetail(context, deck.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Material(
                      elevation: 0,
                      color: context.accentColor,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 4,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showAddMenu(context, state),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.floating(context),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 28,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context, DeckListState state) {
    showAddMenuSheet(
      context,
      decks: state.decks,
      onAddDeck: () => _showNewDeck(context),
      onAddCard: (deckId) => _openAddCard(context, deckId),
      onImportExcel: () => Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ExcelLibraryScreen(spaceId: widget.space.id),
            ),
          )
          .then((_) {
            if (context.mounted) context.read<DeckListCubit>().load();
          }),
    );
  }

  void _showNewDeck(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeckFormSheet(
        onSubmit: (name, color) =>
            context.read<DeckListCubit>().addDeck(name, color),
      ),
    );
  }

  void _editDeck(BuildContext context, Deck deck) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeckFormSheet(
        deck: deck,
        onSubmit: (name, color) => context.read<DeckListCubit>().updateDeck(
          deck.copyWith(name: name.trim(), color: color),
        ),
        onDelete: () async {
          final confirmed = await showConfirmDialog(
            context,
            title: AppStrings.deleteDeck,
            message: AppStrings.deleteDeckConfirm,
          );
          if (confirmed == true && context.mounted) {
            await context.read<DeckListCubit>().deleteDeck(deck.id);
          }
        },
      ),
    );
  }

  void _openStudy(BuildContext context, String deckId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => StudyScreen(
              config: StudyConfig.deck(
                spaceId: widget.space.id,
                deckId: deckId,
              ),
            ),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<DeckListCubit>().load();
        });
  }

  void _openAllDueStudy(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => StudyScreen(
              config: StudyConfig.allDue(spaceId: widget.space.id),
            ),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<DeckListCubit>().load();
        });
  }

  void _openBoxCards(BuildContext context, int box) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => BoxCardsScreen(
              boxNumber: box,
              spaceId: widget.space.id,
            ),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<DeckListCubit>().load();
        });
  }

  void _openLearnedCards(BuildContext context) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => LearnedCardsScreen(spaceId: widget.space.id),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<DeckListCubit>().load();
        });
  }

  void _openAddCard(BuildContext context, String deckId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => AddCardScreen(
              deckId: deckId,
              spaceId: widget.space.id,
            ),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<DeckListCubit>().load();
        });
  }

  void _openDetail(BuildContext context, String deckId) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => DeckDetailScreen(
              deckId: deckId,
              spaceId: widget.space.id,
            ),
          ),
        )
        .then((_) {
          if (context.mounted) context.read<DeckListCubit>().load();
        });
  }
}

class _BoxOverviewRow extends StatelessWidget {
  const _BoxOverviewRow({required this.boxCounts, required this.onBoxTap});

  final Map<int, int> boxCounts;
  final ValueChanged<int> onBoxTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(maxBox, (index) {
        final box = index + 1;
        final count = boxCounts[box] ?? 0;
        final (fill, onFill) = context.leitnerBoxColors(box);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index < maxBox - 1 ? 8 : 0),
            child: Material(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onBoxTap(box),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: onFill.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${AppStrings.box} $box',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 11,
                            color: onFill.withValues(alpha: 0.78),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$count',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: onFill,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyDecks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 32, color: colors.mutedForeground),
          const SizedBox(height: 12),
          Text(
            AppStrings.emptyDecks,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.deck,
    required this.total,
    required this.due,
    required this.onStudy,
    required this.onEdit,
    required this.onOpenDetail,
  });

  final Deck deck;
  final int total;
  final int due;
  final VoidCallback onStudy;
  final VoidCallback onEdit;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final accent = AppColors.forDeck(deck.color);
    final progress = total > 0 ? ((total - due) / total).clamp(0.0, 1.0) : 0.0;

    return Material(
      color: context.tintedSurface(accent),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onStudy,
        onLongPress: onOpenDetail,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.card(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: colors.muted,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: colors.mutedForeground,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: due > 0 ? accent : colors.muted,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  due > 0 ? '$due ${AppStrings.due}' : AppStrings.done,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: due > 0
                        ? Colors.white
                        : colors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
