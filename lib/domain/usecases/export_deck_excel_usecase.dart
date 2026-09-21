import 'dart:typed_data';

import 'package:recall/data/utils/excel_encoder.dart';
import 'package:recall/domain/usecases/get_cards_by_deck_usecase.dart';
import 'package:recall/domain/usecases/get_deck_usecase.dart';

class DeckExportEmptyException implements Exception {
  const DeckExportEmptyException();
}

class DeckExportNotFoundException implements Exception {
  const DeckExportNotFoundException();
}

class ExportedDeckExcel {
  const ExportedDeckExcel({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

class ExportDeckExcelUseCase {
  ExportDeckExcelUseCase({
    required GetDeckUseCase getDeckUseCase,
    required GetCardsByDeckUseCase getCardsByDeckUseCase,
  })  : _getDeckUseCase = getDeckUseCase,
        _getCardsByDeckUseCase = getCardsByDeckUseCase;

  final GetDeckUseCase _getDeckUseCase;
  final GetCardsByDeckUseCase _getCardsByDeckUseCase;

  Future<ExportedDeckExcel> call(String deckId) async {
    final deck = await _getDeckUseCase(deckId);
    if (deck == null) throw const DeckExportNotFoundException();

    final cards = [...await _getCardsByDeckUseCase(deckId)]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final rows = <({String front, String back})>[];
    for (final card in cards) {
      final front = card.front.trim();
      final back = card.back.trim();
      if (front.isEmpty || back.isEmpty) continue;
      rows.add((front: front, back: back));
    }

    if (rows.isEmpty) throw const DeckExportEmptyException();

    return ExportedDeckExcel(
      fileName: ExcelWorkbookEncoder.fileNameForDeck(deck.name),
      bytes: ExcelWorkbookEncoder.encodeKeyValue(rows),
    );
  }
}
