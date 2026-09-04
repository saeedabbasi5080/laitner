import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_state.dart';
import 'package:recall/presentation/screens/deck_list_screen.dart';
import 'package:recall/presentation/screens/settings_screen.dart';
import 'package:recall/presentation/screens/space_list_screen.dart';
import 'package:recall/presentation/screens/statistics_screen.dart';
import 'package:recall/presentation/widgets/space_form_sheet.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SpaceListCubit>()..load(),
      child: BlocBuilder<SpaceListCubit, SpaceListState>(
        builder: (context, spaceState) {
          return Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _HomeTab(spaceState: spaceState),
                const SpaceListScreen(),
                _StatsTab(spaceState: spaceState),
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
    final colors = context.recallColors;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
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
                icon: Icons.insights_outlined,
                activeIcon: Icons.insights_rounded,
                label: AppStrings.navStats,
                isActive: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _NavItem(
                icon: Icons.more_horiz_outlined,
                activeIcon: Icons.more_horiz_rounded,
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

  void _handleAdd(BuildContext context, SpaceListState spaceState) {
    if (spaceState.summaries.isEmpty) {
      _showNewSpace(context);
    } else {
      final firstSpace = spaceState.summaries.first.space;
      sl<SettingsCubit>().loadForSpace(firstSpace.id);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DeckListScreen(space: firstSpace),
        ),
      ).then((_) {
        if (context.mounted) context.read<SpaceListCubit>().load();
      });
    }
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
          }
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.spaceState});

  final SpaceListState spaceState;

  @override
  Widget build(BuildContext context) {
    if (spaceState.summaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final totalDue = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.dueCards,
    );
    final totalCards = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.totalCards,
    );
    final colors = context.recallColors;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.appTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                Icon(Icons.menu, color: colors.mutedForeground),
              ],
            ),
            const SizedBox(height: 20),
            _HeroCard(totalDue: totalDue),
            const SizedBox(height: 16),
            _SummaryChips(spaceState: spaceState, totalCards: totalCards),
            const SizedBox(height: 24),
            _RecentReviewRow(spaceState: spaceState),
            const SizedBox(height: 24),
            Text(
              AppStrings.yourSpaces,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...spaceState.summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SpaceListTile(
                  name: summary.space.name,
                  cardCount: summary.totalCards,
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
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.totalDue});

  final int totalDue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.7),
            scheme.tertiary.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            AppStrings.dueToday,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalDue',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
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
    final colors = context.recallColors;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        _ChipStat(
          icon: Icons.school_outlined,
          value: '$totalCards',
          label: 'یادگرفته',
          color: scheme.primary,
          bgColor: colors.card,
        ),
        const SizedBox(width: 8),
        _ChipStat(
          icon: Icons.trending_up,
          value: '$totalNew',
          label: 'یادگیری',
          color: AppColors.mint,
          bgColor: colors.card,
        ),
        const SizedBox(width: 8),
        _ChipStat(
          icon: Icons.replay,
          value: '$totalDue',
          label: 'مرور',
          color: AppColors.peach,
          bgColor: colors.card,
        ),
        const SizedBox(width: 8),
        _ChipStat(
          icon: Icons.stars_outlined,
          value: '${spaceState.summaries.length}',
          label: 'فضا',
          color: AppColors.lavender,
          bgColor: colors.card,
        ),
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  const _ChipStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.recallColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.recallColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentReviewRow extends StatelessWidget {
  const _RecentReviewRow({required this.spaceState});

  final SpaceListState spaceState;

  @override
  Widget build(BuildContext context) {
    final totalReviewed = spaceState.summaries.fold<int>(
      0,
      (sum, s) => sum + s.totalCards,
    );
    final colors = context.recallColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: colors.mutedForeground, size: 20),
          const SizedBox(width: 10),
          Text(
            'کارت‌های بازبینی شده',
            style: TextStyle(
              fontSize: 13,
              color: colors.mutedForeground,
            ),
          ),
          const Spacer(),
          Text(
            '$totalReviewed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceListTile extends StatelessWidget {
  const _SpaceListTile({
    required this.name,
    required this.cardCount,
    required this.onTap,
  });

  final String name;
  final int cardCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$cardCount ${AppStrings.cards}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: colors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.spaceState});

  final SpaceListState spaceState;

  @override
  Widget build(BuildContext context) {
    if (spaceState.summaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return StatisticsScreen(spaceId: spaceState.summaries.first.space.id);
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
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
