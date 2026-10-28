import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Whether the current platform can schedule a notification for later.
///
/// Browsers and Linux desktops have no scheduler behind the Notifications API,
/// so the feature is hidden there instead of silently never firing.
bool get reminderSchedulingSupported {
  if (kIsWeb) return false;
  if (defaultTargetPlatform == TargetPlatform.android) return true;
  if (defaultTargetPlatform == TargetPlatform.iOS) return true;
  if (defaultTargetPlatform == TargetPlatform.macOS) return true;
  // Windows only supports one-shot toasts, and Linux has no scheduler at all.
  if (!kIsWeb && Platform.isWindows) return true;
  return false;
}

/// A notification that should appear at a known moment.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    this.payload,
  });

  final int id;
  final String title;
  final String body;

  /// Local wall-clock time the notification should appear.
  final DateTime when;
  final String? payload;
}

/// Thin wrapper over `flutter_local_notifications`.
///
/// Keeps plugin details — channels, exact-alarm permissions, the sixty-four
/// pending-request budget iOS imposes — out of the rest of the app.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// iOS keeps only the most recent 64 pending requests, so the schedule is
  /// trimmed to stay well inside that.
  static const _pendingBudget = 56;

  static const _channelId = 'atilearn_daily_reminder';
  static const _channelName = 'یادآور مرور';
  static const _channelDescription = 'یادآور روزانه‌ی زمان مرور کارت‌ها';

  bool _initialized = false;

  bool get isSupported => reminderSchedulingSupported;

  Future<void> initialize({void Function(String? payload)? onTap}) async {
    if (_initialized || !isSupported) return;

    // The timezone database must be loaded before any TZDateTime is built.
    tz_data.initializeTimeZones();
    await _applyLocalTimezone();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Reminders are useful even while the app is open.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );

    _initialized = true;
  }

  Future<void> _applyLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (error) {
      // Falling back to UTC keeps scheduling working; times would simply be
      // interpreted in UTC rather than the device's zone.
      debugPrint('Could not resolve the device timezone: $error');
    }
  }

  /// Asks for permission to post notifications.
  ///
  /// Returns `false` when the user declined or notifications are blocked at the
  /// OS level, so the settings screen can explain why nothing will arrive.
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await initialize();

    if (kIsWeb) {
      final web = _plugin.resolvePlatformSpecificImplementation<
          WebFlutterLocalNotificationsPlugin>();
      return await web?.requestNotificationsPermission() ?? false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;

      final granted = await android.requestNotificationsPermission() ?? false;
      if (!granted) return false;

      // Exact alarms were separated out in Android 14. Without them the
      // reminder still fires, just with the system's own timing tolerance.
      await android.requestExactAlarmsPermission();
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final darwin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await darwin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  /// Whether the OS currently allows this app to post notifications.
  Future<bool> areNotificationsEnabled() async {
    if (!isSupported) return false;
    await initialize();

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.areNotificationsEnabled() ?? true;

    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final check = await darwin?.checkPermissions();
    if (check != null) {
      return check.isEnabled ||
          check.isAlertEnabled ||
          check.isBadgeEnabled ||
          check.isSoundEnabled;
    }
    return true;
  }

  /// Replaces every reminder with [reminders].
  ///
  /// The whole set is cancelled first because the due counts change whenever
  /// cards are reviewed; leaving the old ones behind would show stale numbers.
  Future<void> replaceAll(List<ScheduledReminder> reminders) async {
    if (!isSupported) return;
    await initialize();

    await _plugin.cancelAllPendingNotifications();

    // Nearest first, so trimming the tail drops the furthest-out reminders.
    final ordered = [...reminders]
      ..sort((a, b) => a.when.compareTo(b.when));

    for (final reminder in ordered.take(_pendingBudget)) {
      await _schedule(reminder);
    }
  }

  Future<void> _schedule(ScheduledReminder reminder) async {
    final when = tz.TZDateTime(
      tz.local,
      reminder.when.year,
      reminder.when.month,
      reminder.when.day,
      reminder.when.hour,
      reminder.when.minute,
    );

    try {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.payload,
      );
    } catch (error) {
      debugPrint('Could not schedule reminder ${reminder.id}: $error');
    }
  }

  /// Clears every pending reminder, used when the last space turns its
  /// reminder off.
  Future<void> clearAll() async {
    if (!isSupported) return;
    await initialize();
    await _plugin.cancelAllPendingNotifications();
  }
}