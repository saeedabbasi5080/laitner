// Chart pieces shared by every statistics graph.
//
// Each of these is drawn by a single painter rather than by a column of widgets,
// and that is a performance decision as much as a tidiness one. A thirty-day bar
// chart built as thirty Containers means thirty rounded-rect draws plus thirty
// subtrees, all redrawn on every frame of a scroll. One painter is one layer:
// the compositor rasterises it once and the scroller just moves it.
//
// The `CustomPaint(child: SizedBox.expand())` shape below is deliberate. A
// CustomPaint with a child takes its size from that child, so `SizedBox.expand()`
// is what lets the painter learn how wide it is without a LayoutBuilder.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:recall/core/theme/app_theme.dart';

/// Fixed-height plot area, always left-to-right.
///
/// Time runs left to right even in a right-to-left interface. A chart that
/// mirrored its own time axis would stop lining up with the dates printed
/// beneath it, and the reader would have out to work out which way to read it
/// every single time.
class ChartPlot extends StatelessWidget {
  const ChartPlot({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(height: height, child: child),
    );
  }
}

/// One bar per slot, where bar height is the only thing encoded.
///
/// A slot with no data still gets a faint stub, so a gap reads as "nothing
/// happened" rather than "no data".
class ChartBars extends StatelessWidget {
  const ChartBars({
    super.key,
    required this.values,
    required this.color,
    required this.zeroColor,
    this.height = 150,
    this.gap = 1.5,
  });

  final List<double> values;
  final Color color;
  final Color zeroColor;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: CustomPaint(
          painter: _BarsPainter(
            values: values,
            color: color,
            zeroColor: zeroColor,
            gap: gap,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({
    required this.values,
    required this.color,
    required this.zeroColor,
    required this.gap,
  });

  final List<double> values;
  final Color color;
  final Color zeroColor;
  final double gap;

  /// Room left above the tallest bar so it never touches the top edge.
  static const _headroom = 1.1;

  @override
  void paint(Canvas canvas, Size size) {
    // Headroom so the tallest bar never touches the top edge.
    final max = math.max(1.0, values.reduce(math.max) * _headroom);
    final slot = size.width / values.length;
    final barWidth = math.max(1.0, slot - gap * 2);
    final radius = Radius.circular(math.min(3.0, barWidth / 2));

    final fill = Paint()..color = color;
    final stub = Paint()..color = zeroColor;

    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      final left = slot * i + gap;

      if (value <= 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, size.height - 3, barWidth, 3),
            Radius.circular(2),
          ),
          stub,
        );
        continue;
      }

      final barHeight = math.max(3.0, size.height * (value / max));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, size.height - barHeight, barWidth, barHeight),
          radius,
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.zeroColor != zeroColor ||
      oldDelegate.gap != gap ||
      !_sameValues(oldDelegate.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Axis labels aligned one-to-one with the bars above.
///
/// Also painted rather than laid out as one `Text` per slot: thirty to sixty
/// text widgets is thirty to sixty layout and compositing operations on every
/// scroll frame, for output that never changes once drawn.
///
/// On a phone labels are the scarcest thing on screen, so [labelAt] returns
/// `null` for most slots and only the ones worth reading get text.
class ChartBarLabels extends StatelessWidget {
  const ChartBarLabels({
    super.key,
    required this.count,
    required this.labelAt,
  });

  final int count;

  /// The label for slot [index], or null to leave it blank.
  final String? Function(int index) labelAt;

  @override
  Widget build(BuildContext context) {
    final labels = <String?>[
      for (var i = 0; i < count; i++) labelAt(i),
    ];

    return RepaintBoundary(
      child: SizedBox(
        height: 14,
        child: CustomPaint(
          painter: _LabelsPainter(labels: labels, color: context.recallColors.mutedForeground),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _LabelsPainter extends CustomPainter {
  const _LabelsPainter({required this.labels, required this.color});

  final List<String?> labels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (labels.isEmpty) return;

    final slot = size.width / labels.length;
    final painter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < labels.length; i++) {
      final text = labels[i];
      if (text == null || text.isEmpty) continue;

      painter
        ..text = TextSpan(
          text: text,
          style: TextStyle(fontSize: 10, color: color),
        )
        ..layout(maxWidth: slot * 1.6);

      // Centre the label on its own slot; TextOverflow.visible used to let a
      // long label spill over its neighbours.
      painter.paint(
        canvas,
        Offset(slot * (i + 0.5) - painter.width / 2, 0),
      );
    }

    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _LabelsPainter oldDelegate) =>
      oldDelegate.color != color || !_sameLabels(oldDelegate.labels, labels);

  static bool _sameLabels(List<String?> a, List<String?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A thin dashed line over a bar chart, on its own scale.
///
/// Dashed rather than solid so it can never be mistaken for a bar, and drawn
/// last so it stays visible where the two cross.
class ChartDashedLinePainter extends CustomPainter {
  const ChartDashedLinePainter({
    required this.values,
    required this.peak,
    required this.color,
  });

  final List<double> values;

  /// Value that maps to the top of the plot.
  final double peak;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || peak <= 0) return;

    const dash = 5.0;
    const gap = 4.0;

    Offset pointAt(int index) {
      // Slot centres, matching the bars underneath.
      final slot = size.width / values.length;
      return Offset(
        slot * (index + 0.5),
        size.height * (1 - values[index] / peak),
      );
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.55);

    for (var i = 0; i < values.length - 1; i++) {
      final start = pointAt(i);
      final end = pointAt(i + 1);
      final distance = (end - start).distance;
      if (distance <= 0) continue;

      final direction = (end - start) / distance;
      var travelled = 0.0;
      while (travelled < distance) {
        final segmentEnd = math.min(travelled + dash, distance);
        canvas.drawLine(
          start + direction * travelled,
          start + direction * segmentEnd,
          paint,
        );
        travelled = segmentEnd + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ChartDashedLinePainter oldDelegate) =>
      oldDelegate.peak != peak ||
      oldDelegate.color != color ||
      !_sameValues(oldDelegate.values, values);

  static bool _sameValues(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}