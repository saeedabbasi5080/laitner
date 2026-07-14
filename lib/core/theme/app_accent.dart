import 'package:flutter/material.dart';

/// پنج رنگ اصلی تم برنامه (seed برای [ColorScheme.fromSeed]).
enum AppAccent {
  lavender(
    Color(0xFFC9B8E8),
    'یاسی',
  ),
  mint(
    Color(0xFFA8E6CF),
    'نعنایی',
  ),
  peach(
    Color(0xFFFFD4B8),
    'هلویی',
  ),
  sky(
    Color(0xFFB8D4F0),
    'آسمانی',
  ),
  rose(
    Color(0xFFF5B8C8),
    'گل‌سرخی',
  );

  const AppAccent(this.seed, this.label);

  final Color seed;
  final String label;

  static AppAccent fromName(String? name) {
    return AppAccent.values.firstWhere(
      (a) => a.name == name,
      orElse: () => AppAccent.lavender,
    );
  }
}
