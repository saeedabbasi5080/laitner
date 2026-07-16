import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/screens/about_app_screen.dart';
import 'package:recall/presentation/screens/developer_screen.dart';
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
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
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
                const SizedBox(height: 32),
                const SectionLabel(AppStrings.pronunciation),
                const SizedBox(height: 8),
                Text(
                  AppStrings.ttsLanguageHint,
                  style: TextStyle(fontSize: 12, color: colors.mutedForeground),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.volume_up_outlined, color: accent),
                    title: const Text(AppStrings.ttsLanguage),
                    subtitle: Text(state.ttsLanguage.label),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => _selectTtsLanguage(context, state.ttsLanguage),
                  ),
                ),
                const SizedBox(height: 32),
                const SectionLabel(AppStrings.about),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline, color: accent),
                        title: const Text(AppStrings.aboutApp),
                        subtitle: const Text(AppStrings.appVersion),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: colors.border),
                      ListTile(
                        leading: Icon(Icons.code_outlined, color: accent),
                        title: const Text(AppStrings.aboutDeveloper),
                        subtitle: const Text(AppStrings.developerTitle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DeveloperScreen(),
                          ),
                        ),
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

  void _selectTtsLanguage(BuildContext context, TtsLanguage current) {
    final cubit = context.read<SettingsCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TtsLanguageSheet(
        current: current,
        onSelected: (language) {
          cubit.setTtsLanguage(language);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _TtsLanguageSheet extends StatelessWidget {
  const _TtsLanguageSheet({required this.current, required this.onSelected});

  final TtsLanguage current;
  final ValueChanged<TtsLanguage> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final accent = context.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  AppStrings.selectTtsLanguage,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: TtsLanguage.values.length,
                itemBuilder: (context, index) {
                  final language = TtsLanguage.values[index];
                  final selected = language == current;
                  return ListTile(
                    title: Text(language.label),
                    subtitle: Text(
                      language.code,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.mutedForeground,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check_circle, color: accent)
                        : null,
                    onTap: () => onSelected(language),
                  );
                },
              ),
            ),
          ],
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
    final checkColor =
        ThemeData.estimateBrightnessForColor(accent.seed) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1A1D24);

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
              ? Icon(Icons.check, size: 20, color: checkColor)
              : null,
        ),
      ),
    );
  }
}
