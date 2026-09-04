import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StatisticsCubit>(param1: spaceId)..load(),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (context, state) {
            if (state.status == StatisticsStatus.loading &&
                state.totalCards == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == StatisticsStatus.error) {
              return _ErrorView(onRetry: context.read<StatisticsCubit>().load);
            }

            return RefreshIndicator(
              onRefresh: context.read<StatisticsCubit>().load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  const _Header(),
                  const SizedBox(height: 32),
                  _MasteryCard(state: state),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: AppStrings.boxDistribution,
                    subtitle: AppStrings.boxDistributionHint,
                    child: _VerticalBarChart(
                      values: [
                        for (var box = 1; box <= maxBox; box++)
                          state.boxCounts[box] ?? 0,
                      ],
                      labels: [for (var box = 1; box <= maxBox; box++) '$box'],
                      colors: const [
                        AppColors.rose,
                        AppColors.peach,
                        AppColors.lemon,
                        AppColors.mint,
                        AppColors.sky,
                      ],
                      semanticPrefix: AppStrings.box,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: AppStrings.dailyReviews,
                    subtitle: AppStrings.lastSevenDays,
                    child: _VerticalBarChart(
                      values: state.dailyReviewCounts,
                      labels: _pastWeekLabels(),
                      colors: List.filled(7, context.accentColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AnswerRateCard(state: state),
                  const SizedBox(height: 16),
                  _StreakCard(state: state),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: AppStrings.futureDue,
                    subtitle: AppStrings.nextSevenDays,
                    child: _VerticalBarChart(
                      values: state.futureDueCounts,
                      labels: _futureLabels(),
                      colors: List.filled(7, AppColors.lavender),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HistoryNote(hasHistory: state.totalReviews > 0),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static List<String> _pastWeekLabels() {
    final now = DateTime.now();
    return [
      for (var offset = 6; offset >= 0; offset--)
        offset == 0
            ? AppStrings.todayShort
            : _weekdayLabel(now.subtract(Duration(days: offset))),
    ];
  }

  static List<String> _futureLabels() {
    final now = DateTime.now();
    return [
      AppStrings.todayShort,
      AppStrings.tomorrowShort,
      for (var offset = 2; offset < 7; offset++)
        _weekdayLabel(now.add(Duration(days: offset))),
    ];
  }

  static String _weekdayLabel(DateTime date) => switch (date.weekday) {
    DateTime.monday => 'د',
    DateTime.tuesday => 'س',
    DateTime.wednesday => 'چ',
    DateTime.thursday => 'پ',
    DateTime.friday => 'ج',
    DateTime.saturday => 'ش',
    DateTime.sunday => 'ی',
    _ => '',
  };
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          back: true,
          icon: Icons.arrow_back,
          label: AppStrings.backToDecks,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.statistics,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(AppStrings.learningOverview, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.state});

  final StatisticsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final percent = (state.masteryProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
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
                    const Text(
                      AppStrings.mastery,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.masteryHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent٪',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: context.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: state.masteryProgress,
              minHeight: 10,
              backgroundColor: colors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${state.masteredCards} از ${state.totalCards} '
            '${AppStrings.masteredCards}',
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _VerticalBarChart extends StatelessWidget {
  const _VerticalBarChart({
    required this.values,
    required this.labels,
    required this.colors,
    this.semanticPrefix,
  }) : assert(values.length == labels.length && values.length == colors.length);

  final List<int> values;
  final List<String> labels;
  final List<Color> colors;
  final String? semanticPrefix;

  @override
  Widget build(BuildContext context) {
    final largestValue = values.fold<int>(
      0,
      (largest, value) => value > largest ? value : largest,
    );
    final chartMax = largestValue <= 0 ? 1 : largestValue;
    final muted = context.recallColors.muted;
    final mutedForeground = context.recallColors.mutedForeground;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        height: 172,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < values.length; index++)
              Expanded(
                child: Semantics(
                  label:
                      '${semanticPrefix == null ? '' : '$semanticPrefix '}${labels[index]}: ${values[index]}',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${values[index]}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final ratio = values[index] / chartMax;
                              final height = values[index] == 0
                                  ? 4.0
                                  : math
                                        .max(8.0, constraints.maxHeight * ratio)
                                        .toDouble();
                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 350),
                                  curve: Curves.easeOutCubic,
                                  width: double.infinity,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: values[index] == 0
                                        ? muted
                                        : colors[index],
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          labels[index],
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: labels[index].length > 2 ? 9 : 11,
                            color: mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerRateCard extends StatelessWidget {
  const _AnswerRateCard({required this.state});

  final StatisticsState state;

  @override
  Widget build(BuildContext context) {
    final total = state.totalReviews;
    final knowProgress = total == 0 ? 0.0 : state.knowCount / total;
    final dontKnowProgress = total == 0 ? 0.0 : state.dontKnowCount / total;

    return _ChartCard(
      title: AppStrings.answerRate,
      subtitle: AppStrings.answerRateHint,
      child: Column(
        children: [
          _RateRow(
            label: AppStrings.know,
            count: state.knowCount,
            progress: knowProgress,
            color: AppColors.mint,
          ),
          const SizedBox(height: 20),
          _RateRow(
            label: AppStrings.dontKnow,
            count: state.dontKnowCount,
            progress: dontKnowProgress,
            color: AppColors.rose,
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.label,
    required this.count,
    required this.progress,
    required this.color,
  });

  final String label;
  final int count;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    final colors = context.recallColors;

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(
              '$count · $percent٪',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: colors.muted,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.state});

  final StatisticsState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: context.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.local_fire_department_outlined,
              color: context.accentColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _StreakMetric(
              label: AppStrings.currentStreak,
              value: state.currentStreak,
            ),
          ),
          Container(width: 1, height: 42, color: colors.border),
          const SizedBox(width: 16),
          Expanded(
            child: _StreakMetric(
              label: AppStrings.bestStreak,
              value: state.bestStreak,
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakMetric extends StatelessWidget {
  const _StreakMetric({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.recallColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value ${AppStrings.day}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _HistoryNote extends StatelessWidget {
  const _HistoryNote({required this.hasHistory});

  final bool hasHistory;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: colors.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasHistory
                ? AppStrings.reviewHistoryNote
                : AppStrings.noReviewHistory,
            style: TextStyle(
              fontSize: 11,
              height: 1.6,
              color: colors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            const Text(AppStrings.error),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}
