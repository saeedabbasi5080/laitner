import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/app_gate/app_gate.dart';
import 'package:recall/data/datasources/space_settings_store.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/domain/usecases/get_app_gate_cards_usecase.dart';
import 'package:recall/domain/usecases/review_card_usecase.dart';
import 'package:recall/domain/usecases/sync_app_gate_due_usecase.dart';

enum GateStatus { loading, asking, opening }

class GateState extends Equatable {
  const GateState({
    this.status = GateStatus.loading,
    this.target,
    this.cards = const [],
    this.index = 0,
    this.flipped = false,
  });

  final GateStatus status;
  final GateTarget? target;

  /// The cards to answer before the app opens.
  final List<Flashcard> cards;
  final int index;
  final bool flipped;

  Flashcard? get current => index < cards.length ? cards[index] : null;

  GateState copyWith({
    GateStatus? status,
    GateTarget? target,
    List<Flashcard>? cards,
    int? index,
    bool? flipped,
  }) => GateState(
    status: status ?? this.status,
    target: target ?? this.target,
    cards: cards ?? this.cards,
    index: index ?? this.index,
    flipped: flipped ?? this.flipped,
  );

  @override
  List<Object?> get props => [status, target, cards, index, flipped];
}

/// The flashcards shown before a chosen app opens.
///
/// Only cards due today are asked, and their answers are real reviews: they
/// were due, so answering them here is the same as answering them in the app.
/// Any answer counts — "don't know" sends the card back as it normally would,
/// and the app still opens. When nothing is due the app opens at once; the
/// native side normally lets it straight through, and this covers the first
/// opening of a day, before today's count is known.
class GateCubit extends Cubit<GateState> {
  GateCubit({
    required AppGatePlatform platform,
    required GetAppGateCardsUseCase getCards,
    required ReviewCardUseCase reviewCard,
    required SpaceSettingsStore spaceSettingsStore,
    required SyncAppGateDueUseCase syncDue,
  }) : _platform = platform,
       _getCards = getCards,
       _reviewCard = reviewCard,
       _spaceSettings = spaceSettingsStore,
       _syncDue = syncDue,
       super(const GateState());

  final AppGatePlatform _platform;
  final GetAppGateCardsUseCase _getCards;
  final ReviewCardUseCase _reviewCard;
  final SpaceSettingsStore _spaceSettings;
  final SyncAppGateDueUseCase _syncDue;

  /// The space of each card asked, so its answer uses that space's houses.
  final Map<String, String> _spaceOf = {};
  bool _busy = false;

  Future<void> load() async {
    emit(const GateState());
    final target = await _platform.target();
    if (target == null) {
      await _platform.goHome();
      return;
    }
    final config = await _platform.loadConfig();
    final due = await _getCards(config);

    final count = switch (config.mode) {
      AppGateMode.perOpen =>
        due.length < config.cardsPerOpen ? due.length : config.cardsPerOpen,
      AppGateMode.allDue => due.length,
    };

    if (count == 0) {
      await _open(target);
      return;
    }

    final asked = due.take(count).toList();
    _spaceOf
      ..clear()
      ..addAll({for (final g in asked) g.card.id: g.spaceId});
    emit(
      GateState(
        status: GateStatus.asking,
        target: target,
        cards: [for (final g in asked) g.card],
      ),
    );
  }

  void flip() {
    if (state.status != GateStatus.asking) return;
    emit(state.copyWith(flipped: !state.flipped));
  }

  Future<void> answer(ReviewRating rating) async {
    final card = state.current;
    final spaceId = card == null ? null : _spaceOf[card.id];
    if (_busy || card == null || !state.flipped || spaceId == null) return;
    _busy = true;
    try {
      final settings = await _spaceSettings.load(spaceId);
      await _reviewCard(
        card,
        rating,
        spaceId: spaceId,
        boxes: settings.leitnerBoxes,
        settings: settings.reviewSettings,
      );

      final next = state.index + 1;
      if (next >= state.cards.length) {
        await _open(state.target!);
        return;
      }
      emit(state.copyWith(index: next, flipped: false));
    } finally {
      _busy = false;
    }
  }

  /// Leaves without opening the app.
  Future<void> leave() => _platform.goHome();

  Future<void> _open(GateTarget target) async {
    emit(state.copyWith(status: GateStatus.opening, target: target));
    // Before opening, so the lock already knows whether anything is left today.
    try {
      await _syncDue();
    } catch (_) {
      // A count that could not be refreshed is re-read on the next opening.
    }
    await _platform.unlockAndOpen(target.package);
  }
}
