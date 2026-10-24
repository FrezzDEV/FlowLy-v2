import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowly/app.dart';
import 'package:flowly/features/player/player_controller.dart';

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

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.search_rounded),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Популярные жанры'), findsOneWidget);
  });
  testWidgets('playback timer advances and pause freezes it', (tester) async {
    final player = PlayerController.instance;
    if (player.isPlaying) player.togglePlay();
    player.seek(0);

    player.togglePlay();
    await tester.pump(const Duration(seconds: 2));
    final advancedPosition = player.position;
    expect(advancedPosition.inSeconds, greaterThan(0));

    player.togglePlay();
    final pausedPosition = player.position;
    await tester.pump(const Duration(seconds: 2));
    expect(player.position, pausedPosition);
    expect(player.isPlaying, isFalse);
  });

  testWidgets('mini player opens and closes the full-screen player', (tester) async {
    await tester.pumpWidget(const FlowLyApp());

    expect(find.text('Midnight Flow'), findsWidgets);
    await tester.tap(find.text('Midnight Flow').first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.text('Midnight Flow'), findsWidgets);
  });

}
