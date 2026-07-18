import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/tts/tts_service.dart';
import 'package:recall/core/utils/responsive.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';

class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, required this.config});

  final StudyConfig config;

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = config.withRandomOrder(
      context.read<SettingsCubit>().state.randomReviewOrder,
    );
    return BlocProvider(
      create: (_) => sl<StudyCubit>(param1: effectiveConfig)..load(),
      child: _StudyView(config: effectiveConfig),
    );
  }
}

class _StudyView extends StatefulWidget {
  const _StudyView({required this.config});

  final StudyConfig config;

  @override
  State<_StudyView> createState() => _StudyViewState();
}

class _StudyViewState extends State<_StudyView> {
  bool _ttsUnavailableNotified = false;
  String? _lastAutoSpokenKey;

  @override
  void dispose() {
    sl<TtsService>().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<StudyCubit, StudyState>(
          listenWhen: (previous, current) {
            if (!context.read<SettingsCubit>().state.autoSpeak) return false;
            if (current.status != StudyStatus.ready || current.isFinished) {
              return false;
            }
            if (current.currentCard == null) return false;
            // Only when a new card is shown — not when the user flips it.
            return previous.status != current.status ||
                previous.currentIndex != current.currentIndex;
          },
          listener: (context, state) {
            final card = state.currentCard;
            if (card == null) return;
            // Speak the question side of the newly opened card once.
            final text = _displayText(
              front: card.front,
              back: card.back,
              isFlipped: false,
              reversed: state.reversed,
            );
            final key = card.id;
            if (key == _lastAutoSpokenKey) return;
            _lastAutoSpokenKey = key;
            _speak(
              context,
              text,
              notifyUnavailable: !_ttsUnavailableNotified,
            ).then((spoken) {
              if (!spoken && mounted) {
                _ttsUnavailableNotified = true;
              }
            });
          },
          builder: (context, state) {
            if (state.status == StudyStatus.loading) {
              return const Center(child: CircularProgressIndicator());
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
                  padding: EdgeInsets.fromLTRB(
                    context.pageHorizontalPadding,
                    12,
                    context.pageHorizontalPadding,
                    8,
                  ),
                  child: Row(
                    children: [
                      CircleIconButton(
                        back: true,
                        icon: Icons.arrow_back,
                        label: AppStrings.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      if (!state.isFinished && card != null) ...[
                        const SizedBox(width: 6),
                        CircleIconButton(
                          icon: Icons.volume_up_outlined,
                          label: AppStrings.speak,
                          onPressed: () => _speak(context, questionText),
                        ),
                        const SizedBox(width: 6),
                        CircleIconButton(
                          icon: Icons.edit_outlined,
                          label: AppStrings.editCard,
                          onPressed: () => _editCard(context, state),
                        ),
                        const SizedBox(width: 6),
                        CircleIconButton(
                          icon: Icons.delete_outline,
                          label: AppStrings.deleteCard,
                          color: AppColors.danger,
                          onPressed: () => _deleteCard(context),
                        ),
                      ],
                      const SizedBox(width: 8),
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
                      const SizedBox(width: 8),
                      Text(
                        '${state.currentIndex.clamp(0, state.queue.length)}/${state.queue.length}',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.recallColors.mutedForeground,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isFreeReview &&
                    !state.isFinished &&
                    state.boxNumber != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.pageHorizontalPadding,
                      0,
                      context.pageHorizontalPadding,
                      8,
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${AppStrings.freeReview} — '
                          '${AppStrings.box} ${state.boxNumber}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.accentColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.freeReviewStudyBadge,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            color: context.recallColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.pageHorizontalPadding,
                    ),
                    child: Center(
                      child: state.isFinished
                          ? _FinishedView(total: state.queue.length)
                          : card != null
                          ? _FlashcardView(
                              text: questionText,
                              fontSize: context
                                  .watch<SettingsCubit>()
                                  .state
                                  .cardFontSize
                                  .sizeFor(questionText),
                              onTap: () =>
                                  context.read<StudyCubit>().flipCard(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                if (!state.isFinished)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.pageHorizontalPadding,
                      8,
                      context.pageHorizontalPadding,
                      context.isShortHeight ? 16 : 28,
                    ),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                                    label: AppStrings.know,
                                    color: AppColors.mint,
                                    onPressed: () => context
                                        .read<StudyCubit>()
                                        .rateCard(ReviewRating.know),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.dontKnow,
                                    color: AppColors.peach,
                                    onPressed: () => context
                                        .read<StudyCubit>()
                                        .rateCard(ReviewRating.dontKnow),
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

  Future<bool> _speak(
    BuildContext context,
    String text, {
    bool notifyUnavailable = true,
  }) async {
    if (text.trim().isEmpty) return true;
    final language = context.read<SettingsCubit>().state.ttsLanguage;
    final messenger = ScaffoldMessenger.of(context);
    final tts = sl<TtsService>();

    final available = await tts.isLanguageAvailable(language.code);
    if (!available) {
      if (notifyUnavailable && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text(AppStrings.ttsUnavailable)),
        );
      }
      return false;
    }
    await tts.speak(text, languageCode: language.code);
    return true;
  }

  Future<void> _resetToBox1(BuildContext context) async {
    await context.read<StudyCubit>().resetCurrentCardToBox1();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.resetToBox1Done)));
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
    required this.fontSize,
    required this.onTap,
  });

  final String text;
  final double fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final short = context.isShortHeight;
    final padH = short ? 20.0 : 28.0;
    final padV = short ? 24.0 : 36.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fitCardSize(
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
        );

        return Align(
          alignment: Alignment.center,
          child: Material(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: size.width,
                height: size.height,
                padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.border),
                  boxShadow: AppShadows.card(context),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: size.width - (padH * 2),
                        maxHeight: size.height - (padV * 2),
                      ),
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
            ),
          ),
        );
      },
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
