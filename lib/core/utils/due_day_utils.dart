import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/leitner_box_config.dart';
import 'package:recall/domain/usecases/leitner_logic.dart';

class DueDayBucket {
  const DueDayBucket({required this.cards, this.day, this.isOverdue = false});

  final DateTime? day;
  final bool isOverdue;
  final List<Flashcard> cards;

  int get count => cards.length;
}

DateTime calendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Time until just after the next local midnight, for day-boundary UI refresh.
Duration untilNextLocalDay([DateTime? now]) {
  final current = now ?? DateTime.now();
  final nextDay = DateTime(current.year, current.month, current.day + 1);
  return nextDay.difference(current) + const Duration(seconds: 1);
}

DateTime cardDueDay(
  Flashcard card, {
  DateTime? now,
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  return calendarDay(nextReviewDate(card, boxes: boxes));
}

List<DueDayBucket> groupCardsByDueDay(
  List<Flashcard> cards, {
  DateTime? now,
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  final today = calendarDay(now ?? DateTime.now());
  final overdue = <Flashcard>[];
  final byDay = <DateTime, List<Flashcard>>{};

  for (final card in cards) {
    final dueDay = cardDueDay(card, now: today, boxes: boxes);
    if (dueDay.isBefore(today)) {
      overdue.add(card);
    } else {
      byDay.putIfAbsent(dueDay, () => []).add(card);
    }
  }

  final sortedDays = byDay.keys.toList()..sort();
  return [
    if (overdue.isNotEmpty) DueDayBucket(cards: overdue, isOverdue: true),
    for (final day in sortedDays) DueDayBucket(day: day, cards: byDay[day]!),
  ];
}

List<Flashcard> filterCardsByDueDay(
  List<Flashcard> cards, {
  DateTime? dueDay,
  bool overdueOnly = false,
  DateTime? now,
  LeitnerBoxConfig boxes = LeitnerBoxConfig.classic,
}) {
  if (dueDay == null && !overdueOnly) return List.of(cards);

  final today = calendarDay(now ?? DateTime.now());
  if (overdueOnly) {
    return cards
        .where(
          (card) => cardDueDay(card, now: today, boxes: boxes).isBefore(today),
        )
        .toList();
  }

  final selectedDay = calendarDay(dueDay!);
  return cards
      .where((card) => cardDueDay(card, now: today, boxes: boxes) == selectedDay)
      .toList();
}

String dueDayLabel(DueDayBucket bucket, {DateTime? now}) {
  if (bucket.isOverdue) return 'معوق';

  final today = calendarDay(now ?? DateTime.now());
  final daysAway = bucket.day!.difference(today).inDays;
  return switch (daysAway) {
    0 => 'امروز',
    1 => 'فردا',
    2 => 'پس‌فردا',
    _ => '$daysAway روز دیگر',
  };
}
