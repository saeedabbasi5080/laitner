import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/usecases/statistics_aggregator.dart';

/// What is waiting, day by day.
///
/// Deliberately not a chart. This started as Anki's two-series bar chart, then
/// grew a picker offering three ways to read it, and by then the section was
/// five pieces of information — bars, a second line, a legend, an average and a
/// peak — before a single number had been read. A row per day with a bar beside
/// it carries the same forecast and asks for no decoding at all: the label is
/// the day, the bar is the size, the number is the count.
///
/// Days with nothing due are left out rather than shown as a zero row, because
/// a column of zeroes says more about how long the list is than about the work.
class UpcomingCard extends StatelessWidget {
  const UpcomingCard({super.key, required this.snapshot});

  final StatisticsSnapshot snapshot;

  /// How many days to spell out before summarising the rest.
  static const shownDays = 7;

  @override
  Widget build(BuildContext context) {
    final forecast = snapshot.forecast;
    if (forecast.isEmpty) return const SizedBox.shrink();

    final colors = context.recallColors;
    final today = forecast.first.day;

    final busy = <({DateTime day, int count})>[
      for (final f in forecast)
        if (f.dueCount > 0) (day: f.day, count: f.dueCount),
    ];
    final restTotal = busy
        .skip(shownDays)
        .fold<int>(0, (sum, entry) => sum + entry.count);

    // Nothing due and nothing overdue: one sentence, no rows.
    if (busy.isEmpty && snapshot.overdueCount == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          AppStrings.forecastNothingSoon,
          style: TextStyle(fontSize: 13, color: colors.mutedForeground),
        ),
      );
    }

    final peak = busy.isEmpty
        ? 1
        : busy.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in busy.take(shownDays))
          _DayRow(
            label: _dayName(entry.day, today),
            count: entry.count,
            fraction: entry.count / peak,
            accent: context.accentColor,
            track: colors.muted,
          ),
        if (restTotal > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${AppStrings.forecastAfterThat} ($restTotal)',
              style: TextStyle(fontSize: 12, color: colors.mutedForeground),
            ),
          ),
        const SizedBox(height: 12),
        // The long-run average is the one thing the day list cannot show.
        Row(
          children: [
            Text(
              AppStrings.statsDailyLoad,
              style: TextStyle(fontSize: 12, color: colors.mutedForeground),
            ),
            const Spacer(),
            Text(
              _formatLoad(snapshot.dailyLoad),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (snapshot.overdueCount > 0) ...[
          const SizedBox(height: 10),
          Text(
            '${AppStrings.statsOverdueHidden}: ${snapshot.overdueCount}',
            style: TextStyle(fontSize: 11, color: colors.mutedForeground),
          ),
        ],
      ],
    );
  }
}

/// A day, a bar sized against the busiest day, and the count.
///
/// The bar is relative to the worst day in the window rather than to an absolute
/// scale, so the list always uses its full width and the comparison the reader
/// actually wants — this day against that day — is the one on screen.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.count,
    required this.fraction,
    required this.accent,
    required this.track,
  });

  final String label;
  final int count;
  final double fraction;
  final Color accent;
  final Color track;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: colors.mutedForeground),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  // The track shows the day's share of the busiest day, so a
                  // short bar reads as a light day rather than as no data.
                  Container(height: 8, color: track),
                  FractionallySizedBox(
                    widthFactor: fraction.clamp(0.02, 1.0),
                    child: Container(height: 8, color: accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anki's daily load is often a fraction — a card due in two days contributes
/// 0.5.
///
/// Rounding that to a whole number printed "0 cards a day", which reads as
/// having nothing to do rather than as having plenty of time.
String _formatLoad(double load) {
  if (load < 1) {
    return AppStrings.forecastCardsPerDayFraction(load.toStringAsFixed(1));
  }
  return AppStrings.statsCardsPerDay(load);
}

/// "tomorrow" / "the day after", then a date.
///
/// Relative names only cover the days anyone can actually plan around. Past
/// that a date is the honest label; pretending otherwise would turn a forecast
/// into a riddle.
String forecastDayName(DateTime day, DateTime today) {
  final difference = day.difference(today).inDays;
  return switch (difference) {
    0 => AppStrings.forecastToday,
    1 => AppStrings.forecastTomorrow,
    2 => AppStrings.forecastAfterTomorrow,
    _ => '${day.day}/${day.month}',
  };
}

String _dayName(DateTime day, DateTime today) => forecastDayName(day, today);