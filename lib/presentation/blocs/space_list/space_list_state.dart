import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/learning_space.dart';

class SpaceSummary extends Equatable {
  const SpaceSummary({
    required this.space,
    required this.deckCount,
    required this.totalCards,
    required this.dueCards,
  });

  final LearningSpace space;
  final int deckCount;
  final int totalCards;
  final int dueCards;

  @override
  List<Object?> get props => [space, deckCount, totalCards, dueCards];
}

enum SpaceListStatus { initial, loading, loaded, error }

class SpaceListState extends Equatable {
  const SpaceListState({
    this.status = SpaceListStatus.initial,
    this.summaries = const [],
    this.canAddSpace = true,
    this.errorMessage,
  });

  final SpaceListStatus status;
  final List<SpaceSummary> summaries;
  final bool canAddSpace;
  final String? errorMessage;

  SpaceListState copyWith({
    SpaceListStatus? status,
    List<SpaceSummary>? summaries,
    bool? canAddSpace,
    String? errorMessage,
  }) {
    return SpaceListState(
      status: status ?? this.status,
      summaries: summaries ?? this.summaries,
      canAddSpace: canAddSpace ?? this.canAddSpace,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summaries, canAddSpace, errorMessage];
}
