import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/core/utils/nightly_window.dart';
import 'package:recall/data/datasources/http_sync_remote.dart';
import 'package:recall/data/datasources/preferences_sync_state_store.dart';
import 'package:recall/data/datasources/secure_auth_token_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/data/datasources/storage_setup.dart';
import 'package:recall/domain/usecases/sync_collection_usecase.dart';
import 'package:recall/domain/usecases/sync_reminders_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// The nightly jobs: two Android WorkManager jobs, each a one-off that
/// schedules its successor.
///
/// - **Sync**, due at 03:00, with a "connected" constraint: a phone that is
///   offline at three runs it on the first connection, days later if need be,
///   whether or not the app is open.
/// - **Reminders**, due at 03:30, with no constraint: rebuilds the coming week's
///   study reminders from the cards on the phone. Without it the reminder queue
///   is refilled only when the app is opened, so somebody who stops opening it
///   runs out of reminders exactly when one would help. After the sync, so the
///   counts include cards the sync brought in.
///
/// Neither is exact. Android batches background work, so in Doze a job can start
/// some minutes to an hour late. A force-stopped app, or one a manufacturer's
/// battery saver has put to sleep, runs nothing until it is opened again.
///
/// One-offs rather than periodic jobs: a periodic job's start drifts with every
/// late run, and after a few weeks "three o'clock" would mean the afternoon.
const String nightlySyncTask = 'atilearn-nightly-sync';
const String nightlyRemindersTask = 'atilearn-nightly-reminders';

/// Starts the jobs if there are none. Called on every launch, so a phone whose
/// jobs were lost — the app updated, the user cleared its data — gets them back.
Future<void> ensureNightlySyncScheduled() async {
  if (!_supported) return;
  await Workmanager().initialize(nightlySyncDispatcher);
  await _scheduleSync(ExistingWorkPolicy.keep);
  await _scheduleReminders(ExistingWorkPolicy.keep);
}

/// The background entry point. Runs in its own isolate, with none of the app's
/// dependency container, so it builds what each job needs itself.
@pragma('vm:entry-point')
void nightlySyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final reminders = task == nightlyRemindersTask;
    try {
      DartPluginRegistrant.ensureInitialized();
      await (reminders ? _runReminders() : _runSync());
    } catch (error, stack) {
      // Silent, like the app's own automatic sync. A failure here is retried by
      // the next launch and by tomorrow night; a retry storm on a server that is
      // down would help nobody.
      debugPrint('Nightly job $task failed: $error\n$stack');
    }
    try {
      // Appended: this job is still running, and replacing it would cancel it.
      await (reminders
          ? _scheduleReminders(ExistingWorkPolicy.append)
          : _scheduleSync(ExistingWorkPolicy.append));
    } catch (error, stack) {
      debugPrint(
        'Nightly job $task could not schedule the next run: $error\n$stack',
      );
    }
    return true;
  });
}

Future<void> _runSync() async {
  final prefs = await SharedPreferences.getInstance();
  final tokens = SecureAuthTokenStore(preferences: prefs);
  final session = await tokens.read();
  if (session == null || session.accessToken.isEmpty) return;

  final local = await createLocalDataSource(prefs);
  await SyncCollectionUseCase(
    localDataSource: local,
    remote: HttpSyncRemote(tokenStore: tokens),
    state: PreferencesSyncStateStore(prefs: prefs),
  ).sync();
}

/// For everybody, signed in or not: reminders are a feature of the phone.
Future<void> _runReminders() async {
  final prefs = await SharedPreferences.getInstance();
  final local = await createLocalDataSource(prefs);
  await SyncRemindersUseCase(
    localDataSource: local,
    spaceSettingsStore: SpaceSettingsStore(prefs),
    notificationService: NotificationService(),
  ).call();
}

Future<void> _scheduleSync(ExistingWorkPolicy policy) {
  return Workmanager().registerOneOffTask(
    nightlySyncTask,
    nightlySyncTask,
    initialDelay: untilNextNightlySync(DateTime.now()),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: policy,
  );
}

Future<void> _scheduleReminders(ExistingWorkPolicy policy) {
  return Workmanager().registerOneOffTask(
    nightlyRemindersTask,
    nightlyRemindersTask,
    initialDelay: untilNextDailyTime(
      DateTime.now(),
      hour: nightlySyncHour,
      minute: 30,
    ),
    existingWorkPolicy: policy,
  );
}

bool get _supported =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
