import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/notifications/notification_service.dart';

part 'reminder_state.dart';

/// Answers one question: what will the operating system actually allow?
///
/// Deliberately holds no reminder settings. Those are the user's preference and
/// live in [SettingsCubit], which is the only thing that persists them. This
/// cubit owns only what the app cannot store — whether notifications are
/// supported, and whether the OS would actually deliver them — because that
/// changes when the user visits system settings without telling the app.
class ReminderCubit extends Cubit<ReminderState> {
  ReminderCubit({required NotificationService notificationService})
      : _notificationService = notificationService,
        super(const ReminderState(supported: false));

  final NotificationService _notificationService;

  /// Reads whether the OS will currently deliver a notification.
  ///
  /// Deliberately does not guess *why* it will not. The platform reports
  /// "notifications are off" the same way whether the user never granted the
  /// runtime permission or switched the channel off in system settings, and
  /// claiming to know which would put the wrong advice in front of the user.
  /// [requestPermission] asks the platform directly, and only then are the two
  /// cases told apart.
  Future<void> refreshStatus() async {
    if (!_notificationService.isSupported) {
      emit(const ReminderState(supported: false, loading: false));
      return;
    }

    final enabled = await _notificationService.areNotificationsEnabled();
    emit(
      ReminderState(
        supported: true,
        loading: false,
        permissionGranted: enabled,
      ),
    );
  }

  /// Asks for the runtime permission and reports whether reminders can fire.
  ///
  /// Called before turning reminders on rather than on open, because asking on
  /// open would put a system dialog in front of someone who has not expressed
  /// any interest yet.
  Future<bool> requestPermission() async {
    if (!_notificationService.isSupported) return false;

    final granted = await _notificationService.requestPermission();
    // Permission can be granted while the OS still has notifications off at
    // the channel level, so the two are checked separately.
    final blocked =
        granted && !await _notificationService.areNotificationsEnabled();

    emit(
      ReminderState(
        supported: true,
        loading: false,
        permissionGranted: granted,
        notificationsBlocked: blocked,
      ),
    );

    return granted && !blocked;
  }
}