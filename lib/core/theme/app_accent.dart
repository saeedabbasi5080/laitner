import 'package:flutter/material.dart';

/// پنج رنگ اصلی تم برنامه (seed برای [ColorScheme.fromSeed]).
enum AppAccent {
  lavender(
    Color(0xFF7C3AED),
    'بنفش',
  ),
  mint(
    Color(0xFF00A86B),
    'سبز',
  ),
  peach(
    Color(0xFFFF6D00),
    'نارنجی',
  ),
  sky(
    Color(0xFF1976D2),
    'آبی',
  ),
  rose(
    Color(0xFFE91E63),
    'صورتی',
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
