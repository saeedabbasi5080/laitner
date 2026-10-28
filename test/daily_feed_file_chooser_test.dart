import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall/core/localization/app_strings.dart';
import 'package:recall/core/theme/app_accent.dart';
import 'package:recall/core/theme/app_theme.dart';
import 'package:recall/domain/entities/excel_import.dart';
import 'package:recall/presentation/widgets/daily_excel_feed_section.dart';

final _now = DateTime(2026, 3, 1);

ExcelImport _file(String id, {int rows = 5}) => ExcelImport(
      id: id,
      spaceId: 's1',
      fileName: '$id.xlsx',
      createdAt: _now,
      rows: [
        for (var i = 0; i < rows; i++)
          ExcelImportRow(id: '$id-r$i', front: 'w$i', back: 'b$i'),
      ],
    );

void main() {
  testWidgets('the file chooser actually shows its files', (tester) async {
    // The sheet used to render blank: a Flexible holding a shrink-wrapped list
    // inside a min-size column gets no height, so every tile collapsed to
    // nothing and the user was left staring at an empty white sheet.
    final files = [_file('a'), _file('b'), _file('c')];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppAccent.lavender),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DailyFileChooserSheet(
                  imports: files,
                  selected: const {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.dailyFeedManageFiles), findsOneWidget);

    for (final file in files) {
      expect(
        find.text(file.fileName),
        findsOneWidget,
        reason: '${file.fileName} must be visible',
      );
    }
  });

  testWidgets('a long list scrolls instead of overflowing', (tester) async {
    final files = [for (var i = 0; i < 40; i++) _file('f$i')];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppAccent.lavender),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DailyFileChooserSheet(
                  imports: files,
                  selected: const {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // The sheet must not grow past the screen.
    final sheetHeight = tester.getSize(find.byType(DailyFileChooserSheet)).height;
    expect(
      sheetHeight,
      lessThanOrEqualTo(tester.view.physicalSize.height / tester.view.devicePixelRatio),
    );
  });

  testWidgets('ticking files and confirming returns their ids', (tester) async {
    List<String>? chosen;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppAccent.lavender),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                chosen = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DailyFileChooserSheet(
                    imports: [_file('a'), _file('b')],
                    selected: const {'a'},
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // "a" came in already selected, so the box is already ticked.
    await tester.tap(find.widgetWithText(CheckboxListTile, 'b.xlsx'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.done));
    await tester.pumpAndSettle();

    expect(chosen, isNotNull);
    expect(chosen, containsAll(['a', 'b']));
  });

  testWidgets('confirming with nothing ticked returns an empty list',
      (tester) async {
    List<String>? chosen;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppAccent.lavender),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                chosen = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => DailyFileChooserSheet(
                    imports: [_file('a')],
                    selected: const {},
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.done));
    await tester.pumpAndSettle();

    // An empty result, not null: clearing every file has to be possible.
    expect(chosen, isEmpty);
  });

  testWidgets('an empty library is handled by the caller, not the sheet',
      (tester) async {
    // Opening the sheet with no files would render a header and nothing else,
    // which reads as the same blank sheet. The tile refuses to open instead.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(AppAccent.lavender),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<List<String>>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const DailyFileChooserSheet(
                  imports: [],
                  selected: {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Renders without throwing, and says so rather than showing nothing.
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.dailyFeedNoFiles), findsOneWidget);
  });
}