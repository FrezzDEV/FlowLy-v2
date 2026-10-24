import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowly/app.dart';
import 'package:flowly/features/player/player_controller.dart';
import 'package:flowly/features/player/draggable_player.dart';
import 'package:flowly/features/library/playlist_detail_screen.dart';
import 'package:flowly/features/library/catalog_collection_screen.dart';

void main() {
  SharedPreferences.setMockInitialValues({});
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
    expect(find.text('Популярные жанры'), findsNothing);
    expect(find.text('Найди музыку'), findsOneWidget);
  });
  testWidgets('home favorites quick tile opens the playlist screen', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    await tester.tap(find.text('Избранное').first);
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(find.text('Твои любимые треки'), findsOneWidget);
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

  testWidgets('playlists can be created and tracks added and removed', (tester) async {
    final player = PlayerController.instance;
    final playlist = await player.createPlaylist(
      'Тестовый плейлист FlowLy',
      initialTrack: PlayerController.catalog.first,
    );

    expect(playlist.name, 'Тестовый плейлист FlowLy');
    expect(playlist.tracks, hasLength(1));
    expect(playlist.tracks.single.title, PlayerController.catalog.first.title);

    final added = await player.addTrackToPlaylist(
      playlist.id,
      PlayerController.catalog[1],
    );
    expect(added, isTrue);
    expect(player.playlistById(playlist.id)!.tracks, hasLength(2));

    await player.removeTrackFromPlaylist(playlist.id, PlayerController.catalog.first);
    expect(player.playlistById(playlist.id)!.tracks, hasLength(1));
  });

  testWidgets('playlist detail screen shows banner and bulk-adds tracks to downloads', (tester) async {
    final player = PlayerController.instance;
    final playlist = await player.createPlaylist(
      'Тест загрузки всех треков',
      initialTrack: PlayerController.catalog.first,
    );
    await player.addTrackToPlaylist(
      playlist.id,
      PlayerController.catalog[1],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlaylistDetailScreen(playlistId: playlist.id)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Тест загрузки всех треков'), findsOneWidget);
    expect(find.text('Скачать все'), findsOneWidget);
    expect(find.text('Midnight Flow'), findsOneWidget);
    expect(find.text('Afterlife'), findsOneWidget);

    await tester.tap(find.text('Скачать все'));
    await tester.pumpAndSettle();

    final downloads = player.playlistById(
      PlayerController.downloadsPlaylistId,
    )!;
    expect(downloads.tracks, contains(PlayerController.catalog.first));
    expect(downloads.tracks, contains(PlayerController.catalog[1]));
  });

  testWidgets('download all is disabled when every track is already downloaded', (tester) async {
    final player = PlayerController.instance;
    await player.addTracksToPlaylist(
      PlayerController.downloadsPlaylistId,
      [PlayerController.catalog.first, PlayerController.catalog[1]],
    );
    final playlist = await player.createPlaylist(
      'Уже скачанный набор',
      initialTrack: PlayerController.catalog.first,
    );
    await player.addTrackToPlaylist(
      playlist.id,
      PlayerController.catalog[1],
    );

    await tester.pumpWidget(
      MaterialApp(home: PlaylistDetailScreen(playlistId: playlist.id)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Скачано'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Скачано'),
        matching: find.byType(FilledButton),
      ).first,
    );
    expect(button.onPressed, isNull);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('library categories open artists and albums', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.byType(CustomPaint)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Исполнители'));
    await tester.pumpAndSettle();
    expect(find.text('Ed Sheeran'), findsOneWidget);
    await tester.tap(find.text('Ed Sheeran'));
    await tester.pumpAndSettle();
    expect(find.text('Afterlife'), findsOneWidget);
    expect(find.byType(CatalogCollectionScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Альбомы'));
    await tester.pumpAndSettle();
    expect(find.text('OutRun'), findsOneWidget);
  });

  testWidgets('creating a playlist from the full player menu saves the track', (tester) async {
    final player = PlayerController.instance;
    await tester.pumpWidget(const FlowLyApp());

    await tester.tap(find.text('Midnight Flow').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Создать новый плейлист'), findsOneWidget);
    await tester.tap(find.text('Создать новый плейлист'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Создан из плеера');
    await tester.tap(find.text('Создать').last);
    await tester.pumpAndSettle();

    final playlist = player.playlists.firstWhere(
      (item) => item.name == 'Создан из плеера',
    );
    expect(playlist.tracks, contains(player.currentTrack));
  });

  testWidgets('playlist screen keeps bottom navigation and mini player visible', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    await tester.tap(find.text('Избранное').first);
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DraggableView), findsOneWidget);
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
