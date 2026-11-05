import 'package:recall/core/app_gate/app_gate.dart';
import 'package:recall/domain/usecases/get_app_gate_cards_usecase.dart';

/// Tells the app lock how many cards are due today in its spaces.
///
/// The native side lets every app through when the count for today is zero,
/// and asks the gate screen when it does not know today's count. So this runs
/// whenever the count can change on this device: on launch and resume, after
/// a study session, and after the gate itself.
class SyncAppGateDueUseCase {
  SyncAppGateDueUseCase({
    required AppGatePlatform platform,
    required GetAppGateCardsUseCase getCards,
    DateTime Function()? clock,
  }) : _platform = platform,
       _getCards = getCards,
       _now = clock ?? DateTime.now;

  final AppGatePlatform _platform;
  final GetAppGateCardsUseCase _getCards;
  final DateTime Function() _now;

  Future<void> call() async {
    if (!_platform.supported) return;
    final config = await _platform.loadConfig();
    if (!config.enabled) return;

    final now = _now();
    final due = await _getCards(config, now: now);
    await _platform.setDueState(due.length, now);
  }
}
