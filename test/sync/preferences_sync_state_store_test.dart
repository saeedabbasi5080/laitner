import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/preferences_sync_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  PreferencesSyncStateStore store() => PreferencesSyncStateStore(prefs: prefs);

  group('the watermark', () {
    test('is absent before anything has been uploaded', () async {
      expect(await store().readReviewLogWatermark(), isNull);
    });

    test('comes back as what was written', () async {
      final when = DateTime(2026, 1, 2, 10, 30, 15, 123);
      await store().writeReviewLogWatermark(when);

      expect(await store().readReviewLogWatermark(), when);
    });

    test('survives a new store over the same preferences', () async {
      final when = DateTime(2026, 3, 4, 5);
      await store().writeReviewLogWatermark(when);

      expect(await store().readReviewLogWatermark(), when);
    });

    test('reads as absent when the stored value cannot be read', () async {
      // A watermark this app cannot parse means "nothing has been uploaded", which
      // resends the boundary entry. That costs one row; treating it as a real
      // watermark could skip entries the server never received.
      SharedPreferences.setMockInitialValues({
        PreferencesSyncStateStore.watermarkKey: 'not a date at all',
      });
      final reopened = await SharedPreferences.getInstance();

      expect(
        await PreferencesSyncStateStore(prefs: reopened).readReviewLogWatermark(),
        isNull,
      );
    });

    test('reads as absent when the stored value is blank', () async {
      SharedPreferences.setMockInitialValues({
        PreferencesSyncStateStore.watermarkKey: '',
      });
      final reopened = await SharedPreferences.getInstance();

      expect(
        await PreferencesSyncStateStore(prefs: reopened).readReviewLogWatermark(),
        isNull,
      );
    });
  });

  group('clear', () {
    test('forgets the watermark', () async {
      await store().writeReviewLogWatermark(DateTime(2026, 1, 1));
      await store().clear();

      expect(await store().readReviewLogWatermark(), isNull);
    });

    test('is safe when there is nothing to forget', () async {
      await store().clear();

      expect(await store().readReviewLogWatermark(), isNull);
    });
  });

  group('what it writes', () {
    test('is wall clock, matching the history it will be compared against',
        () async {
      // Written as UTC while `reviewedAt` stayed local would be the thing that
      // broke the comparison: an entry recorded just after the watermark could
      // read as before it, and would never be uploaded.
      final when = DateTime(2026, 1, 2, 10, 30, 15, 123);
      await store().writeReviewLogWatermark(when);

      final raw = prefs.getString(PreferencesSyncStateStore.watermarkKey);

      expect(raw, when.toIso8601String());
      expect(raw, isNot(contains('Z')));
    });
  });

  group('when the last sync was', () {
    test('is absent before there has been one', () async {
      expect(await store().readLastSyncedAt(), isNull);
    });

    test('comes back as what was written', () async {
      final when = DateTime(2026, 5, 6, 7, 8, 9);

      await store().writeLastSyncedAt(when);

      expect(await store().readLastSyncedAt(), when);
    });

    test('survives a new store over the same preferences', () async {
      final when = DateTime(2026, 5, 6, 7);
      await store().writeLastSyncedAt(when);

      expect(await PreferencesSyncStateStore(prefs: prefs).readLastSyncedAt(), when);
    });

    test('is forgotten on clear, along with the watermark', () async {
      // Both belong to an account. Leaving the watermark behind would make the next
      // account's first push skip entries it had never sent.
      await store().writeReviewLogWatermark(DateTime(2026, 1, 1));
      await store().writeLastSyncedAt(DateTime(2026, 1, 2));

      await store().clear();

      expect(await store().readLastSyncedAt(), isNull);
      expect(await store().readReviewLogWatermark(), isNull);
    });
  });
}
