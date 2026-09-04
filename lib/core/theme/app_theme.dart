import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/domain/entities/deck_color.dart';

class AppColors {
  static const lavender = Color(0xFF7C3AED);
  static const mint = Color(0xFF10B981);
  static const peach = Color(0xFFEA580C);
  static const sky = Color(0xFF2563EB);
  static const rose = Color(0xFFDB27B3);
  static const danger = Color(0xFFEF4444);
  static const lemon = Color(0xFFEAB308);
  static const coral = Color(0xFFF97316);
  static const teal = Color(0xFF0D9488);
  static const lilac = Color(0xFF8B5CF6);
  static const sand = Color(0xFFD97706);
  static const slate = Color(0xFF64748B);
  static const berry = Color(0xFFDB27B3);

  static const know = Color(0xFF10B981);
  static const dontKnow = Color(0xFFEF4444);

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

  /// Maps Material 3 surface-container roles from [ColorScheme.fromSeed].
  /// Scaffold uses [ColorScheme.surface]; cards use [ColorScheme.surfaceContainerLow].
  static RecallColors fromScheme(ColorScheme scheme) => RecallColors(
        card: scheme.surfaceContainerLow,
        muted: scheme.surfaceContainerLowest,
        mutedForeground: scheme.onSurfaceVariant,
        border: scheme.outlineVariant,
        accent: scheme.primary,
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
      RecallColors.fromScheme(
        ColorScheme.fromSeed(seedColor: AppAccent.sky.seed),
      );

  Color get accentColor =>
      Theme.of(this).extension<RecallColors>()?.accent ??
      Theme.of(this).colorScheme.primary;

  /// Tonal surface for colored list cards (Material 3 container tint).
  Color tintedSurface(Color tint, {double amount = 0.10}) {
    return Color.alphaBlend(
      tint.withValues(alpha: amount),
      Theme.of(this).colorScheme.surfaceContainerLow,
    );
  }

  (Color fill, Color onFill) leitnerBoxColors(int box) {
    final scheme = Theme.of(this).colorScheme;
    return switch (box) {
      1 => (scheme.primaryContainer, scheme.onPrimaryContainer),
      2 => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      3 => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      4 => (
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.18),
            scheme.surfaceContainerHigh,
          ),
          scheme.onSurface,
        ),
      _ => (
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.30),
            scheme.surfaceContainerHighest,
          ),
          scheme.onSurface,
        ),
    };
  }
}

class AppTheme {
  /// تم روشن/تاریک با [ColorScheme.fromSeed] طبق استاندارد Material 3.
  static ThemeData light(AppAccent accent) =>
      _build(brightness: Brightness.light, accent: accent);

  static ThemeData dark(AppAccent accent) =>
      _build(brightness: Brightness.dark, accent: accent);

  static ThemeData _build({
    required Brightness brightness,
    required AppAccent accent,
  }) {
    final isDark = brightness == Brightness.dark;
    var colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seed,
      brightness: brightness,
      dynamicSchemeVariant:
          isDark ? DynamicSchemeVariant.tonalSpot : DynamicSchemeVariant.vibrant,
    );
    if (isDark) {
      colorScheme = colorScheme.copyWith(
        surface: const Color(0xFF121214),
        onSurface: const Color(0xFFE4E4E7),
      );
    } else {
      colorScheme = colorScheme.copyWith(
        surface: const Color(0xFFF8FAFD),
        surfaceContainerLow: Colors.white,
      );
    }

    final recallColors = RecallColors.fromScheme(colorScheme);

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
      splashColor: foreground.withValues(alpha: 0.06),
      highlightColor: foreground.withValues(alpha: 0.06),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
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
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withValues(
          alpha: 0.60,
        ),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}

class AppShadows {
  static List<BoxShadow> card(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(
          alpha: isDark ? 0.15 : 0.04,
        ),
        blurRadius: 12,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ];
  }

  static List<BoxShadow> floating(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.accentColor;
    return [
      BoxShadow(
        color: accent.withValues(alpha: isDark ? 0.25 : 0.18),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: -4,
      ),
    ];
  }
}
