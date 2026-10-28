import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/domain/entities/daily_excel_feed.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/domain/usecases/get_excel_imports_usecase.dart';
import 'package:recall/domain/usecases/run_daily_excel_feed_usecase.dart';

part 'daily_feed_state.dart';

/// Backs the daily-feed settings section.
///
/// Holds the space's Excel files and decks so the section can show what is
/// queued and where it will land without reaching into repositories from the
/// widget layer.
class DailyFeedCubit extends Cubit<DailyFeedState> {
  DailyFeedCubit({
    required GetDecksUseCase getDecksUseCase,
    required GetExcelImportsUseCase getImportsUseCase,
    required RunDailyExcelFeedUseCase runFeedUseCase,
    required String spaceId,
  })  : _getDecksUseCase = getDecksUseCase,
        _getImportsUseCase = getImportsUseCase,
        _runFeedUseCase = runFeedUseCase,
        _spaceId = spaceId,
        super(const DailyFeedState());

  final GetDecksUseCase _getDecksUseCase;
  final GetExcelImportsUseCase _getImportsUseCase;
  final RunDailyExcelFeedUseCase _runFeedUseCase;
  final String _spaceId;

  Future<void> load() async {
    emit(state.copyWith(status: DailyFeedStatus.loading));
    try {
      final results = await Future.wait([
        _getDecksUseCase(_spaceId),
        _getImportsUseCase(_spaceId),
      ]);
      emit(
        state.copyWith(
          status: DailyFeedStatus.ready,
          decks: results[0] as List<Deck>,
          imports: results[1] as List<ExcelImport>,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: DailyFeedStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> runNow() async {
    emit(state.copyWith(running: true, lastResult: null));
    try {
      final result = await _runFeedUseCase.runForSpaceId(
        spaceId: _spaceId,
        force: true,
      );
      // The rows moved, so the library's pending counts are stale.
      await load();
      emit(
        state.copyWith(
          running: false,
          lastResult: result,
          status: DailyFeedStatus.ready,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          running: false,
          status: DailyFeedStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}