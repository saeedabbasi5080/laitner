/// Single source of truth for calendar-day arithmetic.
///
/// Every part of the app schedules on *local* calendar days, so all day
/// bucketing must share one rule. Mixing `DateTime.utc(...)` with local
/// `DateTime(...)` for the same concept used to shift buckets by a day
/// whenever the device crossed a DST boundary, which desynced the forecast
/// chart from the due-day chips.
///
/// [dayNumber] is DST-safe even for UTC instants: it reads the already-resolved
/// local year/month/day fields and then uses UTC purely as a timezone-free
/// arithmetic base (leap days included), never as a wall clock.
library;

const int _msPerDay = 86400000;

DateTime _asLocal(DateTime value) => value.isUtc ? value.toLocal() : value;

/// Local midnight of the calendar day containing [value].
DateTime dayStart(DateTime value) {
  final local = _asLocal(value);
  return DateTime(local.year, local.month, local.day);
}

/// Days since the Unix epoch for the local calendar day containing [value].
int dayNumber(DateTime value) {
  final local = _asLocal(value);
  return DateTime.utc(local.year, local.month, local.day).millisecondsSinceEpoch ~/
      _msPerDay;
}

/// The local midnight [days] days after the day containing [value].
DateTime addDays(DateTime value, int days) {
  final local = _asLocal(value);
  return DateTime(local.year, local.month, local.day + days);
}

/// Inverse of [dayNumber]: the local midnight for a day number.
///
/// The UTC timestamp is only a device for recovering the year/month/day
/// triple. Adding a [Duration] instead would drift by an hour across DST and
/// could hand back 23:00 of the previous day.
DateTime dateFromDayNumber(int dayNumber) {
  final utc = DateTime.fromMillisecondsSinceEpoch(
    dayNumber * _msPerDay,
    isUtc: true,
  );
  return DateTime(utc.year, utc.month, utc.day);
}

/// Whole local calendar days from the day of [from] to the day of [to].
/// Negative when [to] is earlier than [from].
int daysBetween(DateTime from, DateTime to) => dayNumber(to) - dayNumber(from);

/// [DateTime.monday]..[DateTime.sunday] for a [dayNumber].
///
/// Day number 0 is 1970-01-01, a Thursday, hence the `+ 3` offset.
int weekdayOfDayNumber(int dayNumber) => (dayNumber + 3) % 7 + 1;

/// The local midnight [dayBoundary] before the day containing [value].
///
/// Mirrors Anki's "day starts at" preference (default 04:00). With a zero
/// boundary this is exactly [dayStart].
DateTime dayStartWithBoundary(DateTime value, Duration dayBoundary) {
  if (dayBoundary <= Duration.zero) return dayStart(value);
  return dayStart(_asLocal(value).subtract(dayBoundary));
}

/// The day that a timestamp belongs to, honouring a "day starts at" boundary.
int dayNumberWithBoundary(DateTime value, Duration dayBoundary) =>
    dayNumber(dayStartWithBoundary(value, dayBoundary));