import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowly/app.dart';
import 'package:flowly/features/player/player_controller.dart';
import 'package:flowly/features/player/draggable_player.dart';
import 'package:flowly/features/library/playlist_detail_screen.dart';
import 'package:flowly/features/library/catalog_collection_screen.dart';
import 'package:flowly/features/library/library_screen.dart';
import 'package:flowly/features/profile/profile_screen.dart';
import 'package:flowly/examples/circle_reveal_demo_page.dart';
import 'package:flowly/examples/playlist_page.dart';

Future<void> pumpPlayerUi(WidgetTester tester) async {
  // The expanded player deliberately owns a continuously ticking playback clock,
  // so pumpAndSettle would wait forever while a track is playing. Pump explicit
  // frames so controller animations advance deterministically without settling.
  for (var i = 0; i < 24; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

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
  testWidgets('profile settings menu offers settings, editor and share', (tester) async {
    await tester.pumpWidget(const FlowLyApp());

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.byIcon(Icons.person_outline_rounded),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Настройки профиля'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Карандаш'), findsOneWidget);
    expect(find.text('Поделиться профилем'), findsOneWidget);

    await tester.tap(find.text('Карандаш'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileEditorScreen), findsOneWidget);
    expect(find.text('Предпросмотр профиля'), findsOneWidget);
    final editorScrollable = find.descendant(
      of: find.byType(ProfileEditorScreen),
      matching: find.byType(Scrollable),
    ).first;

    await tester.scrollUntilVisible(
      find.text('Аватарка'),
      260,
      scrollable: editorScrollable,
    );
    expect(find.text('Аватарка'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Витрина профиля'),
      260,
      scrollable: editorScrollable,
    );
    expect(find.text('Витрина профиля'), findsOneWidget);
    expect(find.text('Добавить контент'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Рамка аватарки'),
      260,
      scrollable: editorScrollable,
    );
    expect(find.text('Рамка аватарки'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Показывать плейлисты'),
      260,
      scrollable: editorScrollable,
    );
    for (final label in [
      'Показывать плейлисты',
      'Показывать треки',
      'Показывать альбомы',
      'Показывать авторов',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        180,
        scrollable: editorScrollable,
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('home favorites quick tile opens the playlist screen', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    await tester.tap(find.text('Избранное').first);
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(find.text('Твои любимые треки'), findsOneWidget);
  });

  testWidgets('tapping the currently playing track pauses and resumes it', (tester) async {
    final player = PlayerController.instance;
    if (player.isPlaying) player.togglePlay();

    final current = player.currentTrack;
    final track = PlayerController.catalog.firstWhere(
      (item) => item.title != current.title || item.artist != current.artist,
    );
    player.playTrack(track);
    expect(player.isPlaying, isTrue);

    player.seek(0.4);
    player.playTrack(track);
    expect(player.isPlaying, isFalse);
    expect(player.progress, closeTo(0.4, 0.02));

    player.playTrack(track);
    expect(player.isPlaying, isTrue);
    expect(player.progress, closeTo(0.4, 0.02));
    player.togglePlay();
  });

  testWidgets('profile accent defaults to white', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    expect(Theme.of(tester.element(find.byType(Scaffold).first)).colorScheme.primary,
        const Color(0xFFF5F5F5));
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

  testWidgets('custom playlists support editing and track reordering', (tester) async {
    final player = PlayerController.instance;
    final playlist = await player.createPlaylist(
      'Плейлист для изменения и порядка',
      initialTrack: PlayerController.catalog[0],
    );
    await player.addTracksToPlaylist(
      playlist.id,
      [PlayerController.catalog[1], PlayerController.catalog[2]],
    );

    await player.reorderPlaylistTracks(playlist.id, 0, 3);
    expect(
      player.playlistById(playlist.id)!.tracks.map((track) => track.title),
      [
        PlayerController.catalog[1].title,
        PlayerController.catalog[2].title,
        PlayerController.catalog[0].title,
      ],
    );

    final updated = await player.updatePlaylistDetails(
      playlist.id,
      name: 'Новое имя плейлиста',
      coverPath: '/test/playlist-cover.png',
    );
    expect(updated, isTrue);
    expect(player.playlistById(playlist.id)!.name, 'Новое имя плейлиста');
    expect(
      player.playlistById(playlist.id)!.coverPath,
      '/test/playlist-cover.png',
    );
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
    expect(find.text('Ed Sheeran'), findsWidgets);
    await tester.tap(find.text('Ed Sheeran').first);
    await tester.pumpAndSettle();
    expect(find.text('Afterlife'), findsWidgets);
    expect(find.byType(CatalogCollectionScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Альбомы'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('OutRun'),
      220,
      scrollable: find.descendant(
        of: find.byType(LibraryScreen),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('OutRun'), findsOneWidget);
  });

  testWidgets('creating a playlist from the full player menu saves the track', (tester) async {
    final player = PlayerController.instance;
    await tester.pumpWidget(const FlowLyApp());

    if (player.currentTrack.title != PlayerController.catalog.first.title) {
      player.playTrack(PlayerController.catalog.first);
    }
    unawaited(draggablePlayerKey.currentState?.close());
    await pumpPlayerUi(tester);
    unawaited(draggablePlayerKey.currentState?.open());
    await pumpPlayerUi(tester);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await pumpPlayerUi(tester);

    expect(find.text('Создать новый плейлист'), findsOneWidget);
    await tester.tap(find.text('Создать новый плейлист'));
    await pumpPlayerUi(tester);

    await tester.enterText(find.byType(TextField).last, 'Создан из плеера');
    await tester.tap(find.text('Создать').last);
    await pumpPlayerUi(tester);

    // Creation from the large player should keep the picker open and reveal
    // the new playlist row after scrolling to the bottom of the list.
    expect(find.text('Сохранить в плейлист'), findsOneWidget);
    expect(find.text('Создан из плеера'), findsOneWidget);

    final playlist = player.playlists.firstWhere(
      (item) => item.name == 'Создан из плеера',
    );
    expect(playlist.tracks, contains(player.currentTrack));
    if (player.isPlaying) player.togglePlay();
  });

  testWidgets('playlist screen keeps bottom navigation and mini player visible', (tester) async {
    await tester.pumpWidget(const FlowLyApp());
    await tester.tap(find.text('Избранное').first);
    await tester.pumpAndSettle();

    expect(find.byType(PlaylistDetailScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DraggableView), findsOneWidget);
    expect(draggablePlayerKey.currentState?.isOpen, isFalse);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
  });

  testWidgets('playlist picker stays open and toggles track membership', (tester) async {
    final player = PlayerController.instance;
    await tester.pumpWidget(const FlowLyApp());
    unawaited(draggablePlayerKey.currentState?.close());
    await pumpPlayerUi(tester);
    await player.removeTrackFromPlaylist(
      PlayerController.favoritesPlaylistId,
      player.currentTrack,
    );
    unawaited(draggablePlayerKey.currentState?.open());
    await pumpPlayerUi(tester);
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await pumpPlayerUi(tester);

    expect(find.text('Сохранить в плейлист'), findsOneWidget);
    // Downloads remains available in the library, but not as a save target.
    expect(
      find.descendant(
        of: find.byType(DraggableScrollableSheet).first,
        matching: find.widgetWithText(ListTile, 'Скачанные'),
      ),
      findsNothing,
    );
    await tester.tap(find.text('Избранное').last);
    await pumpPlayerUi(tester);
    expect(find.text('Сохранить в плейлист'), findsOneWidget);
    expect(
      player.playlistById(PlayerController.favoritesPlaylistId)!.tracks,
      contains(player.currentTrack),
    );

    await tester.tap(find.text('Избранное').last);
    await pumpPlayerUi(tester);
    expect(find.text('Сохранить в плейлист'), findsOneWidget);
    expect(
      player.playlistById(PlayerController.favoritesPlaylistId)!.tracks,
      isNot(contains(player.currentTrack)),
    );
    expect(find.byType(SnackBar), findsNothing);
    if (player.isPlaying) player.togglePlay();
  });

  testWidgets('tapping any part of the mini player opens the full player', (tester) async {
    final player = PlayerController.instance;
    await tester.pumpWidget(const FlowLyApp());
    await tester.pumpAndSettle();

    // Tap the album art edge rather than the title or transport buttons.
    await tester.tapAt(const Offset(20, 500));
    await pumpPlayerUi(tester);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    if (player.isPlaying) player.togglePlay();
  });

  testWidgets('circular reveal demo opens the selected playlist and exits', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CircleRevealDemoPage()));

    expect(find.text('Neon Nights'), findsOneWidget);
    expect(find.text('Dawn Drive'), findsOneWidget);
    expect(find.byType(PlaylistPage), findsNothing);

    await tester.tap(find.text('Dawn Drive'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistPage), findsOneWidget);

    expect(find.text('First Light'), findsOneWidget);
    expect(find.byType(IconButton).evaluate().any(
      (element) => (element.widget as IconButton).key != null,
    ), isTrue);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(PlaylistPage), findsNothing);
    expect(find.text('Подборки'), findsOneWidget);
  });

  testWidgets('mini player opens and closes the full-screen player', (tester) async {
    final player = PlayerController.instance;
    if (player.currentTrack.title != PlayerController.catalog.first.title) {
      player.playTrack(PlayerController.catalog.first);
    }
    await tester.pumpWidget(const FlowLyApp());
    unawaited(draggablePlayerKey.currentState?.close());
    await pumpPlayerUi(tester);

    final miniTitle = find.byKey(
      const ValueKey('mini-title-label'),
    );
    expect(miniTitle, findsOneWidget);
    await tester.tap(miniTitle);
    await pumpPlayerUi(tester);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await pumpPlayerUi(tester);

    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.byKey(const ValueKey('mini-title-Midnight Flow')), findsOneWidget);
    if (player.isPlaying) player.togglePlay();
  });

}
