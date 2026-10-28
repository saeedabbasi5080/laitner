import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/statistics/statistics_cubit.dart';
import 'package:recall/presentation/widgets/chart_primitives.dart';
import 'package:recall/presentation/widgets/forecast_card.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

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

String _rangeLabel(StatisticsRange range) => switch (range) {
      StatisticsRange.week => AppStrings.rangeWeek,
      StatisticsRange.month => AppStrings.rangeMonth,
      StatisticsRange.quarter => AppStrings.rangeQuarter,
      StatisticsRange.year => AppStrings.rangeYear,
      StatisticsRange.all => AppStrings.rangeAll,
    };

/// The statistics screen, reduced to four blocks.
///
/// The order and the choice of charts follow Anki's own statistics window
/// (docs.ankiweb.net/stats.html): plain numbers for *Today*, a card-count
/// breakdown, a review count over time, and a forecast.
///
/// What made the earlier version hard to read was never the number of charts
/// but the number of encodings inside each one. A bar chart that is also
/// stacked by card state, overlaid with a cumulative line on a second axis, and
/// captioned with a four-item legend asks the reader to decode three things at
/// once — and a reader who cannot decode it concludes the app is lying. So each
/// chart here answers exactly one question with one shape: height means count,
/// nothing else. Where a second value genuinely matters, as in the forecast's
/// "if you stop" line, it is the only overlay and it is labelled in place.
class _StatisticsView extends StatelessWidget {
  const _StatisticsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<StatisticsCubit>();

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<StatisticsCubit, StatisticsState>(
          builder: (context, state) {
            final snapshot = state.snapshot;

            if (state.status == StatisticsStatus.error) {
              return _ErrorView(onRetry: cubit.load);
            }

            if (snapshot == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  const AppPageHeader(
                    title: AppStrings.statistics,
                    subtitle: AppStrings.learningOverview,
                  ),
                  const SizedBox(height: 20),
                  _RangeSelector(
                    selected: state.range,
                    onSelected: cubit.setRange,
                  ),
                  const SizedBox(height: 16),
                  _TodayCard(snapshot: snapshot),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: AppStrings.statsCardDistribution,
                    subtitle: AppStrings.statsCardDistributionHint(
                      snapshot.totalCards,
                    ),
                    child: _DistributionDonut(snapshot: snapshot),
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: AppStrings.statsReviewsOverTime,
                    subtitle: _rangeLabel(state.range),
                    child: _ReviewsChart(snapshot: snapshot),
                  ),
                  const SizedBox(height: 16),
                  _ChartCard(
                    title: AppStrings.statsForecast,
                    subtitle: AppStrings.statsForecastHint,
                    child: UpcomingCard(snapshot: snapshot),
                  ),
                  if (snapshot.hasHistory) ...[
                    const SizedBox(height: 16),
                    const _HistoryNote(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onSelected});

  final StatisticsRange selected;
  final ValueChanged<StatisticsRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final range in StatisticsRange.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _RangeChip(
                label: _rangeLabel(range),
                selected: range == selected,
                onTap: () => onSelected(range),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Material(
      color: selected ? context.accentColor : colors.muted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? colors.card : colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's numbers as plain figures, no chart.
///
/// Anki puts these at the top of its statistics window as text rather than as a
/// graph, and its manual makes a point of why: one day's figures are a poor
/// guide to progress, because everyone has bad days. A bare number also stops a
/// single low day from looking like a trend, which a one-bar chart very much
/// does.
class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final rate = snapshot.todayKnowRate;

    // Nothing else goes in this card. A lifetime figure such as the share of
    // graduated cards would read as a result of today's studying, which is
    // exactly the wrong impression: a space can sit at 50% mastered without a
    // single review today. The card-count chart below already shows that share,
    // where it can be read as what it is.
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.statsToday,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.statsTodayHint,
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),
          if (snapshot.todayTotal == 0)
            Text(
              AppStrings.statsNotStudiedToday,
              style: TextStyle(fontSize: 14, color: colors.mutedForeground),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Figure(
                  value: '${snapshot.todayTotal}',
                  label: AppStrings.statsReviews,
                ),
                _Figure(
                  // A dash rather than "۰٪": answering nothing is not a score
                  // of zero, and showing it as one would read as total failure.
                  value: rate == null ? '—' : '${(rate * 100).round()}٪',
                  label: AppStrings.statsCorrect,
                ),
                _Figure(
                  value: '${snapshot.currentStreak}',
                  label: AppStrings.statsStreakDays(snapshot.currentStreak),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: colors.mutedForeground),
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
    // Its own repaint boundary so a scroll moves the finished chart rather than
    // repainting its bars and labels on every frame.
    return RepaintBoundary(
      child: _Card(
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
              style: TextStyle(
                fontSize: 12,
                color: context.recallColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

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
      child: child,
    );
  }
}

/// Reviews per period as one flat series.
///
/// Anki's version splits each bar by card state and overlays a cumulative line
/// on a second axis. Both are dropped: the split only matters to someone tuning
/// a scheduler, and a second axis cannot be read against the first without a
/// legend. What survives is the one thing a learner actually looks at — how
/// much they did, and when.
class _ReviewsChart extends StatelessWidget {
  const _ReviewsChart({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final buckets = snapshot.reviewBuckets;
    if (buckets.isEmpty || buckets.every((b) => b.total == 0)) {
      return _EmptyHint();
    }

    // Labels are the scarcest thing on a phone, so only the ends and every
    // third slot are drawn. The rest keep an empty box rather than being
    // skipped, which is what keeps each label under its own bar.
    final step = math.max(1, (buckets.length / 3).ceil());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChartBars(
          values: [for (final b in buckets) b.total.toDouble()],
          color: context.accentColor,
          zeroColor: context.recallColors.muted,
        ),
        const SizedBox(height: 6),
        ChartBarLabels(
          count: buckets.length,
          // -1 means "never show".
          labelAt: (index) {
            final keep = index == 0 ||
                index == buckets.length - 1 ||
                index % step == 0;
            if (!keep) return null;
            return _periodLabel(buckets[index].start, snapshot.unit);
          },
        ),
      ],
    );
  }
}

/// Card counts split three ways.
///
/// Anki's card-count chart splits four ways because it has a suspended queue
/// this app does not. Three is what the Leitner model actually has, so three is
/// what is shown — no category, legend or slice exists that would not change a
/// number.
class _DistributionDonut extends StatelessWidget {
  const _DistributionDonut({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final distribution = snapshot.distribution;
    final total = snapshot.totalCards;

    if (total == 0) return const _EmptyHint();

    final parts = <({String label, int count, Color color})>[
      (
        label: AppStrings.houseRoleFresh,
        count: distribution.freshCount,
        color: AppColors.lemon,
      ),
      (
        label: AppStrings.houseRoleLearning,
        count: distribution.learningCount,
        color: AppColors.sky,
      ),
      (
        label: AppStrings.houseRoleLearned,
        count: distribution.learnedCount,
        color: AppColors.mint,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Center(
            // No entry animation. A sweep looked nice for about half a second
            // and then cost a repaint of the whole card on every frame of every
            // scroll, which is exactly the wrong trade on a list of charts.
            child: RepaintBoundary(
              child: CustomPaint(
                size: const Size(140, 140),
                painter: _DonutPainter(
                  slices: [
                    for (final part in parts)
                      (
                        fraction: part.count / total,
                        color: part.color,
                      ),
                  ],
                  track: context.recallColors.muted,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // A legend with the counts, the way Anki's card-count chart does: the
        // ring shows proportions, the rows give the exact numbers.
        for (final part in parts)
          _LegendRow(
            color: part.color,
            label: part.label,
            value: part.count,
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.slices,
    required this.track,
  });

  final List<({double fraction, Color color})> slices;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, trackPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;
    for (final slice in slices) {
      if (slice.fraction <= 0) continue;
      final sweep = math.pi * 2 * slice.fraction;
      paint.color = slice.color;
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.track != track ||
      !_sameSlices(oldDelegate.slices, slices);

  static bool _sameSlices(
    List<({double fraction, Color color})> a,
    List<({double fraction, Color color})> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].fraction != b[i].fraction || a[i].color != b[i].color) {
        return false;
      }
    }
    return true;
  }
}
/// Shown in place of a chart that has nothing to draw.
///
/// Says what is missing rather than rendering an empty box, so an empty graph
/// never reads as a broken one.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        AppStrings.statsNoReviewsYet,
        style: TextStyle(
          fontSize: 13,
          color: context.recallColors.mutedForeground,
        ),
      ),
    );
  }
}

/// Short date under the axis: day and month, or month and year for month
/// buckets, so a multi-year axis stays legible.
String _periodLabel(DateTime day, BucketUnit unit) => switch (unit) {
      BucketUnit.day => '${day.day}/${day.month}',
      BucketUnit.week => '${day.day}/${day.month}',
      BucketUnit.month => '${day.month}/${day.year % 100}',
    };

/// Anki keeps the review history of deleted cards and excludes it from a single
/// deck's totals. Worth saying once, because the numbers here can look a little
/// short next to the deck's own card count.
class _HistoryNote extends StatelessWidget {
  const _HistoryNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.statsCardsDeletedNote,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        height: 1.7,
        color: context.recallColors.mutedForeground,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              AppStrings.dataLoadFailed,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}