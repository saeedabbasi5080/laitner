import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/due_day_utils.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_state.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/deck_list_screen.dart';
import 'package:recall/presentation/screens/settings_screen.dart';
import 'package:recall/presentation/screens/space_cards_screen.dart';
import 'package:recall/presentation/screens/space_list_screen.dart';
import 'package:recall/presentation/screens/statistics_screen.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';
import 'package:recall/presentation/widgets/space_form_sheet.dart';

class AppShellScreen extends StatelessWidget {
  const AppShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SpaceListCubit>()..load(),
      child: const _AppShellView(),
    );
  }
}

class _AppShellView extends StatefulWidget {
  const _AppShellView();

  @override
  State<_AppShellView> createState() => _AppShellViewState();
}

class _AppShellViewState extends State<_AppShellView>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  String? _statsSpaceId;
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
      _reloadSpaces();
      _scheduleDayBoundaryRefresh();
    }
  }

  void _reloadSpaces() {
    if (!mounted) return;
    context.read<SpaceListCubit>().load();
  }

  void _scheduleDayBoundaryRefresh() {
    _dayBoundaryTimer?.cancel();
    _dayBoundaryTimer = Timer(untilNextLocalDay(), () {
      _reloadSpaces();
      _scheduleDayBoundaryRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.collectionEpoch != current.collectionEpoch,
      listener: (context, _) {
        context.read<SpaceListCubit>().load();
      },
      child: BlocBuilder<SpaceListCubit, SpaceListState>(
        builder: (context, spaceState) {
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _HomeTab(spaceState: spaceState),
                const SpaceListScreen(),
                _StatsTab(spaceId: _statsSpaceId),
                const _MoreTab(),
              ],
            ),
            bottomNavigationBar: _buildBottomNav(context, spaceState),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, SpaceListState spaceState) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: AppStrings.navHome,
                isActive: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _NavItem(
                icon: Icons.layers_outlined,
                activeIcon: Icons.layers_rounded,
                label: AppStrings.navSpaces,
                isActive: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _CenterAddButton(
                onTap: () => _handleAdd(context, spaceState),
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: AppStrings.navStats,
                isActive: _currentIndex == 2,
                onTap: () => _openStats(context, spaceState),
              ),
              _NavItem(
                icon: Icons.more_horiz,
                activeIcon: Icons.more_horiz,
                label: AppStrings.navMore,
                isActive: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStats(
    BuildContext context,
    SpaceListState spaceState,
  ) async {
    final space = await pickSpaceOrNotify(
      context,
      spaceState,
      AppStrings.pickSpaceForStats,
    );
    if (space == null || !mounted) return;
    setState(() {
      _statsSpaceId = space.id;
      _currentIndex = 2;
    });
  }

  void _handleAdd(BuildContext context, SpaceListState spaceState) {
    if (!spaceState.canAddSpace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.spaceLimitReached(maxLearningSpaces)),
        ),
      );
      return;
    }
    _showNewSpace(context);
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.spaceState});

  final SpaceListState spaceState;

  @override
  Widget build(BuildContext context) {
    if (spaceState.status == SpaceListStatus.loading &&
        spaceState.summaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (spaceState.status == SpaceListStatus.error &&
        spaceState.summaries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.dataLoadFailed,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.read<SpaceListCubit>().load(),
                child: const Text(AppStrings.retry),
              ),
            ],
          ),
        ),
      );
    }

    final totalDue = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.dueCards,
    );
    final totalCards = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.totalCards,
    );
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: AppStrings.appTitle,
              showBack: false,
            ),
            const SizedBox(height: 8),
            BlobHeroCard(
              label: AppStrings.dueToday,
              value: totalDue,
              onTap: () => _startTodayReview(context),
            ),
            if (totalDue == 0 && totalCards > 0) ...[
              const SizedBox(height: 10),
              Text(
                AppStrings.noDueTodayHint,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.recallColors.mutedForeground,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _SummaryChips(spaceState: spaceState, totalCards: totalCards),
            const SizedBox(height: 16),
            _RecentReviewRow(
              spaceState: spaceState,
              onTap: () => _openReviewedCards(context),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.yourSpaces,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (spaceState.summaries.isEmpty)
              Text(
                AppStrings.emptySpaces,
                style: TextStyle(
                  fontSize: 13,
                  color: context.recallColors.mutedForeground,
                  height: 1.5,
                ),
              )
            else
              ...spaceState.summaries.map(
                (summary) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftListTile(
                    title: summary.space.name,
                    subtitle: '${summary.totalCards} ${AppStrings.cards}',
                    icon: Icons.auto_stories_outlined,
                    accent: AppColors.forDeck(summary.space.color),
                    onTap: () async {
                      await sl<SettingsCubit>().loadForSpace(summary.space.id);
                      if (!context.mounted) return;
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DeckListScreen(space: summary.space),
                        ),
                      );
                      if (context.mounted) {
                        context.read<SpaceListCubit>().load();
                      }
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTodayReview(BuildContext context) async {
    final space = await pickSpaceOrNotify(
      context,
      spaceState,
      AppStrings.pickSpaceForReview,
      subtitle: (selected) {
        final summary = spaceState.summaries.firstWhere(
          (item) => item.space.id == selected.id,
        );
        return '${summary.dueCards} ${AppStrings.due}';
      },
    );
    if (space == null || !context.mounted) return;
    await sl<SettingsCubit>().loadForSpace(space.id);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(
          config: StudyConfig.allDue(spaceId: space.id),
        ),
      ),
    );
    if (context.mounted) context.read<SpaceListCubit>().load();
  }

  Future<void> _openReviewedCards(BuildContext context) async {
    final space = await pickSpaceOrNotify(
      context,
      spaceState,
      AppStrings.pickSpaceForCards,
      subtitle: (selected) {
        final summary = spaceState.summaries.firstWhere(
          (item) => item.space.id == selected.id,
        );
        return '${summary.totalCards} ${AppStrings.cards}';
      },
    );
    if (space == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SpaceCardsScreen(spaceId: space.id),
      ),
    );
    if (context.mounted) context.read<SpaceListCubit>().load();
  }
}

class _SummaryChips extends StatelessWidget {
  const _SummaryChips({required this.spaceState, required this.totalCards});

  final SpaceListState spaceState;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    final totalNew = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.totalCards - s.dueCards,
    );
    final totalDue = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.dueCards,
    );
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircularStat(
          icon: Icons.workspace_premium_outlined,
          value: '$totalCards',
          label: 'یادگرفته',
          color: AppColors.lemon,
        ),
        CircularStat(
          icon: Icons.autorenew_rounded,
          value: '$totalDue',
          label: 'مرور',
          color: AppColors.teal,
        ),
        CircularStat(
          icon: Icons.school_outlined,
          value: '$totalNew',
          label: 'یادگیری',
          color: scheme.primary,
        ),
        CircularStat(
          icon: Icons.auto_awesome,
          value: '${spaceState.summaries.length}',
          label: 'فضا',
          color: AppColors.rose,
        ),
      ],
    );
  }
}

class _RecentReviewRow extends StatelessWidget {
  const _RecentReviewRow({
    required this.spaceState,
    required this.onTap,
  });

  final SpaceListState spaceState;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final totalReviewed = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.totalCards,
    );
    final colors = context.recallColors;
    final scheme = Theme.of(context).colorScheme;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(Icons.style_outlined, color: scheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            '$totalReviewed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            AppStrings.reviewedCardsHome,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: colors.mutedForeground),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({this.spaceId});

  final String? spaceId;

  @override
  Widget build(BuildContext context) {
    if (spaceId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppStrings.pickSpaceForStats,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.recallColors.mutedForeground,
            ),
          ),
        ),
      );
    }
    return StatisticsScreen(
      key: ValueKey(spaceId),
      spaceId: spaceId!,
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen();
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  const _CenterAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.add, color: scheme.onPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}

Future<LearningSpace?> pickSpaceOrNotify(
  BuildContext context,
  SpaceListState spaceState,
  String title, {
  String Function(LearningSpace space)? subtitle,
}) async {
  if (spaceState.summaries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.createSpaceFirst)),
    );
    return null;
  }
  return showPickSpaceDialog(
    context,
    spaces: [for (final summary in spaceState.summaries) summary.space],
    title: title,
    subtitle: subtitle,
  );
}

void _showNewSpace(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SpaceFormSheet(
      onSubmit: (name, color) async {
        try {
          await context.read<SpaceListCubit>().addSpace(name, color);
        } on SpaceLimitReachedException {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppStrings.spaceLimitReached(maxLearningSpaces),
                ),
              ),
            );
          }
          rethrow;
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.spaceSaveFailed)),
            );
          }
          rethrow;
        }
      },
    ),
  );
}
