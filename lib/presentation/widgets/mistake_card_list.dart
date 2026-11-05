import 'package:flutter/material.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/flashcard.dart';

/// The cards that were answered wrong, each with its front and its answer, so
/// they can be read through before deciding to review them again.
///
/// A column rather than a list view: it sits inside pages and sheets that
/// already scroll.
class MistakeCardList extends StatelessWidget {
  const MistakeCardList({super.key, required this.cards});

  final List<Flashcard> cards;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) Divider(height: 1, color: colors.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cards[i].front,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cards[i].back,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
