part of 'reminder_cubit.dart';

enum ReminderStatus { initial, ready, failed }

/// What the platform will allow. Carries no reminder settings — see
/// [ReminderCubit] for why that split matters.
class ReminderState extends Equatable {
  const ReminderState({
    required this.supported,
    this.status = ReminderStatus.initial,
    this.loading = true,
    this.permissionGranted = true,
    this.notificationsBlocked = false,
  });

  /// False on platforms without a notification scheduler, in which case the
  /// whole section is hidden rather than shown as broken.
  final bool supported;

  final ReminderStatus status;
  final bool loading;

  /// Whether the user has granted permission to post notifications.
  final bool permissionGranted;

  /// Permission was granted but the OS still has notifications switched off.
  final bool notificationsBlocked;

  /// True while the platform has not reported back yet.
  ///
  /// The section stays hidden for this, so a switch never appears in a state
  /// the OS might contradict a moment later.
  bool get canToggle => supported && permissionGranted && !notificationsBlocked;

  @override
  List<Object?> get props => [
        supported,
        status,
        loading,
        permissionGranted,
        notificationsBlocked,
      ];
}