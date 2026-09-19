import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class DeleteSpaceUseCase {
  DeleteSpaceUseCase(
    this._repository,
    this._reviewHistoryStore,
    this._excelImportStore,
    this._spaceSettingsStore,
    this._deckRepository,
  );

  final ISpaceRepository _repository;
  final ReviewHistoryStore _reviewHistoryStore;
  final ExcelImportStore _excelImportStore;
  final SpaceSettingsStore _spaceSettingsStore;
  final IDeckRepository _deckRepository;

  Future<void> call(String spaceId, {String? transferToSpaceId}) async {
    if (transferToSpaceId != null && transferToSpaceId != spaceId) {
      final decks = await _deckRepository.getDecksBySpaceId(spaceId);
      for (final deck in decks) {
        await _deckRepository.updateDeck(
          deck.copyWith(spaceId: transferToSpaceId),
        );
      }
      await _reviewHistoryStore.reassignSpaceId(spaceId, transferToSpaceId);
      await _excelImportStore.reassignSpaceId(spaceId, transferToSpaceId);
    }

    await _repository.deleteSpace(spaceId);

    if (transferToSpaceId == null || transferToSpaceId == spaceId) {
      await _reviewHistoryStore.deleteBySpaceId(spaceId);
      await _excelImportStore.deleteBySpaceId(spaceId);
    }
    await _spaceSettingsStore.delete(spaceId);
  }
}
