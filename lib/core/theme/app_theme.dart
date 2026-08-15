import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/domain/entities/deck_color.dart';

class AppColors {
  static const lavender = Color(0xFF7B5CB8);
  static const mint = Color(0xFF2E9A72);
  static const peach = Color(0xFFD97A45);
  static const sky = Color(0xFF3D8BC4);
  static const rose = Color(0xFFC45A78);
  static const danger = Color(0xFFB71C1C);
  static const lemon = Color(0xFFC4A832);
  static const coral = Color(0xFFD45C48);
  static const teal = Color(0xFF2A9A8C);
  static const lilac = Color(0xFF8A5CB8);
  static const sand = Color(0xFFB8894A);
  static const slate = Color(0xFF5A6E86);
  static const berry = Color(0xFFB04A7A);
  static const know = Color(0xFF1B7A4A);
  static const dontKnow = Color(0xFFC62828);

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
        muted: scheme.surfaceContainerHighest,
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
        ColorScheme.fromSeed(seedColor: AppAccent.lavender.seed),
      );

  Color get accentColor =>
      Theme.of(this).extension<RecallColors>()?.accent ??
      Theme.of(this).colorScheme.primary;

  /// Tonal surface for colored list cards (Material 3 container tint).
  Color tintedSurface(Color tint, {double amount = 0.14}) {
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
            scheme.primary.withValues(alpha: 0.22),
            scheme.surfaceContainerHigh,
          ),
          scheme.onSurface,
        ),
      _ => (
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.34),
            scheme.surfaceContainerHighest,
          ),
          scheme.onSurface,
        ),
    };
  }
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
    // Light uses vibrant so containers pick up seed chroma; dark keeps tonalSpot
    // so surfaces stay readable. Do not override light surface — that flattened
    // cards and buttons into the same beige as the scaffold.
    var colorScheme = ColorScheme.fromSeed(
      seedColor: accent.seed,
      brightness: brightness,
      dynamicSchemeVariant:
          isDark ? DynamicSchemeVariant.tonalSpot : DynamicSchemeVariant.vibrant,
    );
    if (isDark) {
      colorScheme = colorScheme.copyWith(
        surface: const Color(0xFF1A1D24),
        onSurface: const Color(0xFFF5F5F7),
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
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
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
