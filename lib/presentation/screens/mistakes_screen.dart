import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/usecases/get_todays_mistakes_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/mistakes/mistakes_cubit.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// Lists the cards answered wrongly today so any deck's mistakes can be
/// retried in one tap.
class MistakesScreen extends StatelessWidget {
  const MistakesScreen({super.key, required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MistakesCubit>(param1: spaceId)..load(),
      child: const _MistakesView(),
    );
  }
}

class _MistakesView extends StatelessWidget {
  const _MistakesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<MistakesCubit, MistakesState>(
          builder: (context, state) {
            if (state.status == MistakesStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            final decks = state.decksWithMistakes;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: AppPageHeader(
                    title: AppStrings.todaysMistakes,
                    subtitle: AppStrings.todaysMistakesHint,
                  ),
                ),
                if (decks.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          AppStrings.noMistakesToday,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.recallColors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: context.read<MistakesCubit>().load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        itemCount: decks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final deck = decks[index];
                          final mistakes = state.mistakesFor(deck.id);
                          return _MistakeDeckCard(
                            deckName: deck.name,
                            mistakes: mistakes,
                            onRetry: () => _retry(context, deck.id, mistakes),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _retry(BuildContext context, String deckId, List<MistakeCard> mistakes) {
    final cubit = context.read<MistakesCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudyScreen(
          config: cubit.retryConfig(deckId),
        ),
      ),
    );
  }
}

class _MistakeDeckCard extends StatelessWidget {
  const _MistakeDeckCard({
    required this.deckName,
    required this.mistakes,
    required this.onRetry,
  });

  final String deckName;
  final List<MistakeCard> mistakes;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: colors.border),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.rose, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deckName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                AppStrings.mistakeCount(mistakes.length),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final mistake in mistakes.take(12))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text(
                    mistake.front,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              if (mistakes.length > 12)
                Text(
                  AppStrings.moreCards(mistakes.length - 12),
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.mutedForeground,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(AppStrings.reviewMistakesNow),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}