import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/text_direction_utils.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/get_decks_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class SpaceCardsScreen extends StatefulWidget {
  const SpaceCardsScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  State<SpaceCardsScreen> createState() => _SpaceCardsScreenState();
}

class _SpaceCardsScreenState extends State<SpaceCardsScreen> {
  List<Flashcard> _cards = [];
  Map<String, Deck> _decks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cards = await sl<IFlashcardRepository>().getCardsBySpaceId(
      widget.spaceId,
    );
    final decks = await sl<GetDecksUseCase>()(widget.spaceId);
    if (!mounted) return;
    cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _cards = cards;
      _decks = {for (final deck in decks) deck.id: deck};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: AppPageHeader(
                title: AppStrings.reviewedCardsHome,
                subtitle: _loading
                    ? null
                    : '${_cards.length} ${AppStrings.cards}',
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cards.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.spaceCardsEmpty,
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            final deckName = _decks[card.deckId]?.name;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        card.front,
                                        textDirection: textDirectionFor(
                                          card.front,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        card.back,
                                        textDirection: textDirectionFor(
                                          card.back,
                                        ),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.mutedForeground,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        [
                                          '${AppStrings.box} ${card.box}',
                                          ?deckName,
                                        ].join(' · '),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.mutedForeground,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
