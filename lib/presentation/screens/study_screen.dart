import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/tts/tts_service.dart';
import 'package:recall/core/utils/responsive.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/card_difficulty.dart';
import 'package:recall/domain/entities/card_media.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/blocs/study/study_cubit.dart';
import 'package:recall/presentation/widgets/card_side_editor.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';
import 'package:recall/presentation/widgets/study_card_media.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key, required this.config});

  final StudyConfig config;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  StudyConfig? _effectiveConfig;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final spaceSettings = await sl<SpaceSettingsStore>().load(
      widget.config.spaceId,
    );
    if (!mounted) return;
    setState(() {
      _effectiveConfig = widget.config.applySpaceSettings(
        randomOrder: spaceSettings.randomReviewOrder,
        defaultReversed: spaceSettings.defaultReversed,
        boxConfig: spaceSettings.leitnerBoxes,
        reviewSettings: spaceSettings.reviewSettings,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = _effectiveConfig;
    if (config == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return BlocProvider(
      create: (_) => sl<StudyCubit>(param1: config)..load(),
      child: const _StudyView(),
    );
  }
}

class _StudyView extends StatefulWidget {
  const _StudyView();

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
            final settings = context.read<SettingsCubit>().state;
            if (!settings.autoSpeak) return false;
            if (current.status != StudyStatus.ready || current.isFinished) {
              return false;
            }
            if (current.currentCard == null) return false;
            return settings.autoSpeakSide.shouldSpeak(
              isFlipped: current.isFlipped,
              reversed: current.reversed,
            );
          },
          listener: (context, state) {
            final card = state.currentCard;
            if (card == null) return;
            final settings = context.read<SettingsCubit>().state;
            if (!settings.autoSpeakSide.shouldSpeak(
              isFlipped: state.isFlipped,
              reversed: state.reversed,
            )) {
              return;
            }
            final text = _displayText(
              front: card.front,
              back: card.back,
              isFlipped: state.isFlipped,
              reversed: state.reversed,
            );
            final showingFront =
                state.reversed ? state.isFlipped : !state.isFlipped;
            final key = '${card.id}-${showingFront ? 'front' : 'back'}';
            if (key == _lastAutoSpokenKey) return;
            _lastAutoSpokenKey = key;
            _speak(
              context,
              text,
              interrupt: false,
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
                          icon: Icons.restart_alt,
                          label: AppStrings.resetToBox1,
                          color: card.box > 1 ? context.accentColor : null,
                          onPressed: card.box > 1
                              ? () => _resetToBox1(context)
                              : null,
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
                    ],
                  ),
                ),
                if (!state.isFinished && card != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.pageHorizontalPadding,
                      0,
                      context.pageHorizontalPadding,
                      8,
                    ),
                    child: Column(
                      children: [
                        _HouseTrack(
                          box: card.box,
                          maxBox: context
                              .watch<SettingsCubit>()
                              .state
                              .leitnerBoxes
                              .maxBox,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
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
                          ? _FinishedView(
                              total: state.queue.length,
                              knowCount: state.knowCount,
                              dontKnowCount: state.dontKnowCount,
                              mistakeCount: state.mistakeCount,
                              onRetryMistakes: state.mistakeCount == 0
                                  ? null
                                  : () => _retryMistakes(context),
                            )
                          : card != null
                          ? _FlashcardView(
                              text: questionText,
                              styleJson: _showingFront(
                                isFlipped: state.isFlipped,
                                reversed: state.reversed,
                              )
                                  ? card.frontStyle
                                  : card.backStyle,
                              media: card.mediaFor(
                                _showingFront(
                                  isFlipped: state.isFlipped,
                                  reversed: state.reversed,
                                )
                                    ? CardMediaSide.front
                                    : CardMediaSide.back,
                              ),
                              meta: [
                                AppStrings.boxBadge(card.box),
                                if (state.currentDeckName != null)
                                  state.currentDeckName!,
                                if (CardDifficulty.fromTags(card.tags) case
                                    final difficulty?)
                                  difficulty.label,
                              ].join(' · '),
                              fontSize: context
                                  .watch<SettingsCubit>()
                                  .state
                                  .cardFontSize
                                  .sizeFor(questionText),
                              learned: card.isLearnedIn(
                                context
                                    .watch<SettingsCubit>()
                                    .state
                                    .leitnerBoxes
                                    .maxBox,
                              ),
                              onTap: () =>
                                  context.read<StudyCubit>().flipCard(),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                if (state.justLearned.isNotEmpty && !state.isFinished)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.pageHorizontalPadding,
                      8,
                      context.pageHorizontalPadding,
                      4,
                    ),
                    child: _JustLearnedBanner(card: state.justLearned.first),
                  ),
                if (!state.isFinished)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.pageHorizontalPadding,
                      8,
                      context.pageHorizontalPadding,
                      context.isShortHeight ? 16 : 28,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: !state.isFlipped
                          ? const SizedBox(height: 56)
                          : Row(
                              key: const ValueKey('rate-buttons'),
                              children: [
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.know,
                                    color: AppColors.know,
                                    onPressed: () => context
                                        .read<StudyCubit>()
                                        .rateCard(ReviewRating.know),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.dontKnow,
                                    color: AppColors.dontKnow,
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
            );
          },
        ),
      ),
    );
  }

  bool _showingFront({required bool isFlipped, required bool reversed}) {
    return reversed ? isFlipped : !isFlipped;
  }

  String _displayText({
    required String front,
    required String back,
    required bool isFlipped,
    required bool reversed,
  }) {
    return _showingFront(isFlipped: isFlipped, reversed: reversed)
        ? front
        : back;
  }

  Future<bool> _speak(
    BuildContext context,
    String text, {
    bool notifyUnavailable = true,
    bool interrupt = true,
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
    await tts.speak(
      text,
      languageCode: language.code,
      interrupt: interrupt,
      speechRate: context.read<SettingsCubit>().state.ttsSpeechRate,
    );
    return true;
  }

  Future<void> _resetToBox1(BuildContext context) async {
    final cubit = context.read<StudyCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.resetToBox1,
      message: AppStrings.resetToBox1Confirm,
      confirmLabel: AppStrings.yes,
      confirmColor: context.accentColor,
    );
    if (confirmed != true || !mounted) return;

    await cubit.resetCurrentCardToBox1();
    if (!mounted) return;

    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.resetToBox1Done)),
    );
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

  /// Reopens a session over exactly the cards that were missed.
  ///
  /// Built from the ids this session collected rather than from the day's whole
  /// history, so the button retried what just went wrong and nothing else.
  void _retryMistakes(BuildContext context) {
    final cubit = context.read<StudyCubit>();
    final ids = cubit.state.mistakeCardIds;
    if (ids.isEmpty) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(
          config: cubit.config.withMistakeRetry(ids),
        ),
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
    required this.styleJson,
    required this.media,
    required this.meta,
    required this.fontSize,
    required this.onTap,
    this.learned = false,
  });

  final String text;
  final String styleJson;
  final List<CardMedia> media;
  final String meta;
  final double fontSize;
  final VoidCallback onTap;

  /// Tints the card gold when it has graduated into the learned archive.
  final bool learned;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final short = context.isShortHeight;
    final padH = short ? 20.0 : 28.0;
    final padV = short ? 24.0 : 36.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = fitCardSize(
          availableWidth: constraints.maxWidth,
          availableHeight: constraints.maxHeight,
        );

        // Learned cards get a warm gold wash so they are recognisable at a
        // glance in any list or review session.
        final tint = learned
            ? AppColors.gold.withValues(alpha: isDark ? 0.16 : 0.20)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
        final borderColor =
            learned ? AppColors.gold.withValues(alpha: 0.65) : colors.border;

        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Color.alphaBlend(
              tint,
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
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
                  border: Border.all(
                    color: borderColor,
                    width: learned ? 1.5 : 1,
                  ),
                  boxShadow: AppShadows.card(context),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 22,
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: size.width - (padH * 2),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StudyRichText(
                                  plain: text,
                                  styleJson: styleJson,
                                  fontSize: fontSize,
                                ),
                                StudyCardMediaList(media: media),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
  const _FinishedView({
    required this.total,
    required this.knowCount,
    required this.dontKnowCount,
    this.mistakeCount = 0,
    this.onRetryMistakes,
  });

  final int total;
  final int knowCount;
  final int dontKnowCount;

  /// How many cards were missed, which drives the retry button.
  final int mistakeCount;

  final VoidCallback? onRetryMistakes;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final rated = knowCount + dontKnowCount;
    final showResult = rated > 0;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!showResult) ...[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 36,
                color: context.accentColor,
              ),
            ),
            const SizedBox(height: 24),
          ],
          const Text(
            AppStrings.allDone,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            total == 0
                ? AppStrings.noDueTodayHint
                : '$total ${AppStrings.reviewedCards}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: colors.mutedForeground),
          ),
          if (showResult) ...[
            const SizedBox(height: 24),
            if (mistakeCount > 0 && onRetryMistakes != null) ...[
              OutlinedButton.icon(
                onPressed: onRetryMistakes,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(AppStrings.reviewMistakes(mistakeCount)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            _SessionResultChart(
              knowCount: knowCount,
              dontKnowCount: dontKnowCount,
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.sessionResultSummary(knowCount, dontKnowCount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
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
      ),
    );
  }
}

/// Horizontal strip of houses with the current one highlighted, so the user
/// can see at a glance where a card sits and where a correct answer sends it.
class _HouseTrack extends StatelessWidget {
  const _HouseTrack({required this.box, required this.maxBox});

  final int box;
  final int maxBox;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final total = math.max(1, maxBox);
    // A card past the last house has graduated; show that instead of an index.
    final isLearned = box > maxBox;

    return Directionality(
      // House 1 sits on the right in this RTL layout, matching the order the
      // houses are shown in on the home panel.
      textDirection: TextDirection.rtl,
      child: Semantics(
        label: isLearned
            ? AppStrings.houseLearnedBadge
            : AppStrings.houseLabel(box),
        child: Row(
          children: [
            for (var house = 1; house <= total; house++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: !isLearned && house <= box
                              ? context.accentColor
                              : colors.muted,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLearned ? '★' : '$house',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: !isLearned && house == box
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: !isLearned && house == box
                              ? context.accentColor
                              : colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Celebrates the card that just moved into the learned archive.
class _JustLearnedBanner extends StatelessWidget {
  const _JustLearnedBanner({required this.card});

  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, progress, child) => Opacity(
        // Fading in keeps the banner from stealing attention from the next
        // card, which is already on screen by the time this appears.
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.94 + 0.06 * progress, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.field),
          gradient: LinearGradient(
            colors: [
              AppColors.gold.withValues(alpha: 0.26),
              AppColors.gold.withValues(alpha: 0.10),
            ],
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded,
                color: AppColors.gold, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.justLearnedTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.justLearnedCard(card.front),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
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

class _SessionResultChart extends StatelessWidget {
  const _SessionResultChart({
    required this.knowCount,
    required this.dontKnowCount,
  });

  final int knowCount;
  final int dontKnowCount;

  @override
  Widget build(BuildContext context) {
    final rated = knowCount + dontKnowCount;
    final accuracy = rated == 0 ? 0 : ((knowCount / rated) * 100).round();
    final size = context.isShortHeight ? 148.0 : 176.0;

    return Semantics(
      label: AppStrings.sessionResultSummary(knowCount, dontKnowCount),
      child: Column(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  painter: _SessionDonutPainter(
                    knowFraction: rated == 0 ? 0 : knowCount / rated,
                    progress: progress,
                    knowColor: AppColors.know,
                    dontKnowColor: AppColors.dontKnow,
                    trackColor: context.recallColors.muted,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$accuracy٪',
                          style: TextStyle(
                            fontSize: context.isShortHeight ? 26 : 30,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.sessionAccuracy,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.recallColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SessionLegendItem(
                color: AppColors.know,
                label: AppStrings.sessionCorrect,
                count: knowCount,
              ),
              const SizedBox(width: 20),
              _SessionLegendItem(
                color: AppColors.dontKnow,
                label: AppStrings.sessionWrong,
                count: dontKnowCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionLegendItem extends StatelessWidget {
  const _SessionLegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$count $label',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SessionDonutPainter extends CustomPainter {
  const _SessionDonutPainter({
    required this.knowFraction,
    required this.progress,
    required this.knowColor,
    required this.dontKnowColor,
    required this.trackColor,
  });

  final double knowFraction;
  final double progress;
  final Color knowColor;
  final Color dontKnowColor;
  final Color trackColor;

  static const _strokeWidth = 18.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final totalSweep = math.pi * 2 * progress;
    if (totalSweep <= 0) return;

    final knowSweep = totalSweep * knowFraction;
    final dontKnowSweep = totalSweep - knowSweep;

    if (knowSweep > 0) {
      canvas.drawArc(
        rect,
        startAngle,
        knowSweep,
        false,
        Paint()
          ..color = knowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
    }
    if (dontKnowSweep > 0) {
      canvas.drawArc(
        rect,
        startAngle + knowSweep,
        dontKnowSweep,
        false,
        Paint()
          ..color = dontKnowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SessionDonutPainter oldDelegate) {
    return oldDelegate.knowFraction != knowFraction ||
        oldDelegate.progress != progress ||
        oldDelegate.knowColor != knowColor ||
        oldDelegate.dontKnowColor != dontKnowColor ||
        oldDelegate.trackColor != trackColor;
  }
}