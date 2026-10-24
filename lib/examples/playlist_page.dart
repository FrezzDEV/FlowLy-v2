import 'package:flutter/material.dart';

import '../navigation/reveal_stagger.dart';

/// Небольшая модель для демонстрации: переход не зависит от модели плейлиста.
class Playlist {
  const Playlist({
    required this.name,
    required this.color,
    required this.tracks,
  });

  final String name;
  final Color color;
  final List<String> tracks;
}

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({
    super.key,
    required this.playlist,
    this.backButtonKey,
  });

  final Playlist playlist;
  final GlobalKey? backButtonKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090B),
      appBar: AppBar(
        automaticallyImplyLeading: backButtonKey == null,
        leading: backButtonKey == null
            ? null
            : RevealHeader(
                child: IconButton(
                  key: backButtonKey,
                  tooltip: 'Назад',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
        title: RevealHeader(
          child: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        backgroundColor: const Color(0xFF08090B),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          RevealHeader(
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [playlist.color, const Color(0xFF111216)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.queue_music_rounded, size: 64, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 24),
          RevealHeader(
            child: Text(
              '${playlist.tracks.length} треков',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...List<Widget>.generate(playlist.tracks.length, (index) {
            return RevealStagger(
              index: index,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: playlist.color.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: playlist.color,
                  ),
                ),
                title: Text(playlist.tracks[index]),
                subtitle: Text(playlist.name),
                trailing: const Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white70,
                  size: 28,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
