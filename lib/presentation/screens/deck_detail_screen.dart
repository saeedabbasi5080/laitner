import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/deck.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/deck_detail/deck_detail_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/add_card_screen.dart';
import 'package:recall/presentation/screens/excel_library_screen.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:recall/presentation/utils/export_deck_excel.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class DeckDetailScreen extends StatelessWidget {
  const DeckDetailScreen({
    super.key,
    required this.deckId,
    required this.spaceId,
  });

  final String deckId;
  final String spaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeckDetailCubit>(param1: deckId, param2: spaceId)..load(),
      child: _DeckDetailView(deckId: deckId, spaceId: spaceId),
    );
  }
}

class _DeckDetailView extends StatelessWidget {
  const _DeckDetailView({required this.deckId, required this.spaceId});

  final String deckId;
  final String spaceId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeckDetailCubit, DeckDetailState>(
      builder: (context, state) {
        if (state.status == DeckDetailStatus.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.status == DeckDetailStatus.notFound) {
          return Scaffold(
            body: Center(
              child: Text(
                AppStrings.deckNotFound,
                style: TextStyle(color: context.recallColors.mutedForeground),
              ),
            ),
          );
        }

        final deck = state.deck!;
        final accent = AppColors.forDeck(deck.color);
        final colors = context.recallColors;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppPageHeader(
                          title: deck.name,
                          subtitle: AppStrings.deck,
                          actions: [
                            CircleIconButton(
                              icon: Icons.edit_outlined,
                              onPressed: () => _editDeck(context, deck),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                label: AppStrings.cards,
                                value: state.cards.length,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                label: AppStrings.due,
                                value: state.dueCount,
                                accent: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _openStudy(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: null,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              state.dueCount > 0
                                  ? '${AppStrings.studyNCards} ${state.dueCount} ${AppStrings.cards}'
                                  : AppStrings.studyDeck,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openAddCard(context),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(AppStrings.addCard),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        if (state.cards.isNotEmpty &&
                            state.otherDecks.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _transferCards(
                                context,
                                state.cards.map((c) => c.id).toList(),
                                state.otherDecks,
                              ),
                              icon: const Icon(
                                Icons.drive_file_move_outline,
                                size: 18,
                              ),
                              label: const Text(AppStrings.transferAllCards),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => exportDeckExcel(context, deckId),
                            icon: const Icon(
                              Icons.file_download_outlined,
                              size: 18,
                            ),
                            label: const Text(AppStrings.exportDeckExcel),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            AppStrings.exportDeckExcelHint,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context)
                                .push(
                              MaterialPageRoute<void>(
                                builder: (_) => ExcelLibraryScreen(
                                  spaceId: spaceId,
                                  initialDeckId: deckId,
                                ),
                              ),
                            )
                                .then((_) {
                              if (context.mounted) {
                                context.read<DeckDetailCubit>().load();
                              }
                            }),
                            icon: const Icon(
                              Icons.table_chart_outlined,
                              size: 18,
                            ),
                            label: const Text(AppStrings.excelLibrary),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            AppStrings.excelLibrarySubtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ),
                        if (state.cards.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          const SectionLabel(AppStrings.allCards),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                if (state.cards.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList.builder(
                      itemCount: state.cards.length,
                      itemBuilder: (context, index) {
                        final card = state.cards[index];
                        return _CardListItem(
                          front: card.front,
                          back: card.back,
                          box: card.box,
                          accent: accent,
                          onEdit: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => CardFormSheet(
                              front: card.front,
                              back: card.back,
                              onSubmit: (f, b) => context
                                  .read<DeckDetailCubit>()
                                  .updateCard(card.id, f, b),
                            ),
                          ),
                          onDelete: () async {
                            final ok = await showConfirmDialog(
                              context,
                              title: AppStrings.deleteCard,
                              message: AppStrings.deleteCardConfirm,
                            );
                            if (ok == true && context.mounted) {
                              await context
                                  .read<DeckDetailCubit>()
                                  .deleteCard(card.id);
                            }
                          },
                          onTransfer: state.otherDecks.isEmpty
                              ? null
                              : () => _transferCards(
                                    context,
                                    [card.id],
                                    state.otherDecks,
                                  ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editDeck(BuildContext context, Deck deck) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DeckFormSheet(
        deck: deck,
        onSubmit: (name, color) => context
            .read<DeckDetailCubit>()
            .updateDeck(deck.copyWith(name: name.trim(), color: color)),
        onExport: () => exportDeckExcel(context, deck.id),
        onDelete: () async {
          final decision = await showDeleteDeckFlow(
            context,
            otherDecks: context.read<DeckDetailCubit>().state.otherDecks,
          );
          if (decision != null && context.mounted) {
            await context.read<DeckDetailCubit>().deleteDeck(
              transferToDeckId: decision.transferToDeckId,
            );
            if (context.mounted) Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  void _openStudy(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(
          config: StudyConfig.deck(spaceId: spaceId, deckId: deckId),
        ),
      ),
    ).then((_) {
      if (context.mounted) context.read<DeckDetailCubit>().load();
    });
  }

  void _openAddCard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddCardScreen(deckId: deckId, spaceId: spaceId),
      ),
    ).then((_) {
      if (context.mounted) context.read<DeckDetailCubit>().load();
    });
  }

  Future<void> _transferCards(
    BuildContext context,
    List<String> cardIds,
    List<Deck> otherDecks,
  ) async {
    final targetId = await showPickDeckDialog(
      context,
      decks: otherDecks,
      title: AppStrings.selectTargetDeck,
    );
    if (targetId == null || !context.mounted) return;
    await context.read<DeckDetailCubit>().moveCards(cardIds, targetId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.cardsTransferred)),
      );
    }
  }
}

class _CardListItem extends StatelessWidget {
  const _CardListItem({
    required this.front,
    required this.back,
    required this.box,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
    this.onTransfer,
  });

  final String front;
  final String back;
  final int box;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      front,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      back,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppStrings.box} $box',
                      style: TextStyle(
                        fontSize: 11,
                        color: accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
              if (onTransfer != null)
                IconButton(
                  tooltip: AppStrings.transferCard,
                  onPressed: onTransfer,
                  icon: const Icon(Icons.drive_file_move_outline, size: 18),
                ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
