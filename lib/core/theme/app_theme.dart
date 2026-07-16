import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/domain/entities/deck_color.dart';

class AppColors {
  static const lavender = Color(0xFFC9B8E8);
  static const mint = Color(0xFFA8E6CF);
  static const peach = Color(0xFFFFD4B8);
  static const sky = Color(0xFFB8D4F0);
  static const rose = Color(0xFFF5B8C8);
  static const danger = Color(0xFFD32F2F);
  static const lemon = Color(0xFFF5E6A8);
  static const coral = Color(0xFFFFB8A8);
  static const teal = Color(0xFFA8E0D8);
  static const lilac = Color(0xFFD4B8F0);
  static const sand = Color(0xFFE8D4B8);
  static const slate = Color(0xFFB8C4D4);
  static const berry = Color(0xFFD4A8C8);

  static Color forDeck(DeckColor color) => switch (color) {
        DeckColor.lavender => lavender,
        DeckColor.mint => mint,
        DeckColor.peach => peach,
        DeckColor.sky => sky,
        DeckColor.rose => rose,
        DeckColor.lemon => lemon,
        DeckColor.coral => coral,
        DeckColor.teal => teal,
        DeckColor.lilac => lilac,
        DeckColor.sand => sand,
        DeckColor.slate => slate,
        DeckColor.berry => berry,
      };
}

@immutable
class RecallColors extends ThemeExtension<RecallColors> {
  const RecallColors({
    required this.card,
    required this.muted,
    required this.mutedForeground,
    required this.border,
    required this.accent,
  });

  final Color card;
  final Color muted;
  final Color mutedForeground;
  final Color border;
  final Color accent;

  static RecallColors dark(Color accent) => RecallColors(
        card: const Color(0xFF2B2F38),
        muted: const Color(0xFF3A3F4B),
        mutedForeground: const Color(0xFF9BA3B4),
        border: const Color(0x14FFFFFF),
        accent: accent,
      );

  static RecallColors light(Color accent) => RecallColors(
        card: const Color(0xFFFFFFFF),
        muted: const Color(0xFFF0F0F3),
        mutedForeground: const Color(0xFF6B7280),
        border: const Color(0x1A000000),
        accent: accent,
      );

  @override
  RecallColors copyWith({
    Color? card,
    Color? muted,
    Color? mutedForeground,
    Color? border,
    Color? accent,
  }) {
    return RecallColors(
      card: card ?? this.card,
      muted: muted ?? this.muted,
      mutedForeground: mutedForeground ?? this.mutedForeground,
      border: border ?? this.border,
      accent: accent ?? this.accent,
    );
  }

  @override
  RecallColors lerp(ThemeExtension<RecallColors>? other, double t) {
    if (other is! RecallColors) return this;
    return RecallColors(
      card: Color.lerp(card, other.card, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      mutedForeground:
          Color.lerp(mutedForeground, other.mutedForeground, t)!,
      border: Color.lerp(border, other.border, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

extension RecallTheme on BuildContext {
  RecallColors get recallColors =>
      Theme.of(this).extension<RecallColors>() ??
      RecallColors.dark(AppAccent.lavender.seed);

  Color get accentColor =>
      Theme.of(this).extension<RecallColors>()?.accent ??
      Theme.of(this).colorScheme.primary;
}

class AppTheme {
  /// تم روشن/تاریک با [ColorScheme.fromSeed] طبق مستند رسمی Material 3.
  static ThemeData light(AppAccent accent) =>
      _build(brightness: Brightness.light, accent: accent);

  static ThemeData dark(AppAccent accent) =>
      _build(brightness: Brightness.dark, accent: accent);

  static ThemeData _build({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      contrastLevel: 0.1,
    ).copyWith(
      surface: isDark ? const Color(0xFF1A1D24) : const Color(0xFFFAFAFA),
      onSurface: isDark ? const Color(0xFFF5F5F7) : const Color(0xFF1A1D24),
    );
    final recallColors = isDark
        ? RecallColors.dark(colorScheme.primary)
        : RecallColors.light(colorScheme.primary);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [recallColors],
    );

    final foreground = colorScheme.onSurface;

    return base.copyWith(
      textTheme: GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
        bodyColor: foreground,
        displayColor: foreground,
      ),
      dividerColor: recallColors.border,
      cardColor: recallColors.card,
      splashColor: foreground.withValues(alpha: 0.08),
      highlightColor: foreground.withValues(alpha: 0.08),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return null;
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
    );
  }
}

class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
        blurRadius: 30,
        offset: const Offset(0, 8),
        spreadRadius: -8,
      ),
    ];
  }

  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.accentColor;
    return [
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
        blurRadius: 50,
        offset: const Offset(0, 20),
        spreadRadius: -15,
      ),
    ];
  }
}
