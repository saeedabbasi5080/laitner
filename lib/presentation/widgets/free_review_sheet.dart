import 'package:flutter/material.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/study_screen.dart';

class _FreeReviewLaunch {
  const _FreeReviewLaunch({required this.box, required this.reversed});

  final int box;
  final bool reversed;
}

Future<void> showFreeReviewSheet(
  BuildContext context, {
  required Map<int, int> boxCounts,
  int? initialBox,
}) async {
  final colors = context.recallColors;
  final availableBoxes = List.generate(maxBox, (i) => i + 1)
      .where((box) => (boxCounts[box] ?? 0) > 0)
      .toList();

  if (availableBoxes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.freeReviewEmpty)),
    );
    return;
  }

  var selectedBox = initialBox ?? availableBoxes.first;
  if (!availableBoxes.contains(selectedBox)) {
    selectedBox = availableBoxes.first;
  }
  var reversed = false;

  final launch = await showModalBottomSheet<_FreeReviewLaunch>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        return Container(
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
                  AppStrings.freeReviewSetup,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.selectBox,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(maxBox, (index) {
                    final box = index + 1;
                    final count = boxCounts[box] ?? 0;
                    final enabled = count > 0;
                    final selected = selectedBox == box;

                    return FilterChip(
                      label: Text('${AppStrings.box} $box ($count)'),
                      selected: selected,
                      onSelected: enabled
                          ? (_) => setState(() => selectedBox = box)
                          : null,
                    );
                  }),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    reversed
                        ? AppStrings.reversedReview
                        : AppStrings.normalReview,
                  ),
                  value: reversed,
                  onChanged: (v) => setState(() => reversed = v),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        ctx,
                        _FreeReviewLaunch(
                          box: selectedBox,
                          reversed: reversed,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      foregroundColor: const Color(0xFF1A1D24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      '${AppStrings.startReview} — ${AppStrings.box} $selectedBox',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (launch == null || !context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StudyScreen(
        config: StudyConfig.byBox(
          launch.box,
          reversed: launch.reversed,
        ),
      ),
    ),
  );
}
