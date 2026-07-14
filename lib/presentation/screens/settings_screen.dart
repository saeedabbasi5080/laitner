import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            final isDark = state.themeMode == ThemeMode.dark;
            final accent = context.accentColor;

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    CircleIconButton(
                      back: true,
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      AppStrings.settings,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const SectionLabel(AppStrings.appearance),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: SwitchListTile(
                    title: const Text(AppStrings.themeMode),
                    subtitle: Text(
                      isDark ? AppStrings.darkMode : AppStrings.lightMode,
                    ),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: accent,
                    ),
                    value: isDark,
                    onChanged: (dark) {
                      context.read<SettingsCubit>().setThemeMode(
                            dark ? ThemeMode.dark : ThemeMode.light,
                          );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const SectionLabel(AppStrings.themeAccent),
                const SizedBox(height: 8),
                Text(
                  AppStrings.themeAccentHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final option in AppAccent.values)
                        _AccentSwatch(
                          accent: option,
                          selected: state.accent == option,
                          onTap: () =>
                              context.read<SettingsCubit>().setAccent(option),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: accent.label,
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.seed,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.seed.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, size: 20, color: Color(0xFF1A1D24))
              : null,
        ),
      ),
    );
  }
}
