import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/data/utils/excel_parser.dart';
import 'package:recall/data/utils/pick_excel_file.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/injection.dart';
import 'package:recall/presentation/blocs/excel_library/excel_library_cubit.dart';
import 'package:recall/presentation/screens/excel_import_detail_screen.dart';
import 'package:recall/presentation/widgets/common_widgets.dart';
import 'package:recall/presentation/widgets/excel_format_guide_sheet.dart';
import 'package:recall/presentation/widgets/soft_ui.dart';

class ExcelLibraryScreen extends StatelessWidget {
  const ExcelLibraryScreen({
    super.key,
    required this.spaceId,
    this.initialDeckId,
  });

  final String spaceId;
  final String? initialDeckId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExcelLibraryCubit>(param1: spaceId)..load(),
      child: _ExcelLibraryView(spaceId: spaceId, initialDeckId: initialDeckId),
    );
  }
}

class _ExcelLibraryView extends StatelessWidget {
  const _ExcelLibraryView({required this.spaceId, this.initialDeckId});

  final String spaceId;
  final String? initialDeckId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExcelLibraryCubit, ExcelLibraryState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: state.selectedIds.isEmpty
                      ? AppPageHeader(
                          title: AppStrings.excelLibrary,
                          subtitle: AppStrings.excelLibrarySubtitle,
                        )
                      : _SelectionBar(state: state),
                ),
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            ),
          ),
          // Hidden while picking files so it cannot collide with the delete
          // action in the selection header.
          floatingActionButton: state.selectedIds.isEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _startExcelImport(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text(AppStrings.importExcelFile),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ExcelLibraryState state) {
    if (state.status == ExcelLibraryStatus.loading && state.imports.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.imports.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        children: [
          const ExcelFormatGuideCard(),
          const SizedBox(height: 24),
          Text(
            AppStrings.excelLibraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.recallColors.mutedForeground),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: state.imports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = state.imports[index];
        final selected = state.selectedIds.contains(item.id);
        return _ImportListTile(
          import: item,
          selected: selected,
          selectionMode: state.selectedIds.isNotEmpty,
          // In selection mode a tap picks the file instead of opening it, so
          // picking several never navigates away.
          onTap: () => state.selectedIds.isEmpty
              ? _openDetail(context, item.id)
              : context.read<ExcelLibraryCubit>().toggleSelection(item.id),
          onLongPress: () =>
              context.read<ExcelLibraryCubit>().toggleSelection(item.id),
          onDelete: () => _confirmDelete(context, item),
        );
      },
    );
  }

  Future<void> _startExcelImport(BuildContext context) async {
    final proceed = await showExcelFormatGuideSheet(context);
    if (proceed && context.mounted) {
      await _pickAndSaveExcel(context);
    }
  }

  Future<void> _pickAndSaveExcel(BuildContext context) async {
    final cubit = context.read<ExcelLibraryCubit>();
    final picked = await pickExcelFiles(context);
    if (picked.isEmpty) return;

    final saved = <ExcelImport>[];
    var failed = 0;
    try {
      saved.addAll(
        await cubit.importFiles([
          for (final file in picked) (bytes: file.bytes, fileName: file.name),
        ]),
      );
      failed = picked.length - saved.length;
    } on ExcelParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
      return;
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.importFailed)),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (saved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.excelNoRows)),
      );
      return;
    }

    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.excelSomeFilesFailed(saved.length, failed)),
        ),
      );
    } else if (saved.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.excelFilesImported(saved.length))),
      );
    }

    if (saved.length == 1) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ExcelImportDetailScreen(
            importId: saved.first.id,
            spaceId: spaceId,
            initialDeckId: initialDeckId,
          ),
        ),
      );
      if (context.mounted) await cubit.load();
      return;
    }

    await cubit.load();
  }

  void _openDetail(BuildContext context, String importId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExcelImportDetailScreen(
          importId: importId,
          spaceId: spaceId,
          initialDeckId: initialDeckId,
        ),
      ),
    ).then((_) {
      if (context.mounted) context.read<ExcelLibraryCubit>().load();
    });
  }

  Future<void> _confirmDelete(BuildContext context, ExcelImport item) async {
    final ok = await showConfirmDialog(
      context,
      title: AppStrings.deleteExcelFile,
      message: AppStrings.deleteExcelFileConfirm,
    );
    if (ok == true && context.mounted) {
      await context.read<ExcelLibraryCubit>().deleteImport(item.id);
    }
  }

}

/// Header shown while files are picked for a bulk delete.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.state});

  final ExcelLibraryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ExcelLibraryCubit>();
    final count = state.selectedIds.length;

    return Row(
      children: [
        CircleIconButton(
          icon: Icons.close,
          onPressed: cubit.clearSelection,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.excelSelectedFiles(count),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count < state.imports.length
                    ? AppStrings.excelSelectAll
                    : AppStrings.excelAllSelected,
                style: TextStyle(
                  fontSize: 12,
                  color: context.recallColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        if (count < state.imports.length)
          TextButton(onPressed: cubit.selectAll, child: const Text(AppStrings.selectAll)),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: count == 0 ? null : () => _delete(context),
          icon: const Icon(Icons.delete_outline, size: 18),
          label: Text(AppStrings.delete),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size(0, 44),
          ),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ExcelLibraryCubit>();
    final count = state.selectedIds.length;
    if (count == 0) return;

    final ok = await showConfirmDialog(
      context,
      title: AppStrings.excelDeleteSelectedFiles,
      message: AppStrings.excelDeleteSelectedFilesConfirm(count),
      confirmLabel: AppStrings.delete,
    );
    if (ok != true || !context.mounted) return;

    final deleted = await cubit.deleteSelected();
    if (!context.mounted || deleted == 0) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.excelFilesDeleted(deleted))),
    );
  }
}

class _ImportListTile extends StatelessWidget {
  const _ImportListTile({
    required this.import,
    required this.onTap,
    required this.onDelete,
    required this.selected,
    required this.selectionMode,
    this.onLongPress,
  });

  final ExcelImport import;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final date = _formatDate(import.createdAt);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? context.accentColor : colors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: AppShadows.card(context),
          ),
          child: Row(
            children: [
              if (selectionMode)
                Padding(
                  padding: const EdgeInsets.only(left: 4, right: 10),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? context.accentColor
                        : colors.mutedForeground,
                    size: 22,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.table_chart_outlined,
                    color: context.accentColor,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      import.fileName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date · ${import.pendingCount} ${AppStrings.excelPending} · ${import.addedCount} ${AppStrings.excelAdded}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (!selectionMode)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                    size: 20,
                  ),
                ),
              if (!selectionMode)
                Icon(
                  Icons.chevron_right,
                  color: colors.mutedForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}