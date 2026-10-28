import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/reminder_settings.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/reminder/reminder_cubit.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Settings section for the daily study reminder.
///
/// Modelled on AnkiMobile's Preferences → Review → Notifications: one toggle,
/// a time of day, and which days it fires. The whole section is hidden on
/// platforms that cannot schedule notifications, rather than offering a switch
/// that would never do anything.
///
/// Every change goes out through [onChanged], which is the only path that
/// persists it. The displayed value is read from the [settings] this widget is
/// given, never from local state, so what is on screen is always what is on
/// disk — two sources of truth here made the switch snap back after a tap.
class ReminderSettingsSection extends StatelessWidget {
  const ReminderSettingsSection({
    super.key,
    required this.settings,
    required this.onChanged,
    this.cubit,
  });

  final ReminderSettings settings;
  final ValueChanged<ReminderSettings> onChanged;

  /// Overrides the locator lookup. Only tests supply one, because a
  /// notification plugin cannot be stood up inside a widget test.
  final ReminderCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final provided = cubit;
    if (provided != null) {
      return BlocProvider.value(
        value: provided..refreshStatus(),
        child: _ReminderSettingsView(
          settings: settings,
          onChanged: onChanged,
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<ReminderCubit>()..refreshStatus(),
      child: _ReminderSettingsView(settings: settings, onChanged: onChanged),
    );
  }
}

class _ReminderSettingsView extends StatelessWidget {
  const _ReminderSettingsView({required this.settings, required this.onChanged});

  final ReminderSettings settings;
  final ValueChanged<ReminderSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderCubit, ReminderState>(
      builder: (context, state) {
        // Hidden rather than disabled: a switch that cannot work is worse than
        // no switch, and on these platforms it genuinely cannot work.
        if (state.loading || !state.supported) return const SizedBox.shrink();

        final reminder = settings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              value: reminder.enabled,
              onChanged: (value) => _toggle(context, value),
              title: const Text(AppStrings.reminders),
              subtitle: const Text(AppStrings.reminderHint),
            ),
            if (reminder.enabled && !state.permissionGranted)
              _ReminderWarning(message: AppStrings.reminderPermissionNeeded)
            else if (reminder.enabled && state.notificationsBlocked)
              _ReminderWarning(message: AppStrings.reminderBlocked),
            if (reminder.enabled) ...[
              const SizedBox(height: 8),
              _ReminderTimeTile(
                hour: reminder.hour,
                minute: reminder.minute,
                onChanged: (hour, minute) =>
                    onChanged(reminder.copyWith(hour: hour, minute: minute)),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.reminderDays,
                style: TextStyle(
                  fontSize: 12,
                  color: context.recallColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              _WeekdayPicker(
                settings: reminder,
                onToggle: (weekday) =>
                    onChanged(reminder.toggleWeekday(weekday)),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: reminder.showDueCount,
                onChanged: (value) =>
                    onChanged(reminder.copyWith(showDueCount: value)),
                title: const Text(AppStrings.reminderShowCount),
                subtitle: const Text(AppStrings.reminderShowCountHint),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Turns the reminder on, but only once the OS has agreed to deliver it.
  ///
  /// Asking afterwards would leave a reminder that silently never arrives, and
  /// asking before knowing the answer would show a system dialog for a switch
  /// the user may not end up keeping on.
  Future<void> _toggle(BuildContext context, bool value) async {
    if (value) {
      final cubit = context.read<ReminderCubit>();
      final granted = await cubit.requestPermission();
      if (!granted) {
        if (!context.mounted) return;
        // The cubit knows whether the user refused outright or whether the
        // platform granted permission and then refused to deliver anyway, and
        // the two need different advice.
        final message = cubit.state.notificationsBlocked
            ? AppStrings.reminderBlocked
            : AppStrings.reminderPermissionNeeded;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }
    }
    onChanged(settings.copyWith(enabled: value));
  }
}

class _ReminderWarning extends StatelessWidget {
  const _ReminderWarning({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lemon.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.field),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: colors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftListTile(
      title: AppStrings.reminderTime,
      subtitle:
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      icon: Icons.notifications_active_outlined,
      accent: context.accentColor,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: minute),
        );
        if (picked == null) return;
        onChanged(picked.hour, picked.minute);
      },
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({required this.settings, required this.onToggle});

  final ReminderSettings settings;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // Monday-first ordering is the local convention, not an LTR layout one.
      textDirection: TextDirection.rtl,
      child: Row(
        children: [
          for (var weekday = DateTime.saturday;
              weekday >= DateTime.monday;
              weekday--)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _DayToggle(
                  label: AppStrings.weekdayShort(weekday),
                  selected: settings.includesWeekday(weekday),
                  onTap: () => onToggle(weekday),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? context.accentColor : colors.muted,
        borderRadius: BorderRadius.circular(AppRadii.field),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.field),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? colors.card : colors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}