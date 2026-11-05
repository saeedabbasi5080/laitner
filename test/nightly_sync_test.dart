import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/utils/nightly_window.dart';

void main() {
  group('currentSyncDayStart', () {
    test('after three, it is three today', () {
      expect(currentSyncDayStart(DateTime(2026, 11, 3, 14)), DateTime(2026, 11, 3, 3));
    });

    test('at exactly three, a new day has started', () {
      expect(currentSyncDayStart(DateTime(2026, 11, 3, 3)), DateTime(2026, 11, 3, 3));
    });

    test('before three, it is still yesterday, across a month boundary', () {
      expect(currentSyncDayStart(DateTime(2026, 12, 1, 2, 59)), DateTime(2026, 11, 30, 3));
    });
  });

  group('untilNextNightlySync', () {
    test('before three, it is three today', () {
      final now = DateTime(2026, 11, 3, 1, 30);

      expect(now.add(untilNextNightlySync(now)), DateTime(2026, 11, 3, 3));
    });

    test('after three, it is three tomorrow', () {
      final now = DateTime(2026, 11, 3, 14);

      expect(now.add(untilNextNightlySync(now)), DateTime(2026, 11, 4, 3));
    });

    test('at exactly three, it is tomorrow, not now', () {
      // The job that just ran at three must not schedule itself for the same
      // instant and run again.
      final now = DateTime(2026, 11, 3, 3);

      expect(now.add(untilNextNightlySync(now)), DateTime(2026, 11, 4, 3));
    });

    test('crosses the end of a month and a year', () {
      final now = DateTime(2026, 12, 31, 23);

      expect(now.add(untilNextNightlySync(now)), DateTime(2027, 1, 1, 3));
    });

    test('is never negative or zero', () {
      for (var hour = 0; hour < 24; hour++) {
        final wait = untilNextNightlySync(DateTime(2026, 6, 1, hour, 59, 59));
        expect(wait, greaterThan(Duration.zero));
        expect(wait, lessThanOrEqualTo(const Duration(hours: 24)));
      }
    });
  });
}
