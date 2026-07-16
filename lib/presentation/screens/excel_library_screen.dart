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

class ExcelLibraryScreen extends StatelessWidget {
  const ExcelLibraryScreen({super.key, this.initialDeckId});

  final String? initialDeckId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExcelLibraryCubit>()..load(),
      child: _ExcelLibraryView(initialDeckId: initialDeckId),
    );
  }
}

class _ExcelLibraryView extends StatelessWidget {
  const _ExcelLibraryView({this.initialDeckId});

  final String? initialDeckId;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ExcelLibraryCubit, ExcelLibraryState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
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
                            Text(
                              AppStrings.excelLibrary,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppStrings.excelLibrarySubtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildBody(context, state),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startExcelImport(context),
        icon: const Icon(Icons.upload_file),
        label: const Text(AppStrings.importExcelFile),
      ),
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
        return _ImportListTile(
          import: item,
          onTap: () => _openDetail(context, item.id),
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
    final picked = await pickExcelFile(context);
    if (picked == null) return;

    ExcelImport? import;
    try {
      import = await cubit.importFile(
        bytes: picked.bytes,
        fileName: picked.name,
      );
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

    if (import == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.excelNoRows)),
        );
      }
      return;
    }

    final savedImport = import;

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExcelImportDetailScreen(
          importId: savedImport.id,
          initialDeckId: initialDeckId,
        ),
      ),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.excelFileSaved}: ${savedImport.rows.length} ${AppStrings.cards}',
          ),
        ),
      );
      await cubit.load();
    }
  }

  void _openDetail(BuildContext context, String importId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExcelImportDetailScreen(
          importId: importId,
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

class _ImportListTile extends StatelessWidget {
  const _ImportListTile({
    required this.import,
    required this.onTap,
    required this.onDelete,
  });

  final ExcelImport import;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.recallColors;
    final date = _formatDate(import.createdAt);

    return Material(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
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
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                  size: 20,
                ),
              ),
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
