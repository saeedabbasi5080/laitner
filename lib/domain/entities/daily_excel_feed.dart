import 'package:equatable/equatable.dart';

/// One automatic daily card feed: a deck, the library files that feed it, and
/// how many cards a day may enter it.
///
/// A space holds a list of these, one per deck, so a learner can feed a course
/// into one deck and their own files into another, each at its own pace. A
/// space used to hold exactly one; [listFromSpaceJson] reads that older shape
/// as a list of one.
///
/// Modelled on Anki's "new cards per day" limit: a file can be left with far
/// more rows than the user wants to see at once, so a daily allowance decides
/// how much of it enters a deck on any given day. Everything else in the file
/// stays queued in the Excel library and is released a chunk at a time.
class DailyExcelFeedSettings extends Equatable {
  const DailyExcelFeedSettings({
    this.id = '',
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

  /// Tells the feeds of one space apart. Empty for the feed carried over from
  /// the one-feed-per-space days; new feeds get a generated id.
  final String id;

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
    String? id,
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
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      deckId: clearDeckId ? null : (deckId ?? this.deckId),
      importIds: importIds ?? this.importIds,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      lastRunDay: clearLastRun ? null : (lastRunDay ?? this.lastRunDay),
      lastRunAdded: clearLastRun ? 0 : (lastRunAdded ?? this.lastRunAdded),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
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
      id: json['id'] is String ? json['id'] as String : '',
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

  /// The feeds stored in a space's settings blob.
  ///
  /// `dailyExcelFeeds` is the list. Without it, the older single
  /// `dailyExcelFeed` is read as a list of one, if it was ever set up, so an
  /// update keeps the feed a learner already had running.
  static List<DailyExcelFeedSettings> listFromSpaceJson(Map<String, dynamic> json) {
    final list = json['dailyExcelFeeds'];
    if (list is List) {
      return [
        for (final item in list)
          if (item is Map<String, dynamic>) DailyExcelFeedSettings.fromJson(item),
      ];
    }
    final legacy = json['dailyExcelFeed'];
    if (legacy is! Map<String, dynamic>) return const [];
    final feed = DailyExcelFeedSettings.fromJson(legacy);
    final used = feed.enabled || feed.deckId != null || feed.importIds.isNotEmpty;
    return used ? [feed] : const [];
  }

  @override
  List<Object?> get props => [
        id,
        enabled,
        deckId,
        importIds,
        dailyLimit,
        lastRunDay,
        lastRunAdded,
      ];
}