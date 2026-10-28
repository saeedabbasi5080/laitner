import 'package:equatable/equatable.dart';

/// Per-space configuration for the automatic daily card feed.
///
/// Modelled on Anki's "new cards per day" limit: a file can be left with far
/// more rows than the user wants to see at once, so a daily allowance decides
/// how much of it enters a deck on any given day. Everything else in the file
/// stays queued in the Excel library and is released a chunk at a time.
class DailyExcelFeedSettings extends Equatable {
  const DailyExcelFeedSettings({
    this.enabled = false,
    this.deckId,
    this.importIds = const [],
    this.dailyLimit = defaultDailyLimit,
    this.lastRunDay,
    this.lastRunAdded = 0,
  });

  /// 200 a day is roughly what a diligent learner can get through, and matches
  /// the ceiling Anki recommends for new cards.
  static const int defaultDailyLimit = 200;

  /// A limit of zero would silently stop the feed, so the smallest usable
  /// allowance is one card. The cap only exists to stop a runaway import.
  static const int minDailyLimit = 1;
  static const int maxDailyLimit = 5000;

  final bool enabled;

  /// The deck the feed adds to. Null until the user picks one.
  final String? deckId;

  /// The Excel library files that feed this deck, oldest first.
  final List<String> importIds;

  /// How many cards may enter the deck on a single day.
  final int dailyLimit;

  /// Day number of the last run, or null if it has never run.
  final int? lastRunDay;

  /// How many cards the last run actually added, for the status line.
  final int lastRunAdded;

  /// True when the feed has everything it needs to do anything.
  bool get isConfigured =>
      enabled &&
      deckId != null &&
      deckId!.isNotEmpty &&
      importIds.isNotEmpty &&
      dailyLimit > 0;

  /// True when the user turned it on but has not finished setting it up.
  bool get needsSetup => enabled && !isConfigured;

  int get effectiveDailyLimit => dailyLimit.clamp(
        minDailyLimit,
        maxDailyLimit,
      );

  DailyExcelFeedSettings copyWith({
    bool? enabled,
    String? deckId,
    List<String>? importIds,
    int? dailyLimit,
    int? lastRunDay,
    int? lastRunAdded,
    bool clearDeckId = false,
    bool clearLastRun = false,
  }) {
    return DailyExcelFeedSettings(
      enabled: enabled ?? this.enabled,
      deckId: clearDeckId ? null : (deckId ?? this.deckId),
      importIds: importIds ?? this.importIds,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      lastRunDay: clearLastRun ? null : (lastRunDay ?? this.lastRunDay),
      lastRunAdded: clearLastRun ? 0 : (lastRunAdded ?? this.lastRunAdded),
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'deckId': deckId,
        'importIds': importIds,
        'dailyLimit': dailyLimit,
        'lastRunDay': lastRunDay,
        'lastRunAdded': lastRunAdded,
      };

  factory DailyExcelFeedSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DailyExcelFeedSettings();

    // Each field is read defensively rather than cast: these blobs are written
    // by an older version of the app and edited by hand through backups, so a
    // surprising shape must degrade to the default instead of crashing the
    // space on every launch.
    final rawIds = json['importIds'];
    return DailyExcelFeedSettings(
      enabled: json['enabled'] == true,
      deckId: json['deckId'] is String ? json['deckId'] as String : null,
      importIds: rawIds is List
          ? rawIds
              .map((e) => e?.toString() ?? '')
              .where((e) => e.isNotEmpty)
              .toList()
          : const [],
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? defaultDailyLimit,
      lastRunDay: (json['lastRunDay'] as num?)?.toInt(),
      lastRunAdded: (json['lastRunAdded'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        enabled,
        deckId,
        importIds,
        dailyLimit,
        lastRunDay,
        lastRunAdded,
      ];
}