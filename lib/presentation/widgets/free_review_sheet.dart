import 'package:flutter/material.dart';
import 'package:recall/core/constants/leitner_constants.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/due_day_utils.dart';
import 'package:recall/core/utils/responsive.dart';
import 'package:recall/domain/entities/flashcard.dart';
import 'package:recall/domain/usecases/get_cards_by_box_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/study/study_config.dart';
import 'package:recall/presentation/screens/study_screen.dart';

class _FreeReviewLaunch {
  const _FreeReviewLaunch({
    required this.box,
    required this.reversed,
    this.dueDay,
    this.overdueOnly = false,
  });

  final int box;
  final bool reversed;
  final DateTime? dueDay;
  final bool overdueOnly;
}

Future<void> showFreeReviewSheet(
  BuildContext context, {
  required String spaceId,
  required Map<int, int> boxCounts,
  int? initialBox,
}) async {
  final colors = context.recallColors;
  final availableBoxes = List.generate(
    maxBox,
    (i) => i + 1,
  ).where((box) => (boxCounts[box] ?? 0) > 0).toList();

  if (availableBoxes.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.freeReviewEmpty)));
    return;
  }

  final cardsByBox = <int, List<Flashcard>>{};
  for (final box in availableBoxes) {
    cardsByBox[box] = await sl<GetCardsByBoxUseCase>()(box, spaceId: spaceId);
  }
  if (!context.mounted) return;

  var selectedBox = initialBox ?? availableBoxes.first;
  if (!availableBoxes.contains(selectedBox)) {
    selectedBox = availableBoxes.first;
  }
  var reversed = false;
  DateTime? selectedDueDay;
  var selectedOverdue = false;

  final launch = await showModalBottomSheet<_FreeReviewLaunch>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) {
        final dayBuckets = groupCardsByDueDay(
          cardsByBox[selectedBox] ?? const [],
        );
        final selectedDayLabel = selectedOverdue
            ? 'معوق'
            : selectedDueDay == null
            ? AppStrings.allReviewDays
            : dueDayLabel(DueDayBucket(day: selectedDueDay, cards: const []));
        return Container(
          constraints: BoxConstraints(maxHeight: context.sheetMaxHeight),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
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
                            ? (_) => setState(() {
                                selectedBox = box;
                                selectedDueDay = null;
                                selectedOverdue = false;
                              })
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppStrings.selectReviewDay,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            '${AppStrings.allReviewDays} '
                            '(${cardsByBox[selectedBox]?.length ?? 0})',
                          ),
                          selected: selectedDueDay == null && !selectedOverdue,
                          onSelected: (_) => setState(() {
                            selectedDueDay = null;
                            selectedOverdue = false;
                          }),
                        ),
                        for (final bucket in dayBuckets) ...[
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(
                              '${dueDayLabel(bucket)} (${bucket.count})',
                            ),
                            selected: bucket.isOverdue
                                ? selectedOverdue
                                : selectedDueDay == bucket.day,
                            onSelected: (_) => setState(() {
                              selectedOverdue = bucket.isOverdue;
                              selectedDueDay = bucket.isOverdue
                                  ? null
                                  : bucket.day;
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.freeReviewPreviewHint,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            dueDay: selectedDueDay,
                            overdueOnly: selectedOverdue,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        '${AppStrings.startReview} — ${AppStrings.box} '
                        '$selectedBox — $selectedDayLabel',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
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
          spaceId: spaceId,
          reversed: launch.reversed,
          dueDay: launch.dueDay,
          overdueOnly: launch.overdueOnly,
        ),
      ),
    ),
  );
}
