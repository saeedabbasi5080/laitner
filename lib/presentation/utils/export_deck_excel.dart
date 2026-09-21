import 'package:flutter/material.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/data/utils/pick_excel_file.dart';
import 'package:recall/domain/usecases/export_deck_excel_usecase.dart';
import 'package:recall/injection.dart';

bool _exporting = false;

Future<void> exportDeckExcel(BuildContext context, String deckId) async {
  if (_exporting) return;
  _exporting = true;
  try {
    final exported = await sl<ExportDeckExcelUseCase>()(deckId);
    if (!context.mounted) return;
    final saved = await saveExcelFile(
      context,
      fileName: exported.fileName,
      bytes: exported.bytes,
    );
    if (!context.mounted || !saved) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.deckExcelExported)),
    );
  } on DeckExportEmptyException {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.deckExcelExportEmpty)),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.deckExcelExportFailed)),
    );
  } finally {
    _exporting = false;
  }
}
