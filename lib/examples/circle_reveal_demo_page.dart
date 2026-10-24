import 'package:flutter/material.dart';

import '../navigation/circle_reveal_route.dart';
import 'playlist_page.dart';

/// Пример использования CircleRevealRoute: сетка из пяти произвольных подборок.
class CircleRevealDemoPage extends StatelessWidget {
  const CircleRevealDemoPage({super.key});

  static const List<Playlist> playlists = [
    Playlist(
      name: 'Neon Nights',
      color: Color(0xFF8957D5),
      tracks: ['Midnight City', 'Night Drive', 'Neon Rain'],
    ),
    Playlist(
      name: 'Dawn Drive',
      color: Color(0xFF3679B9),
      tracks: ['First Light', 'Open Road', 'Blue Horizon'],
    ),
    Playlist(
      name: 'Lo-Fi Garden',
      color: Color(0xFF3D946F),
      tracks: ['Quiet Leaves', 'Soft Steps', 'Green Tea'],
    ),
    Playlist(
      name: 'After Hours',
      color: Color(0xFFC05C83),
      tracks: ['Late Call', 'Velvet Room', 'Slow Motion'],
    ),
    Playlist(
      name: 'Ocean Memories',
      color: Color(0xFF27979B),
      tracks: ['Low Tide', 'Sea Glass', 'Faraway Shore'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090B),
      appBar: AppBar(
        title: const Text('Подборки'),
        backgroundColor: const Color(0xFF08090B),
        surfaceTintColor: Colors.transparent,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .92,
        ),
        itemCount: playlists.length,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          Offset? tapPosition;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => tapPosition = details.globalPosition,
            onTap: () {
              final backButtonKey = GlobalKey();
              context.pushCircleReveal(
                page: PlaylistPage(
                  playlist: playlist,
                  backButtonKey: backButtonKey,
                ),
                tapPosition: tapPosition ??
                    Offset(
                      MediaQuery.sizeOf(context).width / 2,
                      MediaQuery.sizeOf(context).height / 2,
                    ),
                backButtonKey: backButtonKey,
                backgroundColor: const Color(0xFF08090B),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [playlist.color, const Color(0xFF121318)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.queue_music_rounded,
                    size: 34,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    playlist.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.tracks.length} треков',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
