import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/theme/card_font_size.dart';
import 'package:recall/core/tts/auto_speak_side.dart';
import 'package:recall/core/tts/tts_language.dart';
import 'package:recall/core/utils/responsive.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/settings/settings_cubit.dart';
import 'package:recall/presentation/screens/about_app_screen.dart';
import 'package:recall/presentation/screens/developer_screen.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.spaceId});

  final String? spaceId;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSpace(widget.spaceId);
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spaceId != oldWidget.spaceId) {
      _loadSpace(widget.spaceId);
    }
  }

  void _loadSpace(String? spaceId) {
    if (spaceId != null) {
      sl<SettingsCubit>().loadForSpace(spaceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsView(hasSpace: widget.spaceId != null);
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({required this.hasSpace});

  final bool hasSpace;

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
                AppPageHeader(title: AppStrings.settings),
                const SizedBox(height: 24),
                const SectionLabel(AppStrings.appearance),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context)
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
                if (hasSpace) ...[
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context)
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context)
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.volume_up_outlined, color: accent),
                        title: const Text(AppStrings.ttsLanguage),
                        subtitle: Text(state.ttsLanguage.label),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () =>
                            _selectTtsLanguage(context, state.ttsLanguage),
                      ),
                      Divider(height: 1, color: colors.border),
                      SwitchListTile(
                        secondary: Icon(Icons.record_voice_over, color: accent),
                        title: const Text(AppStrings.autoSpeak),
                        subtitle: const Text(AppStrings.autoSpeakHint),
                        value: state.autoSpeak,
                        onChanged: (enabled) =>
                            context.read<SettingsCubit>().setAutoSpeak(enabled),
                      ),
                      Divider(height: 1, color: colors.border),
                      SwitchListTile(
                        secondary: Icon(Icons.swap_vert, color: accent),
                        title: const Text(AppStrings.autoSpeakSide),
                        subtitle: Text(
                          state.autoSpeakSide == AutoSpeakSide.back
                              ? AppStrings.autoSpeakBack
                              : AppStrings.autoSpeakFront,
                        ),
                        value: state.autoSpeakSide == AutoSpeakSide.back,
                        onChanged: state.autoSpeak
                            ? (back) => context
                                  .read<SettingsCubit>()
                                  .setAutoSpeakSide(
                                    back
                                        ? AutoSpeakSide.back
                                        : AutoSpeakSide.front,
                                  )
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const SectionLabel(AppStrings.reviewSettings),
                const SizedBox(height: 8),
                Text(
                  AppStrings.reviewSettingsSpaceHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context)
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(Icons.flip, color: accent),
                        title: const Text(AppStrings.defaultCardDirection),
                        subtitle: Text(
                          state.defaultReversed
                              ? AppStrings.reversedReview
                              : AppStrings.normalReview,
                        ),
                        value: state.defaultReversed,
                        onChanged: (enabled) => context
                            .read<SettingsCubit>()
                            .setDefaultReversed(enabled),
                      ),
                      Divider(height: 1, color: colors.border),
                      SwitchListTile(
                        secondary: Icon(Icons.shuffle, color: accent),
                        title: const Text(AppStrings.randomReviewOrder),
                        subtitle: const Text(AppStrings.randomReviewOrderHint),
                        value: state.randomReviewOrder,
                        onChanged: (enabled) => context
                            .read<SettingsCubit>()
                            .setRandomReviewOrder(enabled),
                      ),
                      Divider(height: 1, color: colors.border),
                      _CardFontSizePicker(
                        value: state.cardFontSize,
                        onChanged: (size) =>
                            context.read<SettingsCubit>().setCardFontSize(size),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ],
                const SectionLabel(AppStrings.about),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context)
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
      constraints: BoxConstraints(maxHeight: context.sheetMaxHeight * 0.85),
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

class _CardFontSizePicker extends StatelessWidget {
  const _CardFontSizePicker({required this.value, required this.onChanged});

  final CardFontSize value;
  final ValueChanged<CardFontSize> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final accent = context.accentColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_size, color: accent),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  AppStrings.cardFontSize,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.cardFontSizeHint,
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Text(
                  AppStrings.cardFontSizePreview,
                  style: TextStyle(fontSize: 11, color: colors.mutedForeground),
                ),
                const SizedBox(height: 10),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 160),
                  style: TextStyle(
                    fontSize: value.pointSize,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  child: const Text(
                    AppStrings.cardFontSizePreviewWord,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Material: discrete slider with end icons; keep LTR so small→large
          // reads left→right as in the official slider guidelines.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 18,
                  color: colors.mutedForeground,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accent,
                      inactiveTrackColor: accent.withValues(alpha: 0.2),
                      thumbColor: accent,
                      overlayColor: accent.withValues(alpha: 0.12),
                      valueIndicatorColor: accent,
                      showValueIndicator: ShowValueIndicator.never,
                    ),
                    child: Slider(
                      value: value.pointSize,
                      min: CardFontSize.minPointSize,
                      max: CardFontSize.maxPointSize,
                      divisions: CardFontSize.divisions,
                      label: value.label,
                      semanticFormatterCallback: (v) =>
                          AppStrings.cardFontSizeValue(v.round()),
                      onChanged: (next) =>
                          onChanged(CardFontSize.fromPointSize(next)),
                    ),
                  ),
                ),
                Icon(Icons.text_fields, size: 28, color: accent),
              ],
            ),
          ),
        ],
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
              : Theme.of(context).colorScheme.onSurface;

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
