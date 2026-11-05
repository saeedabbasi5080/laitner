import 'package:shamsi_date/shamsi_date.dart';
import 'package:recall/core/utils/day_key.dart';

/// Persian (solar hijri) calendar helpers for the charts and day labels.
///
/// The app is Persian; its users read dates as `۱۴/۸`, not `5/11`, and their
/// week starts on Saturday.

/// `day/month` in the Persian calendar, e.g. `14/8` for 14 Aban.
String jalaliDayMonth(DateTime date) {
  final j = Jalali.fromDateTime(date);
  return '${j.day}/${j.month}';
}

/// `month/yy` in the Persian calendar, e.g. `8/05` for Aban 1405.
String jalaliMonthYear(DateTime date) {
  final j = Jalali.fromDateTime(date);
  return '${j.month}/${(j.year % 100).toString().padLeft(2, '0')}';
}

/// A running month number, so two dates are in the same Persian month exactly
/// when this is equal, and consecutive months differ by one.
int jalaliMonthIndex(DateTime date) {
  final j = Jalali.fromDateTime(date);
  return j.year * 12 + (j.month - 1);
}

/// The first day of the Persian month numbered [index] by [jalaliMonthIndex].
DateTime jalaliMonthStart(int index) =>
    Jalali(index ~/ 12, index % 12 + 1, 1).toDateTime();

/// Days since the Saturday that starts the week containing [dayNumber]:
/// 0 on Saturday, 6 on Friday.
int daysSinceSaturday(int dayNumber) =>
    // ISO weekday: Monday 1 … Saturday 6, Sunday 7.
    (weekdayOfDayNumber(dayNumber) + 1) % 7;
