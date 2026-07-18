/// Selectable flashcard font sizes from 10 to 40 (step 2).
enum CardFontSize {
  size10(10),
  size12(12),
  size14(14),
  size16(16),
  size18(18),
  size20(20),
  size22(22),
  size24(24),
  size26(26),
  size28(28),
  size30(30),
  size32(32),
  size34(34),
  size36(36),
  size38(38),
  size40(40);

  const CardFontSize(this.pointSize);

  final double pointSize;

  static const double minPointSize = 10;
  static const double maxPointSize = 40;
  static const double step = 2;

  /// Discrete slider divisions for Material [Slider].
  static int get divisions => ((maxPointSize - minPointSize) / step).round();

  String get label => pointSize.toInt().toString();

  double sizeFor(String text) =>
      text.length > 60 ? pointSize * 0.85 : pointSize;

  static CardFontSize fromName(String? name) {
    return CardFontSize.values.firstWhere(
      (size) => size.name == name,
      orElse: () => CardFontSize.size16,
    );
  }

  static CardFontSize fromPointSize(num value) {
    final snapped = (value / step).round() * step.toInt();
    final clamped = snapped
        .clamp(minPointSize.toInt(), maxPointSize.toInt())
        .toInt();
    return CardFontSize.values.firstWhere(
      (size) => size.pointSize.toInt() == clamped,
      orElse: () => CardFontSize.size16,
    );
  }
}
