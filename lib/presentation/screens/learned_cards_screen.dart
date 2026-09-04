import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/text_direction_utils.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/repositories/flashcard_repository.dart';
import 'package:recall/domain/usecases/update_card_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class LearnedCardsScreen extends StatefulWidget {
  const LearnedCardsScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  State<LearnedCardsScreen> createState() => _LearnedCardsScreenState();
}

class _LearnedCardsScreenState extends State<LearnedCardsScreen> {
  List<Flashcard> _cards = [];
  final Set<String> _selectedIds = {};
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
    if (!mounted) return;
    setState(() {
      _cards = cards.where((card) => card.isLearned).toList()
        ..sort((a, b) => b.lastReviewed?.compareTo(a.lastReviewed ?? b.createdAt) ??
            b.createdAt.compareTo(a.createdAt));
      _selectedIds.removeWhere((id) => !_cards.any((card) => card.id == id));
      _loading = false;
    });
  }

  Future<void> _returnSelectedToBox1() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await showConfirmDialog(
      context,
      title: AppStrings.returnToBox1,
      message: AppStrings.returnToBox1Confirm,
    );
    if (confirmed != true || !mounted) return;

    final updateCard = sl<UpdateCardUseCase>();
    for (final card in _cards.where((c) => _selectedIds.contains(c.id))) {
      await updateCard(
        card.copyWith(box: 1, clearLastReviewed: true),
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.returnToBox1Done)),
    );
    await _load();
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Row(
                children: [
                  CircleIconButton(
                    back: true,
                    icon: Icons.arrow_back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      AppStrings.learnedCards,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                AppStrings.learnedCardsHint,
                style: TextStyle(fontSize: 12, color: colors.mutedForeground),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cards.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.learnedCardsEmpty,
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: _cards.length,
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            final selected = _selectedIds.contains(card.id);
                            return Material(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? context.accentColor
                                        : colors.border,
                                  ),
                                  boxShadow: AppShadows.card(context),
                                ),
                                child: CheckboxListTile(
                                  value: selected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedIds.add(card.id);
                                      } else {
                                        _selectedIds.remove(card.id);
                                      }
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    card.front,
                                    textDirection: textDirectionFor(card.front),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    card.back,
                                    textDirection: textDirectionFor(card.back),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.mutedForeground,
                                    ),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: FilledButton(
            onPressed: _selectedIds.isEmpty ? null : _returnSelectedToBox1,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              _selectedIds.isEmpty
                  ? AppStrings.returnToBox1
                  : '${AppStrings.returnToBox1} (${_selectedIds.length})',
            ),
          ),
        ),
      ),
    );
  }
}
