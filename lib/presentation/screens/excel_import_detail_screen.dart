import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/domain/usecases/add_selected_excel_rows_usecase.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/excel_import_detail/excel_import_detail_cubit.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';

class ExcelImportDetailScreen extends StatelessWidget {
  const ExcelImportDetailScreen({
    super.key,
    required this.importId,
    this.initialDeckId,
  });

  final String importId;
  final String? initialDeckId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<ExcelImportDetailCubit>(param1: importId, param2: initialDeckId)
            ..load(),
      child: const _ExcelImportDetailView(),
    );
  }
}

class _ExcelImportDetailView extends StatelessWidget {
  const _ExcelImportDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExcelImportDetailCubit, ExcelImportDetailState>(
      builder: (context, state) {
        if (state.status == ExcelImportDetailStatus.loading &&
            state.import == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.import == null) {
          return Scaffold(
            body: Center(
              child: Text(
                AppStrings.excelImportNotFound,
                style: TextStyle(color: context.recallColors.mutedForeground),
              ),
            ),
          );
        }

        final import = state.import!;
        final colors = context.recallColors;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    children: [
                      CircleIconButton(
                        back: true,
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              import.fileName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${import.pendingCount} ${AppStrings.excelPending} · ${import.addedCount} ${AppStrings.excelAdded}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(context),
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel(AppStrings.selectDeck),
                      const SizedBox(height: 8),
                      _DeckDropdown(state: state),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton(
                            onPressed: state.import!.pendingCount > 0
                                ? () => context
                                      .read<ExcelImportDetailCubit>()
                                      .selectAllPending()
                                : null,
                            child: const Text(AppStrings.selectAllPending),
                          ),
                          TextButton(
                            onPressed: state.selectedRowIds.isNotEmpty
                                ? () => context
                                      .read<ExcelImportDetailCubit>()
                                      .clearSelection()
                                : null,
                            child: const Text(AppStrings.clearSelection),
                          ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilterChip(
                          label: Text(AppStrings.pendingOnlyRows),
                          selected: state.pendingOnly,
                          onSelected: (v) => context
                              .read<ExcelImportDetailCubit>()
                              .togglePendingOnly(v),
                        ),
                      ),
                      Text(
                        AppStrings.importExcelHint,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.visibleRows.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.excelAllAdded,
                            style: TextStyle(color: colors.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                          itemCount: state.visibleRows.length,
                          itemBuilder: (context, index) {
                            final row = state.visibleRows[index];
                            final showAddedHeader =
                                !state.pendingOnly &&
                                index > 0 &&
                                !state.visibleRows[index - 1].isAdded &&
                                row.isAdded;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (index == 0 &&
                                    !state.pendingOnly &&
                                    !row.isAdded)
                                  _SectionHeader(
                                    label: AppStrings.excelPending,
                                    colors: colors,
                                  )
                                else if (index == 0 &&
                                    !state.pendingOnly &&
                                    row.isAdded)
                                  _SectionHeader(
                                    label: AppStrings.excelAdded,
                                    colors: colors,
                                  )
                                else if (showAddedHeader)
                                  _SectionHeader(
                                    label: AppStrings.excelAdded,
                                    colors: colors,
                                  ),
                                _WordListTile(
                                  row: row,
                                  selected: state.selectedRowIds.contains(
                                    row.id,
                                  ),
                                  onChanged: row.isAdded
                                      ? null
                                      : (v) => context
                                            .read<ExcelImportDetailCubit>()
                                            .toggleRow(row.id),
                                ),
                              ],
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
                onPressed: _canAdd(state) ? () => _addSelected(context) : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  state.selectedPendingCount > 0
                      ? '${AppStrings.addSelectedToDeck} (${state.selectedPendingCount})'
                      : AppStrings.addSelectedToDeck,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _canAdd(ExcelImportDetailState state) {
    return state.selectedDeckId != null &&
        state.selectedPendingCount > 0 &&
        state.decks.isNotEmpty;
  }

  Future<void> _addSelected(BuildContext context) async {
    final result = await context
        .read<ExcelImportDetailCubit>()
        .addSelectedToDeck();
    if (!context.mounted) return;

    if (result.totalProcessed > 0) {
      await _showImportResult(context, result);
    }
  }

  Future<void> _showImportResult(
    BuildContext context,
    ExcelImportAddResult result,
  ) {
    final colors = context.recallColors;
    final cubit = context.read<ExcelImportDetailCubit>();
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.excelImportResult),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.excelImportResultSummary(
                  result.totalProcessed,
                  result.addedCount,
                  result.skippedDuplicates,
                ),
                style: const TextStyle(height: 1.7),
              ),
              if (result.duplicates.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionLabel(AppStrings.duplicateWords),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: result.duplicates.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: colors.border),
                    itemBuilder: (context, index) {
                      final duplicate = result.duplicates[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.content_copy_outlined,
                          color: AppColors.danger,
                        ),
                        title: Text(
                          duplicate.front,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          AppStrings.duplicateExistsInDeck(
                            duplicate.existingDeckName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (result.duplicates.isNotEmpty)
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showConfirmDialog(
                  dialogContext,
                  title: AppStrings.removeDuplicateWords,
                  message: AppStrings.removeDuplicateWordsQuestion,
                  confirmLabel: AppStrings.delete,
                );
                if (confirmed != true) return;

                final removed = await cubit.removeRows(
                  result.duplicates.map((item) => item.rowId),
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (removed > 0 && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.removeDuplicateWordsConfirm),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text(AppStrings.removeDuplicateWords),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.deleteExcelFile,
      message: AppStrings.deleteExcelFileConfirm,
    );
    if (ok == true && context.mounted) {
      await context.read<ExcelImportDetailCubit>().deleteImport();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _DeckDropdown extends StatelessWidget {
  const _DeckDropdown({required this.state});

  final ExcelImportDetailState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    if (state.decks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          AppStrings.noDecksForCard,
          style: TextStyle(color: colors.mutedForeground),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: state.selectedDeckId,
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      selectedItemBuilder: (context) {
        return state.decks.map((deck) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.forDeck(deck.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(deck.name, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          );
        }).toList();
      },
      items: state.decks
          .map(
            (deck) => DropdownMenuItem(value: deck.id, child: Text(deck.name)),
          )
          .toList(),
      onChanged: (id) {
        if (id != null) {
          context.read<ExcelImportDetailCubit>().selectDeck(id);
        }
      },
    );
  }
}

class _WordListTile extends StatelessWidget {
  const _WordListTile({
    required this.row,
    required this.selected,
    required this.onChanged,
  });

  final ExcelImportRow row;
  final bool selected;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final isAdded = row.isAdded;

    return Material(
      color: isAdded ? colors.muted.withValues(alpha: 0.45) : colors.card,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAdded
                ? AppColors.mint.withValues(alpha: 0.5)
                : (selected ? context.accentColor : colors.border),
            width: selected && !isAdded ? 1.5 : 1,
          ),
        ),
        child: isAdded
            ? ListTile(
                leading: Icon(Icons.check_circle, color: AppColors.mint),
                title: Text(
                  row.front,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                    color: colors.mutedForeground,
                  ),
                ),
                subtitle: Text(
                  AppStrings.excelAlreadyAdded,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.mint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : CheckboxListTile(
                value: selected,
                onChanged: onChanged,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  row.front,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  row.back,
                  style: TextStyle(fontSize: 13, color: colors.mutedForeground),
                ),
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.colors});

  final String label;
  final RecallColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}
