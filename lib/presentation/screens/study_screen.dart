import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, required this.config});

  final StudyConfig config;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudyCubit>(param1: config)..load(),
      child: _StudyView(config: config),
    );
  }
}

class _StudyView extends StatelessWidget {
  const _StudyView({required this.config});

  final StudyConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<StudyCubit, StudyState>(
          builder: (context, state) {
            if (state.status == StudyStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.status == StudyStatus.error) {
              return Center(
                child: Text(
                  state.errorMessage ?? AppStrings.error,
                  style: TextStyle(color: context.recallColors.mutedForeground),
                ),
              );
            }

            final card = state.currentCard;
            final questionText = card == null
                ? ''
                : _displayText(
                    front: card.front,
                    back: card.back,
                    isFlipped: state.isFlipped,
                    reversed: state.reversed,
                  );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    children: [
                      CircleIconButton(
                        back: true,
                        icon: Icons.arrow_back,
                        label: AppStrings.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      if (!state.isFinished && card != null) ...[
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.edit_outlined,
                          label: AppStrings.editCard,
                          onPressed: () => _editCard(context, state),
                        ),
                        const SizedBox(width: 8),
                        CircleIconButton(
                          icon: Icons.delete_outline,
                          label: AppStrings.deleteCard,
                          onPressed: () => _deleteCard(context),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: state.progress,
                            minHeight: 6,
                            backgroundColor: context.recallColors.muted,
                            valueColor: AlwaysStoppedAnimation(
                              context.accentColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 56,
                        child: Text(
                          '${state.currentIndex.clamp(0, state.queue.length)}/${state.queue.length}',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: context.recallColors.mutedForeground,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isFreeReview && !state.isFinished)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Row(
                      children: [
                        FilterChip(
                          avatar: Icon(
                            state.reversed
                                ? Icons.swap_vert
                                : Icons.swap_horiz,
                            size: 16,
                          ),
                          label: Text(
                            state.reversed
                                ? AppStrings.reversedReview
                                : AppStrings.normalReview,
                          ),
                          selected: state.reversed,
                          onSelected: (_) =>
                              context.read<StudyCubit>().toggleReversed(),
                        ),
                        if (state.boxNumber != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${AppStrings.box} ${state.boxNumber}',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.recallColors.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: state.isFinished
                          ? _FinishedView(total: state.queue.length)
                          : card != null
                              ? _FlashcardView(
                                  text: questionText,
                                  onTap: () =>
                                      context.read<StudyCubit>().flipCard(),
                                )
                              : const SizedBox.shrink(),
                    ),
                  ),
                ),
                if (!state.isFinished)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: Column(
                      children: [
                        if (state.isFreeReview &&
                            card != null &&
                            card.box > 1 &&
                            state.isFlipped)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _resetToBox1(context),
                                icon: const Icon(Icons.restart_alt, size: 18),
                                label: const Text(AppStrings.resetToBox1),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: state.isFlipped ? 1 : 0.3,
                          child: IgnorePointer(
                            ignoring: !state.isFlipped,
                            child: Row(
                              children: [
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.dontKnow,
                                    color: AppColors.peach,
                                    onPressed: () => context
                                        .read<StudyCubit>()
                                        .rateCard(ReviewRating.dontKnow),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.know,
                                    color: AppColors.mint,
                                    onPressed: () => context
                                        .read<StudyCubit>()
                                        .rateCard(ReviewRating.know),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _displayText({
    required String front,
    required String back,
    required bool isFlipped,
    required bool reversed,
  }) {
    if (!reversed) {
      return isFlipped ? back : front;
    }
    return isFlipped ? front : back;
  }

  Future<void> _resetToBox1(BuildContext context) async {
    await context.read<StudyCubit>().resetCurrentCardToBox1();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.resetToBox1Done)),
      );
    }
  }

  void _editCard(BuildContext context, StudyState state) {
    final card = state.currentCard!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CardFormSheet(
        front: card.front,
        back: card.back,
        onSubmit: (front, back) =>
            context.read<StudyCubit>().updateCurrentCard(front, back),
      ),
    );
  }

  Future<void> _deleteCard(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.deleteCard,
      message: AppStrings.deleteCardConfirm,
    );
    if (confirmed == true && context.mounted) {
      await context.read<StudyCubit>().deleteCurrentCard();
    }
  }
}

class _FlashcardView extends StatelessWidget {
  const _FlashcardView({
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final fontSize = text.length > 60 ? 24.0 : 30.0;

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 384),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colors.border),
              boxShadow: AppShadows.card(context),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinishedView extends StatelessWidget {
  const _FinishedView({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.mint.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 36, color: AppColors.mint),
        ),
        const SizedBox(height: 24),
        const Text(
          AppStrings.allDone,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          total == 0
              ? AppStrings.noDueCards
              : '$total ${AppStrings.reviewedCards}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: colors.mutedForeground),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Text(
            AppStrings.backToDecks,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
