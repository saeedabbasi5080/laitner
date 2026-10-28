import 'package:equatable/equatable.dart';

/// A study reminder for one space, modelled on AnkiMobile's
/// Preferences → Review → Notifications section.
///
/// Anki keeps this to a single "alert when due" toggle plus a time of day.
/// This adds a weekday mask because it costs nothing and covers the common
/// "weekdays only, not the weekend" case.
class ReminderSettings extends Equatable {
  const ReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    this.daysOfWeek = allDays,
    this.showDueCount = true,
  });

  /// Every day of the week is included in a reminder.
  static const allDays = 0x7F;

  /// A single bit per weekday, using [DateTime.monday] as bit 0.
  static const mondayBit = 1 << DateTime.monday - 1;
  static const tuesdayBit = 1 << DateTime.tuesday - 1;
  static const wednesdayBit = 1 << DateTime.wednesday - 1;
  static const thursdayBit = 1 << DateTime.thursday - 1;
  static const fridayBit = 1 << DateTime.friday - 1;
  static const saturdayBit = 1 << DateTime.saturday - 1;
  static const sundayBit = 1 << DateTime.sunday - 1;

  final bool enabled;
  final int hour;
  final int minute;
  final int daysOfWeek;

  /// Whether the notification body names how many cards are waiting, the way
  /// Anki's daily reminder does.
  final bool showDueCount;

  /// True when [weekday] (1..7, Monday first) is selected.
  bool includesWeekday(int weekday) =>
      weekday >= DateTime.monday &&
      weekday <= DateTime.sunday &&
      (daysOfWeek & (1 << weekday - 1)) != 0;

  /// Total minutes since midnight, handy for comparisons and sorting.
  int get minutesOfDay => hour * 60 + minute;

  /// Turning a day on when it would be the last one selected is ignored, so
  /// the mask can never become empty and silently mute the reminder.
  ReminderSettings toggleWeekday(int weekday) {
    if (weekday < DateTime.monday || weekday > DateTime.sunday) return this;

    final bit = 1 << weekday - 1;
    final next = daysOfWeek ^ bit;
    if (next == 0) return this;
    return copyWith(daysOfWeek: next);
  }

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    int? daysOfWeek,
    bool? showDueCount,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: (hour ?? this.hour).clamp(0, 23),
      minute: (minute ?? this.minute).clamp(0, 59),
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      showDueCount: showDueCount ?? this.showDueCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'daysOfWeek': daysOfWeek,
        'showDueCount': showDueCount,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReminderSettings();
    // A stored mask of zero would mean "never"; fall back to every day rather
    // than leaving the user with a reminder that can never fire.
    final storedMask = json['daysOfWeek'] as int? ?? allDays;
    return ReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      hour: (json['enabled'] == true ? json['hour'] : null) as int? ?? 20,
      minute: (json['enabled'] == true ? json['minute'] : null) as int? ?? 0,
      daysOfWeek: storedMask == 0 ? allDays : storedMask,
      showDueCount: json['showDueCount'] as bool? ?? true,
    );
  }

  @override
  List<Object> get props => [enabled, hour, minute, daysOfWeek, showDueCount];
}