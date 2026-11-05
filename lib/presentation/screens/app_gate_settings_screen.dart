import 'package:flutter/material.dart';
import 'package:recall/core/app_gate/app_gate.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';
import 'package:recall/domain/usecases/sync_app_gate_due_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Settings for the app lock: which apps, which space, how many cards, and the
/// two Android permissions it needs.
///
/// Every change is saved at once — there is no "save" button to forget.
class AppGateSettingsScreen extends StatefulWidget {
  const AppGateSettingsScreen({
    super.key,
    this.platform,
    this.loadSpaces,
    this.syncDue,
  });

  /// Overrides for tests; the app uses the locator.
  final AppGatePlatform? platform;
  final Future<List<LearningSpace>> Function()? loadSpaces;
  final Future<void> Function()? syncDue;

  @override
  State<AppGateSettingsScreen> createState() => _AppGateSettingsScreenState();
}

class _AppGateSettingsScreenState extends State<AppGateSettingsScreen>
    with WidgetsBindingObserver {
  late final AppGatePlatform _platform =
      widget.platform ?? sl<AppGatePlatform>();

  AppGateConfig _config = const AppGateConfig();
  AppGateStatus _status = const AppGateStatus(
    accessibility: false,
    overlay: false,
  );
  List<LearningSpace> _spaces = const [];
  List<InstalledApp>? _apps;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Coming back from the phone's settings is when a permission changes.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _load() async {
    final config = await _platform.loadConfig();
    final status = await _platform.status();
    final spaces = await (widget.loadSpaces ?? sl<GetSpacesUseCase>().call)();
    if (!mounted) return;
    setState(() {
      _config = config;
      _status = status;
      _spaces = spaces;
      _loading = false;
    });
    final apps = await _platform.listApps();
    if (mounted) setState(() => _apps = apps);
  }

  Future<void> _refreshStatus() async {
    final status = await _platform.status();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _update(AppGateConfig config) async {
    setState(() => _config = config);
    await _platform.saveConfig(config);
    // The lock must know today's count for the space now chosen.
    try {
      await (widget.syncDue ?? sl<SyncAppGateDueUseCase>().call)();
    } catch (_) {}
  }

  Future<void> _setEnabled(bool value) async {
    if (value && !_status.ready) {
      final agreed = await _showDisclosure();
      if (agreed != true || !mounted) return;
    }
    await _update(_config.copyWith(enabled: value));
  }

  /// The prominent disclosure: what the accessibility service sees, before
  /// the user is sent to switch it on.
  Future<bool?> _showDisclosure() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.appGateDisclosureTitle),
        content: const SingleChildScrollView(
          child: Text(
            AppStrings.appGateDisclosure,
            style: TextStyle(height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.appGateDisclosureDecline),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.appGateDisclosureAccept),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  const AppPageHeader(
                    title: AppStrings.appGate,
                    subtitle: AppStrings.appGateHint,
                  ),
                  const SizedBox(height: 16),
                  if (!_platform.supported)
                    Text(
                      AppStrings.appGateAndroidOnly,
                      style: TextStyle(color: colors.mutedForeground),
                    )
                  else ...[
                    SwitchListTile.adaptive(
                      value: _config.enabled,
                      onChanged: _setEnabled,
                      title: const Text(AppStrings.appGateEnable),
                    ),
                    const SizedBox(height: 8),
                    _permissions(colors),
                    if (_config.enabled) ...[
                      const SizedBox(height: 20),
                      _spacePicker(),
                      const SizedBox(height: 20),
                      _modePicker(colors),
                      const SizedBox(height: 12),
                      _grace(colors),
                      const SizedBox(height: 20),
                      _appPicker(colors),
                    ],
                  ],
                ],
              ),
      ),
    );
  }

  /// Each permission with one button that goes straight to the place in the
  /// phone's settings where it is switched on, and one line saying what to tap
  /// there. Coming back refreshes the ticks (see [didChangeAppLifecycleState]).
  Widget _permissions(RecallColors colors) {
    Widget step({
      required int number,
      required String title,
      required String hint,
      required String whatToTap,
      required bool granted,
      required VoidCallback open,
      Widget? extra,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  granted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: granted ? AppColors.know : colors.mutedForeground,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$number. $title',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (granted)
                  Text(
                    AppStrings.appGateGranted,
                    style: const TextStyle(color: AppColors.know),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 34, top: 2),
              child: Text(
                hint,
                style: TextStyle(fontSize: 12, color: colors.mutedForeground),
              ),
            ),
            if (!granted) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 34),
                child: Text(whatToTap, style: const TextStyle(fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 34),
                child: FilledButton.icon(
                  onPressed: open,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(AppStrings.appGateOpenSettings),
                ),
              ),
              ?extra,
            ],
          ],
        ),
      );
    }

    Future<void> openAccessibility() async {
      final agreed = await _showDisclosure();
      if (agreed == true) await _platform.openAccessibilitySettings();
    }

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          step(
            number: 1,
            title: AppStrings.appGateAccessibility,
            hint: AppStrings.appGateAccessibilityHint,
            whatToTap: AppStrings.appGateAccessibilitySteps,
            granted: _status.accessibility,
            open: openAccessibility,
            // Android 13+ greys the switch out for apps installed from a file,
            // until "Allow restricted settings" is chosen on the app's info page.
            extra: _RestrictedGuide(onOpenAppInfo: _platform.openAppInfo),
          ),
          Divider(height: 1, color: colors.border),
          step(
            number: 2,
            title: AppStrings.appGateOverlay,
            hint: AppStrings.appGateOverlayHint,
            whatToTap: AppStrings.appGateOverlaySteps,
            granted: _status.overlay,
            open: _platform.openOverlaySettings,
          ),
          if (_config.enabled && !_status.ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                AppStrings.appGateNotReady,
                style: const TextStyle(fontSize: 12, color: AppColors.rose),
              ),
            ),
        ],
      ),
    );
  }

  /// "All spaces" (the default, and it includes spaces made later), or any
  /// set of spaces. Unticking the last chosen space falls back to all, so the
  /// lock is never left with nowhere to take cards from.
  Widget _spacePicker() {
    final all = _config.allSpaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(AppStrings.appGateSpace),
        CheckboxListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: all,
          title: const Text(AppStrings.appGateAllSpaces),
          onChanged: (v) => _update(
            _config.copyWith(
              allSpaces: v ?? true,
              // Starting from a clean choice rather than a stale one.
              spaceIds: const {},
            ),
          ),
        ),
        for (final space in _spaces)
          CheckboxListTile.adaptive(
            contentPadding: const EdgeInsetsDirectional.only(start: 16),
            value: all || _config.spaceIds.contains(space.id),
            enabled: !all,
            title: Text(space.name),
            onChanged: (v) {
              final ids = {..._config.spaceIds};
              v == true ? ids.add(space.id) : ids.remove(space.id);
              _update(
                ids.isEmpty
                    ? _config.copyWith(allSpaces: true, spaceIds: const {})
                    : _config.copyWith(allSpaces: false, spaceIds: ids),
              );
            },
          ),
      ],
    );
  }

  Widget _modePicker(RecallColors colors) {
    Widget option(AppGateMode mode, String title, String hint) =>
        RadioListTile<AppGateMode>.adaptive(
          contentPadding: EdgeInsets.zero,
          value: mode,
          // ignore: deprecated_member_use
          groupValue: _config.mode,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) _update(_config.copyWith(mode: value));
          },
          title: Text(title),
          subtitle: Text(hint, style: const TextStyle(fontSize: 12)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel(AppStrings.appGateMode),
        option(
          AppGateMode.perOpen,
          AppStrings.appGateModePerOpen(_config.cardsPerOpen),
          AppStrings.appGateModePerOpenHint,
        ),
        if (_config.mode == AppGateMode.perOpen)
          _stepper(
            label: AppStrings.appGateCardsPerOpen,
            value: _config.cardsPerOpen,
            text: '${_config.cardsPerOpen}',
            min: AppGateConfig.minCards,
            max: AppGateConfig.maxCards,
            onChanged: (v) => _update(_config.copyWith(cardsPerOpen: v)),
          ),
        option(
          AppGateMode.allDue,
          AppStrings.appGateModeAllDue,
          AppStrings.appGateModeAllDueHint,
        ),
      ],
    );
  }

  Widget _grace(RecallColors colors) {
    return Column(
      children: [
        CheckboxListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _config.graceEnabled,
          onChanged: (v) => _update(_config.copyWith(graceEnabled: v ?? false)),
          title: const Text(AppStrings.appGateGrace),
        ),
        if (_config.graceEnabled)
          _stepper(
            label: '',
            value: _config.graceMinutes,
            text: AppStrings.appGateGraceMinutes(_config.graceMinutes),
            min: AppGateConfig.minGrace,
            max: AppGateConfig.maxGrace,
            onChanged: (v) => _update(_config.copyWith(graceMinutes: v)),
          ),
      ],
    );
  }

  Widget _stepper({
    required String label,
    required int value,
    required String text,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        if (label.isNotEmpty) Expanded(child: Text(label)) else const Spacer(),
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(width: 72, child: Text(text, textAlign: TextAlign.center)),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _appPicker(RecallColors colors) {
    final apps = _apps;
    final query = _query.trim().toLowerCase();
    final shown = apps == null
        ? const <InstalledApp>[]
        : [
            for (final app in apps)
              if (query.isEmpty ||
                  app.label.toLowerCase().contains(query) ||
                  app.package.toLowerCase().contains(query))
                app,
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(AppStrings.appGateApps),
        Text(
          '${AppStrings.appGateSelected(_config.packages.length)} · '
          '${AppStrings.appGateAppsHint}',
          style: TextStyle(fontSize: 12, color: colors.mutedForeground),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: AppStrings.appGateSearch,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 8),
        if (apps == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final app in shown)
            CheckboxListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _config.packages.contains(app.package),
              secondary: app.icon == null
                  ? const Icon(Icons.apps)
                  : Image.memory(app.icon!, width: 36, height: 36),
              title: Text(app.label),
              onChanged: (checked) {
                final packages = {..._config.packages};
                checked == true
                    ? packages.add(app.package)
                    : packages.remove(app.package);
                _update(_config.copyWith(packages: packages));
              },
            ),
      ],
    );
  }
}

/// What to do when Android greys the accessibility switch out.
///
/// Android 13+ does this for every app installed from an APK file, and the
/// way out — "Allow restricted settings" in the app's info menu — is hidden
/// well enough that the switch simply looks broken. Spelled out as numbered
/// steps with the menu's names in English as well, since the
/// phone's own language may not be Persian.
class _RestrictedGuide extends StatelessWidget {
  const _RestrictedGuide({required this.onOpenAppInfo});

  final VoidCallback onOpenAppInfo;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    Widget numbered(int n, String text) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: AppColors.lemon,
            child: Text(
              '$n',
              style: const TextStyle(fontSize: 11, color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsetsDirectional.only(start: 34, top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lemon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.appGateRestrictedTitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.appGateRestrictedIntro,
            style: TextStyle(fontSize: 12, color: colors.mutedForeground),
          ),
          numbered(1, AppStrings.appGateRestrictedStep1),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28, top: 6),
            child: OutlinedButton.icon(
              onPressed: onOpenAppInfo,
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text(AppStrings.appGateOpenAppInfo),
            ),
          ),
          numbered(2, AppStrings.appGateRestrictedStep2),
          const SizedBox(height: 8),
          Text(
            AppStrings.appGateRestrictedNote,
            style: TextStyle(fontSize: 11, color: colors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
