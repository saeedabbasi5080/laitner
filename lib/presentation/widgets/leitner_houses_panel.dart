import 'package:flutter/material.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';

/// Visual-only Leitner houses + learned-cards panel.
/// Counts and tap handlers come from existing deck-list state.
class LeitnerHousesPanel extends StatelessWidget {
  const LeitnerHousesPanel({
    super.key,
    required this.boxCounts,
    required this.learnedCount,
    required this.onBoxTap,
    required this.onLearnedTap,
  });

  final Map<int, int> boxCounts;
  final int learnedCount;
  final ValueChanged<int> onBoxTap;
  final VoidCallback onLearnedTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.recallColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.style_outlined,
                color: scheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.leitnerHousesTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppStrings.leitnerHousesHint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var box = 1; box <= maxBox; box++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.only(
                      end: box == maxBox ? 0 : 6,
                    ),
                    child: _HouseColumn(
                      box: box,
                      count: boxCounts[box] ?? 0,
                      onTap: () => onBoxTap(box),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _ProgressLegend(),
        const SizedBox(height: 18),
        _LearnedBanner(
          count: learnedCount,
          onTap: onLearnedTap,
        ),
      ],
    );
  }
}

class _HouseColumn extends StatelessWidget {
  const _HouseColumn({
    required this.box,
    required this.count,
    required this.onTap,
  });

  final int box;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlighted = box == 1;
    final depth = (box - 1) / (maxBox - 1);
    final fill = highlighted
        ? scheme.primary
        : Color.alphaBlend(
            scheme.primary.withValues(
              alpha: isDark ? 0.10 + depth * 0.22 : 0.06 + depth * 0.14,
            ),
            scheme.surfaceContainerLow,
          );
    final onFill = highlighted ? scheme.onPrimary : scheme.onSurface;
    final badgeFill = highlighted
        ? scheme.onPrimary.withValues(alpha: 0.18)
        : scheme.primary.withValues(alpha: isDark ? 0.28 : 0.16);

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: highlighted
                ? null
                : Border.all(
                    color: scheme.primary.withValues(alpha: 0.22 + depth * 0.2),
                  ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : AppShadows.card(context),
          ),
          child: Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeFill,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$box',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: highlighted ? scheme.onPrimary : scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${AppStrings.box} $box',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: onFill.withValues(alpha: 0.78),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$count',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: onFill,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.cards,
                style: TextStyle(
                  fontSize: 10,
                  color: onFill.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.recallColors.mutedForeground;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            height: 18,
            child: CustomPaint(
              painter: _ProgressLinePainter(color: scheme.primary),
              size: Size.infinite,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                AppStrings.newestCards,
                textAlign: TextAlign.start,
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
            Expanded(
              child: Text(
                AppStrings.currentlyLearning,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
            Expanded(
              child: Text(
                AppStrings.stableMastered,
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 10, color: muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressLinePainter extends CustomPainter {
  _ProgressLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
    const nodes = maxBox;
    for (var i = 0; i < nodes; i++) {
      final t = nodes == 1 ? 0.0 : i / (nodes - 1);
      final x = size.width - 8 - t * (size.width - 16);
      canvas.drawCircle(Offset(x, y), 4, paint);
    }
    final arrow = Path()
      ..moveTo(4, y)
      ..lineTo(12, y - 5)
      ..lineTo(12, y + 5)
      ..close();
    canvas.drawPath(arrow, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ProgressLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LearnedBanner extends StatelessWidget {
  const _LearnedBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.recallColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.28 : 0.16),
                  scheme.surfaceContainerLow,
                ),
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                  scheme.surfaceContainerLow,
                ),
              ],
            ),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 44,
                  color: scheme.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$count ',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                            TextSpan(
                              text: AppStrings.cards,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        AppStrings.learnedCards,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.learnedCardsShortHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                AppStrings.viewAll,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_left,
                                size: 16,
                                color: scheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
