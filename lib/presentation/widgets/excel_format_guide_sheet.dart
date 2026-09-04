import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/core/utils/responsive.dart';

Future<bool> showExcelFormatGuideSheet(BuildContext context) {
  final colors = context.recallColors;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      constraints: BoxConstraints(maxHeight: context.sheetMaxHeight),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
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
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.accentColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      AppStrings.excelFormatGuideTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                AppStrings.excelFormatGuideIntro,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: colors.mutedForeground,
                ),
              ),
              const SizedBox(height: 16),
              const ExcelFormatGuideCard(compact: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.upload_file, size: 20),
                  label: const Text(AppStrings.excelSelectFile),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text(AppStrings.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ).then((value) => value ?? false);
}

class ExcelFormatGuideCard extends StatelessWidget {
  const ExcelFormatGuideCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final accent = context.accentColor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RuleRow(
            icon: Icons.insert_drive_file_outlined,
            text: AppStrings.excelFormatRuleFormat,
            color: accent,
          ),
          const SizedBox(height: 8),
          _RuleRow(
            icon: Icons.view_column_outlined,
            text: AppStrings.excelFormatRuleColumnA,
            color: accent,
          ),
          const SizedBox(height: 8),
          _RuleRow(
            icon: Icons.view_column_outlined,
            text: AppStrings.excelFormatRuleColumnB,
            color: accent,
          ),
          const SizedBox(height: 8),
          _RuleRow(
            icon: Icons.table_rows_outlined,
            text: AppStrings.excelFormatRuleSheet,
            color: accent,
          ),
          const SizedBox(height: 8),
          _RuleRow(
            icon: Icons.filter_list_outlined,
            text: AppStrings.excelFormatRuleRows,
            color: accent,
          ),
          if (!compact) ...[
            const SizedBox(height: 14),
            Text(
              AppStrings.excelFormatExampleTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 10),
          _ExampleTable(accent: accent, colors: colors),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45)),
        ),
      ],
    );
  }
}

class _ExampleTable extends StatelessWidget {
  const _ExampleTable({required this.accent, required this.colors});

  final Color accent;
  final RecallColors colors;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
      border: TableBorder.all(color: colors.border),
      children: [
        TableRow(
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15)),
          children: const [
            _ExampleCell('A — روی کارت', header: true),
            _ExampleCell('B — پشت کارت', header: true),
          ],
        ),
        const TableRow(
          children: [
            _ExampleCell(AppStrings.excelFormatExampleFront),
            _ExampleCell(AppStrings.excelFormatExampleBack),
          ],
        ),
        const TableRow(children: [_ExampleCell('book'), _ExampleCell('کتاب')]),
      ],
    );
  }
}

class _ExampleCell extends StatelessWidget {
  const _ExampleCell(this.text, {this.header = false});

  final String text;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: header ? 11 : 13,
          fontWeight: header ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
