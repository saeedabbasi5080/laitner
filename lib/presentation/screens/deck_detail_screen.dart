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
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/deck_card_sheets.dart';

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
      create: (_) => sl<DeckDetailCubit>(param1: deckId)..load(),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleIconButton(
                        back: true,
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionLabel(AppStrings.deck),
                            Text(
                              deck.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _editDeck(context, deck),
                        icon: const Icon(Icons.edit_outlined),
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
                        foregroundColor: const Color(0xFF1A1D24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        state.dueCount > 0
                            ? '${AppStrings.studyNCards} ${state.dueCount} ${AppStrings.cards}'
                            : AppStrings.studyDeck,
                        style: const TextStyle(fontWeight: FontWeight.w600),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ExcelLibraryScreen(
                            spaceId: spaceId,
                            initialDeckId: deckId,
                          ),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          context.read<DeckDetailCubit>().load();
                        }
                      }),
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
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
                    ...state.cards.map(
                      (card) => _CardListItem(
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
                      ),
                    ),
                  ],
                ],
              ),
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
        onDelete: () async {
          final ok = await showConfirmDialog(
            context,
            title: AppStrings.deleteDeck,
            message: AppStrings.deleteDeckConfirm,
          );
          if (ok == true && context.mounted) {
            await context.read<DeckDetailCubit>().deleteDeck();
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
}

class _CardListItem extends StatelessWidget {
  const _CardListItem({
    required this.front,
    required this.back,
    required this.box,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  final String front;
  final String back;
  final int box;
  final Color accent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(front, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  back,
                  style: TextStyle(fontSize: 13, color: colors.mutedForeground),
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
    );
  }
}
