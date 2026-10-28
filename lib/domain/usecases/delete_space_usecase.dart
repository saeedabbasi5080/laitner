import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/repositories/deck_repository.dart';
import 'package:recall/domain/repositories/review_history_repository.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class DeleteSpaceUseCase {
  DeleteSpaceUseCase(
    this._repository,
    this._reviewHistoryRepository,
    this._excelImportStore,
    this._spaceSettingsStore,
    this._deckRepository,
  );

  final ISpaceRepository _repository;
  final IReviewHistoryRepository _reviewHistoryRepository;
  final ExcelImportStore _excelImportStore;
  final SpaceSettingsStore _spaceSettingsStore;
  final IDeckRepository _deckRepository;

  Future<void> call(String spaceId, {String? transferToSpaceId}) async {
    final transferring =
        transferToSpaceId != null && transferToSpaceId != spaceId;

    if (transferring) {
      final decks = await _deckRepository.getDecksBySpaceId(spaceId);
      for (final deck in decks) {
        await _deckRepository.updateDeck(
          deck.copyWith(spaceId: transferToSpaceId),
        );
      }
      // History has to follow the decks, otherwise the reviews would vanish
      // from every statistics view the moment the space is gone.
      await _reviewHistoryRepository.reassignSpaceId(spaceId, transferToSpaceId);
      await _excelImportStore.reassignSpaceId(spaceId, transferToSpaceId);
    }

    await _repository.deleteSpace(spaceId);

    if (!transferring) {
      await _reviewHistoryRepository.deleteBySpaceId(spaceId);
      await _excelImportStore.deleteBySpaceId(spaceId);
    }
    await _spaceSettingsStore.delete(spaceId);
  }
}