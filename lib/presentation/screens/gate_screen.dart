import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/review_rating.dart';
import 'package:recall/presentation/blocs/gate/gate_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

/// The flashcards between the user and the app they opened.
///
/// Deliberately plainer than the study screen: no editing, no settings, no way
/// sideways into the rest of the app. Answer, and the app opens; back, and the
/// phone goes to its home screen.
class GateScreen extends StatelessWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<GateCubit>().leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<GateCubit, GateState>(
            builder: (context, state) {
              final card = state.current;
              if (state.status != GateStatus.asking || card == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final cubit = context.read<GateCubit>();
              final remaining = state.cards.length - state.index;

              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.gateTitle(state.target!.label),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.gateRemaining(remaining),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: state.index / state.cards.length,
                        minHeight: 6,
                        backgroundColor: colors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GestureDetector(
                        onTap: cubit.flip,
                        child: SoftCard(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                // One face at a time, as on a real card:
                                // turned over, it shows the back only.
                                children: [
                                  Text(
                                    state.flipped ? card.back : card.front,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (!state.flipped) ...[
                                    const SizedBox(height: 20),
                                    Text(
                                      AppStrings.tapToReveal,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 56,
                      child: state.flipped
                          ? Row(
                              children: [
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.know,
                                    color: AppColors.know,
                                    onPressed: () =>
                                        cubit.answer(ReviewRating.know),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RateButton(
                                    label: AppStrings.dontKnow,
                                    color: AppColors.dontKnow,
                                    onPressed: () =>
                                        cubit.answer(ReviewRating.dontKnow),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
