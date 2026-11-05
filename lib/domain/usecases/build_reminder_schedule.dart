import 'package:recall/core/utils/day_key.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/reminder_settings.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

/// Everything needed to plan reminders for one space.
class ReminderSource {
  const ReminderSource({
    required this.spaceId,
    required this.spaceName,
    required this.settings,
    required this.cards,
    required this.boxes,
  });

  final String spaceId;
  final String spaceName;
  final ReminderSettings settings;
  final List<Flashcard> cards;
  final LeitnerBoxConfig boxes;
}

/// One planned notification.
class ReminderOccurrence {
  const ReminderOccurrence({
    required this.spaceId,
    required this.spaceName,
    required this.when,
    required this.dueCount,
    required this.notificationId,
    required this.showDueCount,
    this.repeatsWeekly = false,
  });

  final String spaceId;
  final String spaceName;

  /// Local wall-clock time the notification should appear.
  final DateTime when;

  /// Cards that will be waiting at [when], i.e. everything due on or before
  /// that day. Anki's daily reminder names this number.
  final int dueCount;

  /// Stable id inside one batch, so the notification queue can address it.
  ///
  /// Not stable across syncs on purpose — the queue is rebuilt from scratch each
  /// time, so uniqueness within a batch is all that is required.
  final int notificationId;

  final bool showDueCount;

  /// A fallback the operating system repeats every week at [when]'s weekday and
  /// time, from [when] on, with no count in it. See [BuildReminderSchedule].
  final bool repeatsWeekly;
}

/// Plans reminder notifications ahead of time.
///
/// A repeating notification carries a fixed body, so a per-day "N cards are
/// waiting" count has to be frozen at scheduling time. That is the same
/// trade-off AnkiMobile makes: it pre-computes the coming days whenever the app
/// is opened and reschedules, because it cannot rely on running in the
/// background to recompute later.
///
/// ## The fallback after the window
///
/// The dated reminders run out after [horizonDays] if nothing refreshes them —
/// the app is not opened and the nightly job is held back by a battery saver.
/// So each enabled weekday also gets a weekly repeating reminder that **starts
/// where the window ends**. The system repeats it on its own, forever, with a
/// generic body (a count frozen today would be wrong next month). Every refresh
/// pushes its start out again, so while the app is in use it never fires and
/// never doubles a dated reminder; it only takes over once refreshes stop.
class BuildReminderSchedule {
  const BuildReminderSchedule();

  /// How far ahead reminders are planned. Matches the seven-day window chosen
  /// for the feature.
  static const horizonDays = 7;

  /// Each space gets a block this large, so a space's day offsets never
  /// collide with another space's: dated reminders take offsets 1–7 and the
  /// weekly fallbacks `horizonDays + weekday`, 8–14.
  static const idsPerSpace = horizonDays + 8;

  List<ReminderOccurrence> call({
    required List<ReminderSource> spaces,
    required DateTime now,
    int horizonDays = BuildReminderSchedule.horizonDays,
  }) {
    // Sorting gives every space a slot that cannot collide with another's.
    // Ids are not expected to survive across syncs: the queue is cancelled and
    // rebuilt wholesale, so only uniqueness within one batch matters.
    final ordered = [...spaces]..sort((a, b) => a.spaceId.compareTo(b.spaceId));
    final occurrences = <ReminderOccurrence>[];

    for (var spaceIndex = 0; spaceIndex < ordered.length; spaceIndex++) {
      final source = ordered[spaceIndex];
      if (!source.settings.enabled) continue;

      occurrences.addAll(
        _forSpace(
          source,
          spaceIndex: spaceIndex,
          now: now,
          horizonDays: horizonDays,
        ),
      );
    }

    return occurrences;
  }

  List<ReminderOccurrence> _forSpace(
    ReminderSource source, {
    required int spaceIndex,
    required DateTime now,
    required int horizonDays,
  }) {
    final settings = source.settings;
    final dueDays = _dueDayNumbers(source);
    final occurrences = <ReminderOccurrence>[];

    for (var offset = 0; offset < horizonDays; offset++) {
      final day = addDays(now, offset);
      if (!settings.includesWeekday(day.weekday)) continue;

      final when = DateTime(
        day.year,
        day.month,
        day.day,
        settings.hour,
        settings.minute,
      );
      // Skip times that have already passed today, so enabling the reminder at
      // 21:00 for 20:00 does not fire one that is already late.
      if (!when.isAfter(now)) continue;

      final targetDay = dayNumber(day);
      final waiting = dueDays.where((dueDay) => dueDay <= targetDay).length;

      occurrences.add(
        ReminderOccurrence(
          spaceId: source.spaceId,
          spaceName: source.spaceName,
          when: when,
          dueCount: waiting,
          notificationId: spaceIndex * idsPerSpace + offset + 1,
          showDueCount: settings.showDueCount,
        ),
      );
    }

    // The weekly fallbacks, each starting on the first enabled weekday at or
    // after the end of the window. Seven consecutive days hold every weekday
    // exactly once.
    for (var offset = horizonDays; offset < horizonDays + 7; offset++) {
      final day = addDays(now, offset);
      if (!settings.includesWeekday(day.weekday)) continue;

      occurrences.add(
        ReminderOccurrence(
          spaceId: source.spaceId,
          spaceName: source.spaceName,
          when: DateTime(
            day.year,
            day.month,
            day.day,
            settings.hour,
            settings.minute,
          ),
          dueCount: 0,
          notificationId: spaceIndex * idsPerSpace + horizonDays + day.weekday,
          showDueCount: false,
          repeatsWeekly: true,
        ),
      );
    }

    return occurrences;
  }

  /// Day numbers on which each card becomes due.
  ///
  /// Graduated cards never come back in this app, so they are left out instead
  /// of being counted as permanently waiting.
  List<int> _dueDayNumbers(ReminderSource source) {
    final result = <int>[];
    for (final card in source.cards) {
      if (source.boxes.isLearnedBox(card.box)) continue;
      result.add(dayNumber(nextReviewDate(card, boxes: source.boxes)));
    }
    return result;
  }
}
