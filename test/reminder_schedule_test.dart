import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/day_key.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/entities/reminder_settings.dart';
import 'package:recall/domain/usecases/build_reminder_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Wednesday at 09:00 local time.
final _now = DateTime(2026, 3, 11, 9);

Flashcard _card({required String id, int box = 1, DateTime? lastReviewed}) {
  return Flashcard(
    id: id,
    deckId: 'deck-1',
    front: id,
    back: id,
    box: box,
    lastReviewed: lastReviewed,
    createdAt: lastReviewed ?? _now,
  );
}

ReminderSource _source({
  String spaceId = 'space-1',
  String spaceName = 'English',
  ReminderSettings settings = const ReminderSettings(enabled: true),
  List<Flashcard> cards = const [],
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  return ReminderSource(
    spaceId: spaceId,
    spaceName: spaceName,
    settings: settings,
    cards: cards,
    boxes: boxes,
  );
}

void main() {
  const builder = BuildReminderSchedule();

  group('ReminderSettings', () {
    test('defaults to off, every day, with the count shown', () {
      const settings = ReminderSettings();

      expect(settings.enabled, isFalse);
      expect(settings.daysOfWeek, ReminderSettings.allDays);
      expect(settings.showDueCount, isTrue);
      for (var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++) {
        expect(settings.includesWeekday(weekday), isTrue);
      }
    });

    test('cannot toggle off the last selected day', () {
      const onlyMonday = ReminderSettings(daysOfWeek: ReminderSettings.mondayBit);

      expect(onlyMonday.toggleWeekday(DateTime.monday), onlyMonday);
      expect(onlyMonday.includesWeekday(DateTime.monday), isTrue);
    });

    test('toggling adds and removes days', () {
      const settings = ReminderSettings(daysOfWeek: ReminderSettings.mondayBit);

      final added = settings.toggleWeekday(DateTime.friday);
      expect(added.includesWeekday(DateTime.friday), isTrue);
      expect(added.includesWeekday(DateTime.monday), isTrue);

      final removed = added.toggleWeekday(DateTime.monday);
      expect(removed.includesWeekday(DateTime.monday), isFalse);
      expect(removed.includesWeekday(DateTime.friday), isTrue);
    });

    test('clamps an out-of-range time and rejects an empty stored mask', () {
      final clamped = const ReminderSettings().copyWith(hour: 30, minute: -5);
      expect(clamped.hour, 23);
      expect(clamped.minute, 0);

      // A stored mask of zero would silence the reminder forever.
      final restored = ReminderSettings.fromJson({
        'enabled': true,
        'hour': 9,
        'daysOfWeek': 0,
      });
      expect(restored.daysOfWeek, ReminderSettings.allDays);
      expect(restored.hour, 9);
    });

    test('survives a json round trip', () {
      const settings = ReminderSettings(
        enabled: true,
        hour: 7,
        minute: 30,
        daysOfWeek: ReminderSettings.mondayBit | ReminderSettings.thursdayBit,
        showDueCount: false,
      );

      expect(ReminderSettings.fromJson(settings.toJson()), settings);
    });
  });

  group('BuildReminderSchedule', () {
    test('skips a reminder whose time already passed today', () {
      // 08:00 has already gone by at 09:00, so today must not be scheduled.
      final occurrences = builder.call(
        spaces: [
          _source(
            settings: const ReminderSettings(enabled: true, hour: 8, minute: 0),
          ),
        ],
        now: _now,
      );

      expect(occurrences.any((item) => item.when.day == _now.day), isFalse);
      // The rest of the week is untouched.
      expect(occurrences, isNotEmpty);
      expect(occurrences.first.when.day, _now.day + 1);
    });

    test('includes today when the time is still ahead', () {
      final occurrences = builder.call(
        spaces: [
          _source(
            settings: const ReminderSettings(
              enabled: true,
              hour: 20,
              minute: 0,
              daysOfWeek: ReminderSettings.wednesdayBit,
            ),
          ),
        ],
        now: _now,
      );

      expect(occurrences.first.when.day, _now.day);
      expect(occurrences.first.when.hour, 20);
    });

    test('honours the weekday mask', () {
      // Only Wednesday and Saturday.
      const mask = ReminderSettings.wednesdayBit | ReminderSettings.saturdayBit;

      final occurrences = builder.call(
        spaces: [
          _source(
            settings: ReminderSettings(
              enabled: true,
              hour: 20,
              daysOfWeek: mask,
            ),
          ),
        ],
        now: _now,
        horizonDays: 7,
      );

      expect(occurrences, hasLength(2));
      for (final occurrence in occurrences) {
        expect(
          occurrence.when.weekday == DateTime.wednesday ||
              occurrence.when.weekday == DateTime.saturday,
          isTrue,
        );
      }
    });

    test('a disabled reminder produces nothing', () {
      final occurrences = builder.call(
        spaces: [_source(settings: const ReminderSettings())],
        now: _now,
      );

      expect(occurrences, isEmpty);
    });

    test('counts everything due on or before the reminder day', () {
      // House 1 has a one-day interval, so a card reviewed yesterday is due
      // today. House 3 has a four-day interval, putting the second card four
      // days out.
      final occurrences = builder.call(
        spaces: [
          _source(
            cards: [
              _card(id: 'a', box: 1, lastReviewed: addDays(_now, -1)),
              _card(id: 'b', box: 3, lastReviewed: _now),
            ],
          ),
        ],
        now: _now,
      );

      final today = occurrences.firstWhere((item) => item.when.day == _now.day);
      final later =
          occurrences.firstWhere((item) => item.when.day == _now.day + 4);

      expect(today.dueCount, 1);
      expect(later.dueCount, 2);
    });

    test('graduated cards never count as waiting', () {
      final occurrences = builder.call(
        spaces: [
          _source(cards: [_card(id: 'a', box: 6)]),
        ],
        now: _now,
      );

      expect(occurrences.every((item) => item.dueCount == 0), isTrue);
    });

    test('carries the space name and the show-count preference', () {
      final occurrences = builder.call(
        spaces: [
          _source(
            spaceName: 'Turkish',
            settings: const ReminderSettings(
              enabled: true,
              hour: 20,
              showDueCount: false,
            ),
          ),
        ],
        now: _now,
      );

      expect(occurrences.first.spaceName, 'Turkish');
      expect(occurrences.first.showDueCount, isFalse);
    });

    test('gives each space a non-overlapping id block', () {
      final occurrences = builder.call(
        spaces: [
          _source(spaceId: 'space-a'),
          _source(spaceId: 'space-b'),
          _source(spaceId: 'space-c'),
        ],
        now: _now,
      );

      final ids = occurrences.map((item) => item.notificationId).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.every((id) => id > 0), isTrue);
    });

    test('each space keeps the same ids whether or not others exist', () {
      // The whole queue is cancelled and rebuilt on every sync, so ids only
      // have to be unique inside one batch. This pins that a space's ids do not
      // depend on how many other spaces happen to be scheduled.
      final alone = builder.call(
        spaces: [_source(spaceId: 'space-b')],
        now: _now,
      );
      final crowded = builder.call(
        spaces: [
          _source(spaceId: 'space-a'),
          _source(spaceId: 'space-b'),
        ],
        now: _now,
      );

      final crowdedIds = crowded
          .map((item) => item.notificationId)
          .toSet();
      expect(alone.map((item) => item.notificationId).toSet().length,
          alone.length);
      expect(crowdedIds.length, crowded.length);
    });

    test('stays inside the planning horizon', () {
      final occurrences = builder.call(
        spaces: [_source()],
        now: _now,
      );

      final furthest = occurrences
          .map((item) => item.when.difference(_now).inDays)
          .reduce((a, b) => a > b ? a : b);
      expect(furthest, lessThanOrEqualTo(BuildReminderSchedule.horizonDays - 1));
    });
  });

  group('reminder settings persistence', () {
    late SpaceSettingsStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = SpaceSettingsStore(await SharedPreferences.getInstance());
    });

    test('a space with no stored reminder gets sensible defaults', () async {
      final settings = await store.load('space-1');

      expect(settings.reminder.enabled, isFalse);
      expect(settings.reminder.daysOfWeek, ReminderSettings.allDays);
    });

    test('a saved reminder survives a reload', () async {
      const reminder = ReminderSettings(
        enabled: true,
        hour: 18,
        minute: 45,
        daysOfWeek: ReminderSettings.saturdayBit,
        showDueCount: false,
      );

      await store.save(
        'space-1',
        const SpaceSettingsData().copyWith(reminder: reminder),
      );

      expect((await store.load('space-1')).reminder, reminder);
    });

    test('reminders are kept per space', () async {
      await store.save(
        'space-1',
        const SpaceSettingsData().copyWith(
          reminder: ReminderSettings(enabled: true, hour: 8),
        ),
      );
      await store.save(
        'space-2',
        const SpaceSettingsData().copyWith(
          reminder: ReminderSettings(enabled: true, hour: 21),
        ),
      );

      expect((await store.load('space-1')).reminder.hour, 8);
      expect((await store.load('space-2')).reminder.hour, 21);
    });
  });
}