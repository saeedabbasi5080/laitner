import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/space_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/responsive.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/domain/usecases/add_space_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/space_list/space_list_cubit.dart';
import 'package:recall/presentation/blocs/space_list/space_list_state.dart';
import 'package:recall/presentation/screens/deck_list_screen.dart';
import 'package:recall/presentation/screens/settings_screen.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/space_form_sheet.dart';

class SpaceListScreen extends StatelessWidget {
  const SpaceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SpaceListCubit>()..load(),
      child: const _SpaceListView(),
    );
  }
}

class _SpaceListView extends StatelessWidget {
  const _SpaceListView();

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SpaceListCubit, SpaceListState>(
          builder: (context, state) {
            if (state.status == SpaceListStatus.loading &&
                state.summaries.isEmpty) {
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.appTitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colors.mutedForeground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppStrings.yourSpaces,
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
                          CircleIconButton(
                            icon: Icons.settings_outlined,
                            label: AppStrings.settings,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.spacesHint,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (state.summaries.isEmpty)
                        _EmptySpaces(onCreate: () => _showNewSpace(context))
                      else
                        ...state.summaries.map(
                          (summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SpaceCard(
                              summary: summary,
                              onOpen: () => _openSpace(context, summary.space),
                              onEdit: () => _editSpace(context, summary.space),
                            ),
                          ),
                        ),
                      if (!state.canAddSpace) ...[
                        const SizedBox(height: 8),
                        Text(
                          AppStrings.spaceLimitReached(maxLearningSpaces),
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (state.canAddSpace)
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
                          onTap: () => _showNewSpace(context),
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

  Future<void> _openSpace(BuildContext context, LearningSpace space) async {
    await sl<SettingsCubit>().loadForSpace(space.id);
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeckListScreen(space: space),
      ),
    );
    if (context.mounted) {
      context.read<SpaceListCubit>().load();
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

  void _editSpace(BuildContext context, LearningSpace space) {
    final cubit = context.read<SpaceListCubit>();
    final canDelete = cubit.state.summaries.length > 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SpaceFormSheet(
        space: space,
        canDelete: canDelete,
        onSubmit: (name, color) => cubit.updateSpace(
          space.copyWith(name: name.trim(), color: color),
        ),
        onDelete: () async {
          if (!canDelete) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppStrings.cannotDeleteLastSpace)),
              );
            }
            return;
          }
          final confirmed = await showConfirmDialog(
            context,
            title: AppStrings.deleteSpace,
            message: AppStrings.deleteSpaceConfirm,
          );
          if (confirmed == true && context.mounted) {
            await cubit.deleteSpace(space.id);
          }
        },
      ),
    );
  }
}

class _EmptySpaces extends StatelessWidget {
  const _EmptySpaces({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            AppStrings.emptySpaces,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.mutedForeground, height: 1.6),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onCreate, child: const Text(AppStrings.newSpace)),
        ],
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.summary,
    required this.onOpen,
    required this.onEdit,
  });

  final SpaceSummary summary;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final fill = AppColors.forDeck(summary.space.color);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onOpen,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.layers_outlined, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.space.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.spaceSummary(
                        summary.deckCount,
                        summary.totalCards,
                        summary.dueCards,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (summary.dueCards > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${summary.dueCards} ${AppStrings.due}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.accentColor,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.more_horiz, color: colors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
