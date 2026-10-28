import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/reminder_settings.dart';
import 'package:recall/presentation/blocs/reminder/reminder_cubit.dart';
import 'package:recall/presentation/widgets/reminder_settings_section.dart';

/// Stands in for the plugin, which is not available in a widget test.
class _FakeNotificationService implements NotificationService {
  bool supported = true;
  bool granted = true;
  bool blocked = false;

  int permissionRequests = 0;
  int statusReads = 0;

  @override
  bool get isSupported => supported;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return granted;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    statusReads++;
    return granted && !blocked;
  }

  @override
  Future<void> initialize({void Function(String? payload)? onTap}) async {}

  @override
  Future<void> replaceAll(List<ScheduledReminder> reminders) async {}

  @override
  Future<void> clearAll() async {}
}

void main() {
  final service = _FakeNotificationService();

  Widget host(
    ReminderSettings settings,
    ValueChanged<ReminderSettings> onChanged,
  ) {
    return MaterialApp(
      theme: AppTheme.light(AppAccent.lavender),
      home: Scaffold(
        body: ReminderSettingsSection(
          settings: settings,
          onChanged: onChanged,
          cubit: ReminderCubit(notificationService: service),
        ),
      ),
    );
  }

  setUp(() {
    service.supported = true;
    service.granted = true;
    service.blocked = false;
    service.permissionRequests = 0;
    service.statusReads = 0;
  });

  group('the switch shows what is saved', () {
    testWidgets('an enabled reminder opens switched on', (tester) async {
      await tester.pumpWidget(
        host(const ReminderSettings(enabled: true), (_) {}),
      );
      await tester.pumpAndSettle();

      final toggle =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile).first);
      expect(toggle.value, isTrue);
      expect((toggle.title! as Text).data, AppStrings.reminders);
    });

    testWidgets('a disabled reminder opens switched off', (tester) async {
      await tester.pumpWidget(host(const ReminderSettings(), (_) {}));
      await tester.pumpAndSettle();

      final toggle =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile).first);
      expect(toggle.value, isFalse);
    });
  });

  group('permission', () {
    testWidgets('is asked for when turning on, not on open', (tester) async {
      await tester.pumpWidget(host(const ReminderSettings(), (_) {}));
      await tester.pumpAndSettle();

      expect(
        service.permissionRequests,
        0,
        reason: 'opening settings must not raise a system dialog',
      );

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      expect(service.permissionRequests, 1);
    });

    testWidgets('a denial leaves the reminder off', (tester) async {
      service.granted = false;
      var reported = const ReminderSettings();

      await tester.pumpWidget(host(const ReminderSettings(), (next) {
        reported = next;
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      // Nothing is saved, so a denied permission cannot leave a reminder that
      // silently never arrives.
      expect(reported.enabled, isFalse);
    });

    testWidgets('opening checks the status without asking', (tester) async {
      await tester.pumpWidget(host(const ReminderSettings(), (_) {}));
      await tester.pumpAndSettle();

      expect(
        service.statusReads,
        greaterThan(0),
        reason: 'a permission revoked in system settings must be noticed',
      );
      expect(service.permissionRequests, 0);
    });

    testWidgets('a blocked channel is explained after an attempt',
        (tester) async {
      // Permission is granted, but the OS will not deliver anyway: the
      // platform tells us this only once we have asked it directly.
      service.blocked = true;
      var reported = const ReminderSettings();

      await tester.pumpWidget(host(const ReminderSettings(), (next) {
        reported = next;
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      expect(reported.enabled, isFalse);
      expect(find.text(AppStrings.reminderBlocked), findsOneWidget);
    });

    testWidgets('a refused permission is explained', (tester) async {
      service.granted = false;

      await tester.pumpWidget(
        host(const ReminderSettings(enabled: true), (_) {}),
      );
      await tester.pumpAndSettle();

      // The section cannot tell refusal from a disabled channel without asking,
      // so it gives the advice that covers both rather than guessing wrong.
      expect(find.textContaining('یادآوری'), findsWidgets);
    });
  });

  group('every change reaches the store', () {
    testWidgets('the main toggle reports the new setting', (tester) async {
      var reported = const ReminderSettings();

      await tester.pumpWidget(host(const ReminderSettings(), (next) {
        reported = next;
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      expect(reported.enabled, isTrue);
    });

    testWidgets('turning it back off reports that too', (tester) async {
      var reported = const ReminderSettings(enabled: true);

      await tester.pumpWidget(host(const ReminderSettings(enabled: true), (next) {
        reported = next;
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pumpAndSettle();

      expect(reported.enabled, isFalse);
    });

    testWidgets('the due-count toggle is reported', (tester) async {
      final reported = <ReminderSettings>[];

      await tester.pumpWidget(
        host(const ReminderSettings(enabled: true), reported.add),
      );
      await tester.pumpAndSettle();

      // Two switches: the main toggle, then the due-count one.
      final switches = find.byType(SwitchListTile);
      expect(switches, findsNWidgets(2));

      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last.showDueCount, isFalse);
    });

    testWidgets('a weekday toggle is reported', (tester) async {
      const settings = ReminderSettings(enabled: true);
      final reported = <ReminderSettings>[];

      await tester.pumpWidget(host(settings, reported.add));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.text(AppStrings.weekdayShort(DateTime.saturday)),
        ),
      );
      await tester.pumpAndSettle();

      expect(reported, isNotEmpty);
      expect(reported.last.daysOfWeek, isNot(settings.daysOfWeek),
          reason: 'the day set has to change, and it has to be reported');
    });
  });

  group('where it cannot work', () {
    testWidgets('the section is hidden', (tester) async {
      service.supported = false;

      await tester.pumpWidget(
        host(const ReminderSettings(enabled: true), (_) {}),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsNothing);
    });
  });
}