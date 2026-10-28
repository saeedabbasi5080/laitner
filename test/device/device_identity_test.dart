import 'package:flutter_test/flutter_test.dart';
import 'package:recall/data/datasources/device_identity.dart';
import 'package:recall/domain/services/id_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts what it was asked for, so "minted once" can be asserted rather than
/// assumed.
class _CountingIds implements IdGenerator {
  int calls = 0;

  @override
  String generateId() {
    calls++;
    return 'device-${calls.toString().padLeft(4, '0')}';
  }
}

class _FixedLabel implements DeviceLabelSource {
  _FixedLabel(this.value);

  final String? value;

  @override
  Future<String?> label() async => value;
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  StoredDeviceIdentity identity({
    IdGenerator? ids,
    DeviceLabelSource? labels,
  }) {
    return StoredDeviceIdentity(
      preferences: prefs,
      ids: ids ?? _CountingIds(),
      labels: labels ?? _FixedLabel('گوشی'),
    );
  }

  group('the device id', () {
    test('is minted on first use', () async {
      final ids = _CountingIds();

      final device = await identity(ids: ids).resolve();

      expect(device.id, isNotEmpty);
      expect(ids.calls, 1);
    });

    test('is the same the second time', () async {
      final ids = _CountingIds();
      final which = identity(ids: ids);

      final first = await which.resolve();
      final second = await which.resolve();

      expect(second.id, first.id);
      expect(ids.calls, 1);
    });

    test('survives a new identity over the same storage', () async {
      // The id is what a user removes from the device list. One that changed on
      // every launch could never be removed.
      final first = await identity(ids: _CountingIds()).resolve();
      final second = await identity(ids: _CountingIds()).resolve();

      expect(second.id, first.id);
    });

    test('is not minted again when storage already holds one', () async {
      SharedPreferences.setMockInitialValues({
        StoredDeviceIdentity.storageKey: 'stored-device',
      });
      final reopened = await SharedPreferences.getInstance();
      final ids = _CountingIds();

      final device = await StoredDeviceIdentity(
        preferences: reopened,
        ids: ids,
        labels: _FixedLabel(null),
      ).resolve();

      expect(device.id, 'stored-device');
      expect(ids.calls, 0);
    });

    test('ignores a stored value that is blank', () async {
      SharedPreferences.setMockInitialValues({
        StoredDeviceIdentity.storageKey: '   ',
      });
      final reopened = await SharedPreferences.getInstance();
      final ids = _CountingIds();

      final device = await StoredDeviceIdentity(
        preferences: reopened,
        ids: ids,
        labels: _FixedLabel(null),
      ).resolve();

      expect(ids.calls, 1);
      expect(device.id, isNot('   '));
    });
  });

  group('the label', () {
    test('is passed through', () async {
      expect((await identity(labels: _FixedLabel('گوشی سارا')).resolve()).label,
          'گوشی سارا');
    });

    test('is null when the platform will not say', () async {
      expect((await identity(labels: _FixedLabel(null)).resolve()).label, isNull);
    });
  });

  group('turning a brand and model into a name', () {
    test('joins them', () {
      expect(deviceLabelFrom('Samsung', 'SM-G991B'), 'Samsung SM-G991B');
    });

    test('does not repeat a brand already in the model', () {
      // What Android usually reports. Without this the list reads "Samsung
      // Samsung SM-G991B".
      expect(deviceLabelFrom('Samsung', 'Samsung SM-G991B'), 'Samsung SM-G991B');
    });

    test('compares the brand case-insensitively', () {
      expect(deviceLabelFrom('samsung', 'Samsung SM-G991B'), 'Samsung SM-G991B');
    });

    test('uses the model alone when there is no brand', () {
      expect(deviceLabelFrom('', 'Pixel 8'), 'Pixel 8');
    });

    test('falls back to the brand alone when there is no model', () {
      expect(deviceLabelFrom('Samsung', ''), 'Samsung');
    });

    test('is null when neither is given', () {
      expect(deviceLabelFrom('', ''), isNull);
      expect(deviceLabelFrom('   ', '  '), isNull);
    });

    test('ignores surrounding whitespace', () {
      expect(deviceLabelFrom('  Samsung  ', '  SM-G991B  '), 'Samsung SM-G991B');
    });
  });
}
