import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/usecases/get_todays_mistakes_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/mistakes/mistakes_cubit.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/study_screen.dart';
import 'package:recall/presentation/widgets/mistake_card_list.dart';
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
                else ...[
                  if (decks.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _open(
                            context,
                            context.read<MistakesCubit>().retryAllConfig(),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(AppStrings.reviewAllMistakes),
                        ),
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: context.read<MistakesCubit>().load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                        itemCount: decks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
              ],
            );
          },
        ),
      ),
    );
  }

  void _retry(BuildContext context, String deckId, List<MistakeCard> mistakes) {
    _open(context, context.read<MistakesCubit>().retryConfig(deckId));
  }

  /// Opens the retry, and reloads afterwards so the list reflects it.
  void _open(BuildContext context, StudyConfig config) {
    final cubit = context.read<MistakesCubit>();
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(builder: (_) => StudyScreen(config: config)),
        )
        .then((_) {
          if (!cubit.isClosed) cubit.load();
        });
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
          const SizedBox(height: 4),
          // Every card with its answer, so the list can be read through before
          // deciding to review it — the point of coming back hours later.
          MistakeCardList(
            cards: [for (final mistake in mistakes) mistake.card],
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
