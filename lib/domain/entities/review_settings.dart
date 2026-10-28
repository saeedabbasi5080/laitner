import 'package:equatable/equatable.dart';

/// What happens to a card when the user answers "I don't know".
///
/// Anki steps the card back one house rather than dumping it at the start,
/// which keeps review load proportional to how much was actually forgotten.
/// The reset behaviour is still offered for users who prefer the harder
/// schedule.
enum DontKnowBehaviour {
  /// Back to the first house. The original behaviour of this app.
  resetToFirst,

  /// Down one house from where it was, never below house 1.
  stepBack;

  bool get goesToFirstHouse => this == DontKnowBehaviour.resetToFirst;

  String get name => switch (this) {
        DontKnowBehaviour.resetToFirst => 'resetToFirst',
        DontKnowBehaviour.stepBack => 'stepBack',
      };

  static DontKnowBehaviour fromName(String? name) => switch (name) {
        'stepBack' => DontKnowBehaviour.stepBack,
        _ => DontKnowBehaviour.resetToFirst,
      };
}

/// Per-space review preferences that sit alongside the Leitner layout.
class ReviewSettings extends Equatable {
  const ReviewSettings({this.dontKnowBehaviour = defaultBehaviour});

  static const defaultBehaviour = DontKnowBehaviour.resetToFirst;

  final DontKnowBehaviour dontKnowBehaviour;

  ReviewSettings copyWith({DontKnowBehaviour? dontKnowBehaviour}) {
    return ReviewSettings(
      dontKnowBehaviour: dontKnowBehaviour ?? this.dontKnowBehaviour,
    );
  }

  Map<String, dynamic> toJson() => {'dontKnowBehaviour': dontKnowBehaviour.name};

  factory ReviewSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReviewSettings();
    return ReviewSettings(
      dontKnowBehaviour: DontKnowBehaviour.fromName(
        json['dontKnowBehaviour'] as String?,
      ),
    );
  }

  @override
  List<Object> get props => [dontKnowBehaviour];
}