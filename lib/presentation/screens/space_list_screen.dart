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
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';
import 'package:recall/presentation/widgets/space_form_sheet.dart';

class SpaceListScreen extends StatelessWidget {
  const SpaceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SpaceListView();
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

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                context.pageHorizontalPadding,
                12,
                context.pageHorizontalPadding,
                24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppPageHeader(
                    title: AppStrings.yourSpaces,
                    showBack: false,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.spacesHint,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (state.summaries.isEmpty)
                    _EmptySpaces(onCreate: () => _showNewSpace(context))
                  else
                    ...state.summaries.map(
                      (summary) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SoftListTile(
                          title: summary.space.name,
                          subtitle: AppStrings.spaceSummary(
                            summary.deckCount,
                            summary.totalCards,
                            summary.dueCards,
                          ),
                          icon: Icons.layers_outlined,
                          accent: AppColors.forDeck(summary.space.color),
                          onTap: () => _openSpace(context, summary.space),
                          trailing: IconButton(
                            onPressed: () =>
                                _editSpace(context, summary.space),
                            icon: Icon(
                              Icons.more_horiz,
                              color: colors.mutedForeground,
                            ),
                          ),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 40, color: colors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            AppStrings.emptySpaces,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: colors.mutedForeground,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                AppStrings.newSpace,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
