import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/due_day_utils.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/injection.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class BoxCardsScreen extends StatefulWidget {
  const BoxCardsScreen({
    super.key,
    required this.boxNumber,
    required this.spaceId,
  });

  final int boxNumber;
  final String spaceId;

  @override
  State<BoxCardsScreen> createState() => _BoxCardsScreenState();
}

class _BoxCardsScreenState extends State<BoxCardsScreen> {
  List<Flashcard> _cards = [];
  Map<String, Deck> _deckMap = {};
  bool _loading = true;
  bool _reversed = false;
  DateTime? _selectedDueDay;
  bool _selectedOverdue = false;

  List<DueDayBucket> get _dayBuckets => groupCardsByDueDay(_cards);

  List<Flashcard> get _visibleCards => filterCardsByDueDay(
    _cards,
    dueDay: _selectedDueDay,
    overdueOnly: _selectedOverdue,
  );

  String get _selectedDayLabel {
    if (_selectedOverdue) return 'معوق';
    if (_selectedDueDay == null) return AppStrings.allReviewDays;
    return dueDayLabel(DueDayBucket(day: _selectedDueDay, cards: const []));
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cards = await sl<GetCardsByBoxUseCase>()(
      widget.boxNumber,
      spaceId: widget.spaceId,
    );
    final decks = await sl<GetDecksUseCase>()(widget.spaceId);
    if (mounted) {
      setState(() {
        _cards = cards;
        _deckMap = {for (final d in decks) d.id: d};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final visibleCards = _visibleCards;
    final dayBuckets = _dayBuckets;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: AppPageHeader(
                title: '${AppStrings.box} ${widget.boxNumber}',
                subtitle:
                    '${visibleCards.length} از ${_cards.length} ${AppStrings.cards}',
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_cards.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    AppStrings.noDueCards,
                    style: TextStyle(color: colors.mutedForeground),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppStrings.reviewSchedule,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.reviewScheduleHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                '${AppStrings.allReviewDays} (${_cards.length})',
                              ),
                              selected:
                                  _selectedDueDay == null && !_selectedOverdue,
                              onSelected: (_) => setState(() {
                                _selectedDueDay = null;
                                _selectedOverdue = false;
                              }),
                            ),
                            for (final bucket in dayBuckets) ...[
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text(
                                  '${dueDayLabel(bucket)} (${bucket.count})',
                                ),
                                selected: bucket.isOverdue
                                    ? _selectedOverdue
                                    : _selectedDueDay == bucket.day,
                                onSelected: (_) => setState(() {
                                  _selectedOverdue = bucket.isOverdue;
                                  _selectedDueDay = bucket.isOverdue
                                      ? null
                                      : bucket.day;
                                }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _reversed
                        ? AppStrings.reversedReview
                        : AppStrings.normalReview,
                  ),
                  value: _reversed,
                  onChanged: (v) => setState(() => _reversed = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StudyScreen(
                            config: StudyConfig.byBox(
                              widget.boxNumber,
                              spaceId: widget.spaceId,
                              reversed: _reversed,
                              dueDay: _selectedDueDay,
                              overdueOnly: _selectedOverdue,
                            ),
                          ),
                        ),
                      );
                      if (mounted) _load();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      '${AppStrings.freeReview} — ${AppStrings.box} '
                      '${widget.boxNumber} — $_selectedDayLabel',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: visibleCards.length,
                  itemBuilder: (context, index) {
                    final card = visibleCards[index];
                    final deck = _deckMap[card.deckId];
                    final accent = deck != null
                        ? AppColors.forDeck(deck.color)
                        : context.accentColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.border),
                    boxShadow: AppShadows.card(context),
                  ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (deck != null)
                            Text(
                              deck.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: accent,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            card.front,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card.back,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showAddMenuSheet(
  BuildContext context, {
  required List<Deck> decks,
  required VoidCallback onAddDeck,
  required void Function(String deckId) onAddCard,
  VoidCallback? onImportExcel,
}) {
  final colors = context.recallColors;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.whatToAdd,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Material(
              color: colors.muted,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: Icon(
                  Icons.layers_outlined,
                  color: context.accentColor,
                ),
                title: const Text(AppStrings.addNewDeck),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onAddDeck();
                },
              ),
            ),
            const SizedBox(height: 8),
            Material(
              color: colors.muted,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const Icon(
                  Icons.style_outlined,
                  color: AppColors.mint,
                ),
                title: const Text(AppStrings.addNewCard),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (decks.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.noDecksForCard)),
                    );
                    return;
                  }
                  _showDeckPicker(context, decks, onAddCard);
                },
              ),
            ),
            if (onImportExcel != null) ...[
              const SizedBox(height: 8),
              Material(
                color: colors.muted,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(
                    Icons.table_chart_outlined,
                    color: AppColors.sky,
                  ),
                  title: const Text(AppStrings.excelLibrary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onImportExcel();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

void _showDeckPicker(
  BuildContext context,
  List<Deck> decks,
  void Function(String deckId) onAddCard,
) {
  final colors = context.recallColors;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.selectDeck,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: decks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final deck = decks[index];
                  final accent = AppColors.forDeck(deck.color);
                  return ListTile(
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(deck.name),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: colors.muted,
                    onTap: () {
                      Navigator.pop(ctx);
                      onAddCard(deck.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
