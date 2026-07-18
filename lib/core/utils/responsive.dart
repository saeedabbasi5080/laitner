import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared layout helpers so screens stay usable on small phones.
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);

  bool get isCompactWidth => screenSize.width < 360;

  bool get isShortHeight => screenSize.height < 700;

  double get pageHorizontalPadding => isCompactWidth ? 16.0 : 24.0;

  double get sheetMaxHeight => screenSize.height * 0.85;
}

/// Width for a flashcard that keeps a preferred 3:4 look without overflowing.
Size fitCardSize({
  required double availableWidth,
  required double availableHeight,
  double maxWidth = 384,
  double aspectRatio = 3 / 4,
}) {
  if (availableWidth <= 0 || availableHeight <= 0) {
    return Size.zero;
  }

  var width = math.min(availableWidth, maxWidth);
  var height = width / aspectRatio;
  if (height > availableHeight) {
    height = availableHeight;
    width = math.min(availableWidth, height * aspectRatio);
  }
  return Size(width, height);
}
