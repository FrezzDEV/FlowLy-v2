import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowly/app.dart';

void main() {
  testWidgets('FlowLy opens on home and navigation changes tabs', (tester) async {
    await tester.pumpWidget(const FlowLyApp());

    expect(find.text('Flow'), findsOneWidget);
    expect(find.text('Ly'), findsOneWidget);
    // The home feed is a lazy CustomScrollView. Assert the first section,
    // then scroll to Popular instead of expecting off-screen slivers to exist.
    expect(find.text('Недавние'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Популярное'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Популярное'), findsOneWidget);

    await tester.tap(find.text('Поиск').last);
    await tester.pumpAndSettle();
    expect(find.text('Популярные жанры'), findsOneWidget);
  });
  testWidgets('mini player opens and closes the full-screen player', (tester) async {
    await tester.pumpWidget(const FlowLyApp());

    expect(find.text('Midnight Flow'), findsOneWidget);
    await tester.tap(find.text('Midnight Flow'));
    await tester.pumpAndSettle();

    expect(find.text('СЕЙЧАС ИГРАЕТ'), findsOneWidget);
    await tester.tap(find.byTooltip('Свернуть плеер'));
    await tester.pumpAndSettle();

    expect(find.text('СЕЙЧАС ИГРАЕТ'), findsNothing);
    expect(find.text('Midnight Flow'), findsOneWidget);
  });

}
