import 'package:equatable/equatable.dart';
import 'package:recall/core/constants/leitner_constants.dart';

/// Per-space Leitner house layout. Boxes 1–5 are always on; 6–8 are optional.
class LeitnerBoxConfig extends Equatable {
  const LeitnerBoxConfig({
    this.box6Enabled = false,
    this.box7Enabled = false,
    this.box8Enabled = false,
    this.box6Days = defaultBox6Days,
    this.box7Days = defaultBox7Days,
    this.box8Days = defaultBox8Days,
  });

  static const classic = LeitnerBoxConfig();

  final bool box6Enabled;
  final bool box7Enabled;
  final bool box8Enabled;
  final int box6Days;
  final int box7Days;
  final int box8Days;

  bool get isClassic => maxBox == classicMaxBox;

  int get maxBox {
    if (box6Enabled && box7Enabled && box8Enabled) return 8;
    if (box6Enabled && box7Enabled) return 7;
    if (box6Enabled) return 6;
    return classicMaxBox;
  }

  int get learnedBox => maxBox + 1;

  int intervalDays(int box) {
    if (box <= 0) return 0;
    if (box <= classicMaxBox) {
      return boxIntervalsDays[box.clamp(1, classicMaxBox)];
    }
    return switch (box) {
      6 => box6Days.clamp(extraBoxMinDays, extraBoxMaxDays),
      7 => box7Days.clamp(extraBoxMinDays, extraBoxMaxDays),
      8 => box8Days.clamp(extraBoxMinDays, extraBoxMaxDays),
      _ => boxIntervalsDays[classicMaxBox],
    };
  }

  bool isLearnedBox(int box) => box > maxBox;

  LeitnerBoxConfig copyWith({
    bool? box6Enabled,
    bool? box7Enabled,
    bool? box8Enabled,
    int? box6Days,
    int? box7Days,
    int? box8Days,
  }) {
    var next6 = box6Enabled ?? this.box6Enabled;
    var next7 = box7Enabled ?? this.box7Enabled;
    var next8 = box8Enabled ?? this.box8Enabled;
    if (!next6) {
      next7 = false;
      next8 = false;
    } else if (!next7) {
      next8 = false;
    } else if (next8) {
      next6 = true;
      next7 = true;
    }
    if (next7) next6 = true;
    if (next8) {
      next6 = true;
      next7 = true;
    }

    return LeitnerBoxConfig(
      box6Enabled: next6,
      box7Enabled: next7,
      box8Enabled: next8,
      box6Days: (box6Days ?? this.box6Days).clamp(
        extraBoxMinDays,
        extraBoxMaxDays,
      ),
      box7Days: (box7Days ?? this.box7Days).clamp(
        extraBoxMinDays,
        extraBoxMaxDays,
      ),
      box8Days: (box8Days ?? this.box8Days).clamp(
        extraBoxMinDays,
        extraBoxMaxDays,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'box6Enabled': box6Enabled,
        'box7Enabled': box7Enabled,
        'box8Enabled': box8Enabled,
        'box6Days': box6Days,
        'box7Days': box7Days,
        'box8Days': box8Days,
      };

  factory LeitnerBoxConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return classic;
    return LeitnerBoxConfig(
      box6Enabled: json['box6Enabled'] as bool? ?? false,
      box7Enabled: json['box7Enabled'] as bool? ?? false,
      box8Enabled: json['box8Enabled'] as bool? ?? false,
      box6Days: json['box6Days'] as int? ?? defaultBox6Days,
      box7Days: json['box7Days'] as int? ?? defaultBox7Days,
      box8Days: json['box8Days'] as int? ?? defaultBox8Days,
    ).copyWith();
  }

  @override
  List<Object?> get props => [
        box6Enabled,
        box7Enabled,
        box8Enabled,
        box6Days,
        box7Days,
        box8Days,
      ];
}
