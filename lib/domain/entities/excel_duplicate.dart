import 'package:equatable/equatable.dart';
import 'package:recall/domain/entities/duplicate_card.dart';
import 'package:recall/domain/entities/excel_import.dart';

/// Why a pending Excel row cannot be added.
///
/// Scoped to the row's own space: a word that already lives in a different
/// space is unrelated and never counts as a duplicate here.
enum ExcelDuplicateKind {
  /// The front text already exists as a card in this space.
  existingCard,

  /// An earlier pending row in the same file has the same front text, so only
  /// the first occurrence can be added.
  withinFile,
}

/// A pending row that duplicates something and the reason why.
class ExcelRowDuplicate extends Equatable {
  const ExcelRowDuplicate({
    required this.rowId,
    required this.front,
    required this.kind,
    this.deckName,
    this.duplicateRowId,
  });

  final String rowId;
  final String front;
  final ExcelDuplicateKind kind;

  /// Deck holding the existing card; only set for [ExcelDuplicateKind.existingCard].
  final String? deckName;

  /// The earlier row in this file that already claims the same front text;
  /// only set for [ExcelDuplicateKind.withinFile].
  final String? duplicateRowId;

  @override
  List<Object?> get props => [
        rowId,
        front,
        kind,
        deckName,
        duplicateRowId,
      ];
}

/// Pure duplicate analysis for an Excel import's pending rows.
///
/// Kept free of repositories so the ordering rules — which of two identical
/// rows wins — are directly testable, and so the same rules can back both the
/// row badges and the add-time guard in `AddSelectedExcelRowsUseCase`.
class ExcelDuplicateAnalysis {
  const ExcelDuplicateAnalysis();

  /// Flags pending rows that clash with a card already in the space, or with an
  /// earlier pending row in the same file.
  ///
  /// [existingCards] must already be limited to the row's space, and
  /// [deckNames] maps those cards' deck ids to display names.
  List<ExcelRowDuplicate> findDuplicates({
    required ExcelImport import,
    required List<DuplicateCardMatch> existingCards,
    required Map<String, String> deckNames,
  }) {
    final existingByFront = <String, String>{};
    for (final match in existingCards) {
      // First match wins so a word duplicated across two decks is reported
      // against one of them rather than flickering between them.
      existingByFront.putIfAbsent(
        normalizeCardFront(match.card.front),
        () => deckNames[match.card.deckId] ?? match.deckName,
      );
    }

    final duplicates = <ExcelRowDuplicate>[];
    final claimedByRow = <String, String>{};

    for (final row in import.rows) {
      if (row.isAdded) continue;

      final front = row.front.trim();
      final key = normalizeCardFront(front);
      if (key.isEmpty) continue;

      final existingDeck = existingByFront[key];
      if (existingDeck != null) {
        duplicates.add(
          ExcelRowDuplicate(
            rowId: row.id,
            front: front,
            kind: ExcelDuplicateKind.existingCard,
            deckName: existingDeck,
          ),
        );
        continue;
      }

      final earlierRowId = claimedByRow[key];
      if (earlierRowId != null) {
        duplicates.add(
          ExcelRowDuplicate(
            rowId: row.id,
            front: front,
            kind: ExcelDuplicateKind.withinFile,
            duplicateRowId: earlierRowId,
          ),
        );
        continue;
      }

      claimedByRow[key] = row.id;
    }

    return duplicates;
  }
}