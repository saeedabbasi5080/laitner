import 'package:recall/core/app_gate/app_gate.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/get_all_due_cards_usecase.dart';
import 'package:recall/domain/usecases/get_spaces_usecase.dart';

/// A card due today, with the space it belongs to: answering it is reviewed
/// with that space's own houses and review settings.
typedef GateCard = ({Flashcard card, String spaceId});

/// Today's due cards for the app lock, from every space or the chosen ones.
///
/// "All spaces" is resolved here, each time, rather than stored as a list, so
/// a space created later is included without anyone revisiting the setting.
class GetAppGateCardsUseCase {
  const GetAppGateCardsUseCase({
    required GetSpacesUseCase getSpaces,
    required GetAllDueCardsUseCase getAllDueCards,
    required SpaceSettingsStore spaceSettingsStore,
  }) : _getSpaces = getSpaces,
       _getAllDueCards = getAllDueCards,
       _spaceSettings = spaceSettingsStore;

  final GetSpacesUseCase _getSpaces;
  final GetAllDueCardsUseCase _getAllDueCards;
  final SpaceSettingsStore _spaceSettings;

  Future<List<GateCard>> call(AppGateConfig config, {DateTime? now}) async {
    final spaces = await _getSpaces();
    final ids = [
      for (final space in spaces)
        if (config.allSpaces || config.spaceIds.contains(space.id)) space.id,
    ];

    final cards = <GateCard>[];
    for (final spaceId in ids) {
      final boxes = (await _spaceSettings.load(spaceId)).leitnerBoxes;
      final due = await _getAllDueCards(spaceId, now: now, boxes: boxes);
      cards.addAll([for (final card in due) (card: card, spaceId: spaceId)]);
    }
    return cards;
  }
}
