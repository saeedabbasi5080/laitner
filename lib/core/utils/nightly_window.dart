/// The app's sync day: it starts at 03:00 local time, when the nightly sync runs.

/// The hour the nightly sync is due.
const int nightlySyncHour = 3;

/// The start of the sync day that [now] falls in: the latest 03:00 at or
/// before it.
///
/// A sync at or after this moment means today's sync is done; anything earlier
/// belongs to yesterday.
DateTime currentSyncDayStart(DateTime now) {
  final today = DateTime(now.year, now.month, now.day, nightlySyncHour);
  return now.isBefore(today)
      ? DateTime(now.year, now.month, now.day - 1, nightlySyncHour)
      : today;
}

/// How long from [now] until the next 03:00 on the local clock.
///
/// Exactly three is "tomorrow": the job that just ran at three must not schedule
/// itself for the same instant.
Duration untilNextNightlySync(DateTime now) =>
    untilNextDailyTime(now, hour: nightlySyncHour);

/// How long from [now] until the next [hour]:[minute] on the local clock;
/// exactly that time counts as tomorrow, as above.
Duration untilNextDailyTime(DateTime now, {required int hour, int minute = 0}) {
  var next = DateTime(now.year, now.month, now.day, hour, minute);
  if (!next.isAfter(now)) {
    next = DateTime(now.year, now.month, now.day + 1, hour, minute);
  }
  return next.difference(now);
}
