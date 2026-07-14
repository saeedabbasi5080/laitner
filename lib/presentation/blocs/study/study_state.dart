part of 'study_cubit.dart';

enum StudyStatus { initial, loading, ready, error }

class StudyState extends Equatable {
  const StudyState({
    this.status = StudyStatus.initial,
    this.queue = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isAllDue = false,
    this.boxNumber,
    this.reversed = false,
    this.errorMessage,
  });

  final StudyStatus status;
  final List<Flashcard> queue;
  final int currentIndex;
  final bool isFlipped;
  final bool isAllDue;
  final int? boxNumber;
  final bool reversed;
  final String? errorMessage;

  bool get isFreeReview => boxNumber != null;

  Flashcard? get currentCard =>
      currentIndex < queue.length ? queue[currentIndex] : null;

  bool get isFinished =>
      status == StudyStatus.ready &&
      (queue.isEmpty || currentIndex >= queue.length);

  double get progress =>
      queue.isEmpty ? 0 : (currentIndex / queue.length).clamp(0.0, 1.0);

  StudyState copyWith({
    StudyStatus? status,
    List<Flashcard>? queue,
    int? currentIndex,
    bool? isFlipped,
    bool? isAllDue,
    int? boxNumber,
    bool? reversed,
    String? errorMessage,
  }) {
    return StudyState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isAllDue: isAllDue ?? this.isAllDue,
      boxNumber: boxNumber ?? this.boxNumber,
      reversed: reversed ?? this.reversed,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        queue,
        currentIndex,
        isFlipped,
        isAllDue,
        boxNumber,
        reversed,
        errorMessage,
      ];
}
