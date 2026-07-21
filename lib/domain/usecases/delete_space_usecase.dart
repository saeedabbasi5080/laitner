import 'package:recall/data/datasources/excel_import_store.dart';
import 'package:recall/data/datasources/review_history_store.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/repositories/space_repository.dart';

class DeleteSpaceUseCase {
  DeleteSpaceUseCase(
    this._repository,
    this._reviewHistoryStore,
    this._excelImportStore,
    this._spaceSettingsStore,
  );

  final ISpaceRepository _repository;
  final ReviewHistoryStore _reviewHistoryStore;
  final ExcelImportStore _excelImportStore;
  final SpaceSettingsStore _spaceSettingsStore;

  Future<void> call(String spaceId) async {
    await _repository.deleteSpace(spaceId);
    await _reviewHistoryStore.deleteBySpaceId(spaceId);
    await _excelImportStore.deleteBySpaceId(spaceId);
    await _spaceSettingsStore.delete(spaceId);
  }
}
