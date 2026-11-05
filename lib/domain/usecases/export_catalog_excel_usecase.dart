import 'package:recall/data/utils/excel_encoder.dart';
import 'package:recall/domain/entities/catalog.dart';
import 'package:recall/domain/usecases/catalog_cards.dart';
import 'package:recall/domain/usecases/export_deck_excel_usecase.dart';

/// A ready-made list as an Excel file the app's own importer reads back:
/// column A the word, B the meaning, C the lesson tag. Kept offline, it can be
/// imported later from the Excel library, or opened anywhere else.
class ExportCatalogExcelUseCase {
  const ExportCatalogExcelUseCase();

  ExportedDeckExcel call(CatalogWordList list, {CatalogCardOptions options = const CatalogCardOptions()}) {
    final rows = catalogCardRows(list.lessons, options);
    if (rows.isEmpty) throw const DeckExportEmptyException();
    return ExportedDeckExcel(
      fileName: ExcelWorkbookEncoder.fileNameForDeck(list.node.title),
      bytes: ExcelWorkbookEncoder.encodeKeyValue(rows),
    );
  }
}
