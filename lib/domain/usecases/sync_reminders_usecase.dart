import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/notifications/notification_service.dart';
import 'package:recall/data/datasources/local_data_source.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/learning_space.dart';
import 'package:recall/domain/usecases/build_reminder_schedule.dart';

/// Rebuilds the operating system's notification queue from the spaces' current
/// settings and due cards.
///
/// Deliberately recomputes from scratch every time it runs: reminder bodies
/// carry the number of waiting cards, so any review or settings change makes
/// the queued text stale. Callers should invoke it when the app is resumed,
/// after a study session, and whenever a space's reminder settings change.
class SyncRemindersUseCase {
  const SyncRemindersUseCase({
    required this.localDataSource,
    required this.spaceSettingsStore,
    required this.notificationService,
    this.scheduleBuilder = const BuildReminderSchedule(),
  });

  final LocalDataSource localDataSource;
  final SpaceSettingsStore spaceSettingsStore;
  final NotificationService notificationService;
  final BuildReminderSchedule scheduleBuilder;

  Future<void> call({DateTime? now}) async {
    if (!notificationService.isSupported) return;

    final timestamp = now ?? DateTime.now();

    // The whole card table is read once. Reading it per space made the cost
    // scale with the number of spaces, which is what made enabling a reminder
    // feel like the app had hung.
    final allCards = await localDataSource.getAllCards();

    final spaces = await localDataSource.getAllSpaces();
    final sources = <ReminderSource>[];

    for (final space in spaces) {
      final settings = await spaceSettingsStore.load(space.id);
      if (!settings.reminder.enabled) continue;

      sources.add(
        ReminderSource(
          spaceId: space.id,
          spaceName: space.name,
          settings: settings.reminder,
          cards: await _cardsFor(space, allCards),
          boxes: settings.leitnerBoxes,
        ),
      );
    }

    final occurrences = scheduleBuilder.call(
      spaces: sources,
      now: timestamp,
    );

    if (occurrences.isEmpty) {
      await notificationService.clearAll();
      return;
    }

    await notificationService.replaceAll([
      for (final occurrence in occurrences)
        ScheduledReminder(
          id: occurrence.notificationId,
          title: AppStrings.reminderTitle(occurrence.spaceName),
          body: _body(occurrence),
          when: occurrence.when,
          payload: occurrence.spaceId,
        ),
    ]);
  }

  Future<List<Flashcard>> _cardsFor(
    LearningSpace space,
    List<Flashcard> allCards,
  ) async {
    final decks = await localDataSource.getDecksBySpaceId(space.id);
    if (decks.isEmpty) return const [];

    final deckIds = decks.map((deck) => deck.id).toSet();
    return allCards.where((card) => deckIds.contains(card.deckId)).toList();
  }

  String _body(ReminderOccurrence occurrence) {
    if (!occurrence.showDueCount) return AppStrings.reminderBodyGeneric;

    return occurrence.dueCount == 0
        ? AppStrings.reminderBodyEmpty
        : AppStrings.reminderBodyCount(occurrence.dueCount);
  }
}