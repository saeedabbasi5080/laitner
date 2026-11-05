import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// App lock: before one of the apps the user chose opens, a few flashcards.
///
/// Android only. The native side (android/…/gate/) watches which app comes to
/// the front and decides when to step in; this side holds the settings, asks
/// the cards, and tells the native side how many cards are due today — when
/// none are, nothing is locked.

enum AppGateMode {
  /// A few cards each time a chosen app is opened, while any are due today.
  perOpen,

  /// Every card due today before any chosen app opens.
  allDue,
}

@immutable
class AppGateConfig {
  const AppGateConfig({
    this.enabled = false,
    this.packages = const {},
    this.mode = AppGateMode.perOpen,
    this.cardsPerOpen = 2,
    this.graceEnabled = false,
    this.graceMinutes = 5,
    this.allSpaces = true,
    this.spaceIds = const {},
  });

  final bool enabled;

  /// The apps to lock, by package name.
  final Set<String> packages;
  final AppGateMode mode;
  final int cardsPerOpen;

  /// Whether reopening an app soon after unlocking it is free.
  final bool graceEnabled;
  final int graceMinutes;

  /// Cards come from every space — including ones created later — or only
  /// from [spaceIds].
  final bool allSpaces;
  final Set<String> spaceIds;

  static const minCards = 1;
  static const maxCards = 10;
  static const minGrace = 1;
  static const maxGrace = 60;

  AppGateConfig copyWith({
    bool? enabled,
    Set<String>? packages,
    AppGateMode? mode,
    int? cardsPerOpen,
    bool? graceEnabled,
    int? graceMinutes,
    bool? allSpaces,
    Set<String>? spaceIds,
  }) => AppGateConfig(
    enabled: enabled ?? this.enabled,
    packages: packages ?? this.packages,
    mode: mode ?? this.mode,
    cardsPerOpen: (cardsPerOpen ?? this.cardsPerOpen).clamp(minCards, maxCards),
    graceEnabled: graceEnabled ?? this.graceEnabled,
    graceMinutes: (graceMinutes ?? this.graceMinutes).clamp(minGrace, maxGrace),
    allSpaces: allSpaces ?? this.allSpaces,
    spaceIds: spaceIds ?? this.spaceIds,
  );

  /// The keys `enabled`, `packages`, `graceEnabled` and `graceMinutes` are read
  /// by the native side too; renaming one breaks the lock silently.
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'packages': packages.toList()..sort(),
    'mode': mode.name,
    'cardsPerOpen': cardsPerOpen,
    'graceEnabled': graceEnabled,
    'graceMinutes': graceMinutes,
    'allSpaces': allSpaces,
    'spaceIds': spaceIds.toList()..sort(),
  };

  factory AppGateConfig.fromJson(Map<String, dynamic> json) {
    // The first version chose one space, as `spaceId`.
    final legacy = json['spaceId'] as String?;
    final ids = {
      for (final id in (json['spaceIds'] as List? ?? const [])) id as String,
      ?legacy,
    };
    return AppGateConfig(
      enabled: json['enabled'] as bool? ?? false,
      packages: {
        for (final p in (json['packages'] as List? ?? const [])) p as String,
      },
      mode: AppGateMode.values.asNameMap()[json['mode']] ?? AppGateMode.perOpen,
      cardsPerOpen: (json['cardsPerOpen'] as int? ?? 2).clamp(
        minCards,
        maxCards,
      ),
      graceEnabled: json['graceEnabled'] as bool? ?? false,
      graceMinutes: (json['graceMinutes'] as int? ?? 5).clamp(
        minGrace,
        maxGrace,
      ),
      allSpaces: json['allSpaces'] as bool? ?? ids.isEmpty,
      spaceIds: ids,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppGateConfig &&
      jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

class InstalledApp {
  const InstalledApp({required this.package, required this.label, this.icon});

  final String package;
  final String label;
  final Uint8List? icon;
}

class AppGateStatus {
  const AppGateStatus({required this.accessibility, required this.overlay});

  /// The accessibility service is switched on in the phone's settings.
  final bool accessibility;

  /// "Display over other apps" is allowed.
  final bool overlay;

  bool get ready => accessibility && overlay;
}

/// The gate's target app, as the gate screen is told it.
class GateTarget {
  const GateTarget({required this.package, required this.label});

  final String package;
  final String label;
}

/// The native side. An interface so screens and logic are testable without it.
abstract interface class AppGatePlatform {
  bool get supported;
  Future<AppGateConfig> loadConfig();
  Future<void> saveConfig(AppGateConfig config);
  Future<void> setDueState(int count, DateTime day);
  Future<AppGateStatus> status();
  Future<void> openAccessibilitySettings();
  Future<void> openOverlaySettings();

  /// This app's info page, where Android 13+ hides "Allow restricted settings".
  Future<void> openAppInfo();
  Future<List<InstalledApp>> listApps();

  // The gate screen.
  Future<GateTarget?> target();
  Future<void> unlockAndOpen(String package);
  Future<void> goHome();

  /// Called when another chosen app was opened while the gate was showing.
  void onTargetChanged(void Function() callback);
}

class MethodChannelAppGate implements AppGatePlatform {
  MethodChannelAppGate([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('recall/app_gate');

  final MethodChannel _channel;

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<AppGateConfig> loadConfig() async {
    if (!supported) return const AppGateConfig();
    final raw = await _channel.invokeMethod<String>('getConfig');
    try {
      return AppGateConfig.fromJson(
        jsonDecode(raw ?? '{}') as Map<String, dynamic>,
      );
    } on FormatException {
      return const AppGateConfig();
    }
  }

  @override
  Future<void> saveConfig(AppGateConfig config) async {
    if (!supported) return;
    await _channel.invokeMethod('saveConfig', jsonEncode(config.toJson()));
  }

  @override
  Future<void> setDueState(int count, DateTime day) async {
    if (!supported) return;
    await _channel.invokeMethod('setDueState', {
      'count': count,
      'day': gateDayKey(day),
    });
  }

  @override
  Future<AppGateStatus> status() async {
    if (!supported) {
      return const AppGateStatus(accessibility: false, overlay: false);
    }
    final map = await _channel.invokeMapMethod<String, dynamic>('status');
    return AppGateStatus(
      accessibility: map?['accessibility'] as bool? ?? false,
      overlay: map?['overlay'] as bool? ?? false,
    );
  }

  @override
  Future<void> openAccessibilitySettings() =>
      _channel.invokeMethod('openAccessibilitySettings');

  @override
  Future<void> openOverlaySettings() =>
      _channel.invokeMethod('openOverlaySettings');

  @override
  Future<void> openAppInfo() => _channel.invokeMethod('openAppInfo');

  @override
  Future<List<InstalledApp>> listApps() async {
    if (!supported) return const [];
    final list = await _channel.invokeListMethod<Map>('listApps') ?? const [];
    return [
      for (final app in list)
        InstalledApp(
          package: app['package'] as String,
          label: app['label'] as String,
          icon: app['icon'] as Uint8List?,
        ),
    ];
  }

  @override
  Future<GateTarget?> target() async {
    final map = await _channel.invokeMapMethod<String, dynamic>('getTarget');
    if (map == null) return null;
    return GateTarget(
      package: map['package'] as String,
      label: map['label'] as String? ?? map['package'] as String,
    );
  }

  @override
  Future<void> unlockAndOpen(String package) =>
      _channel.invokeMethod('unlockAndOpen', package);

  @override
  Future<void> goHome() => _channel.invokeMethod('goHome');

  @override
  void onTargetChanged(void Function() callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'targetChanged') callback();
    });
  }
}

/// The day key the native side compares against: `yyyy-MM-dd`, local.
String gateDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';
