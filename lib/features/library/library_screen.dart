import 'package:flutter/material.dart';

import '../../core/storage/image_store.dart';
import '../../navigation/circle_reveal_route.dart';
import '../player/player_controller.dart';
import '../player/draggable_player.dart';
import 'catalog_collection_screen.dart';
import 'playlist_detail_screen.dart';
import 'playlist_sheets.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _category = 0;

  @override
  Widget build(BuildContext context) {
    final controller = PlayerController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final favorites = controller.playlistById(
          PlayerController.favoritesPlaylistId,
        )!;
        final downloads = controller.playlistById(
          PlayerController.downloadsPlaylistId,
        )!;
        final customPlaylists = controller.playlists
            .where((playlist) => !playlist.isSystem)
            .toList();

        final tracksByArtist = <String, List<PlayerTrack>>{};
        final tracksByAlbum = <String, List<PlayerTrack>>{};
        for (final track in PlayerController.catalog) {
          tracksByArtist.putIfAbsent(track.artist, () => []).add(track);
          tracksByAlbum.putIfAbsent(track.album, () => []).add(track);
        }
        final artists = tracksByArtist.keys.toList()..sort();
        final albums = tracksByAlbum.keys.toList()..sort();

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Text(
                'Библиотека',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _FilterChip(
                    label: 'Плейлисты',
                    selected: _category == 0,
                    onTap: () => setState(() => _category = 0),
                  ),
                  _FilterChip(
                    label: 'Исполнители',
                    selected: _category == 1,
                    onTap: () => setState(() => _category = 1),
                  ),
                  _FilterChip(
                    label: 'Альбомы',
                    selected: _category == 2,
                    onTap: () => setState(() => _category = 2),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_category == 0) ...[
                const Text(
                  'Твоя музыка',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _LibraryRow(
                  Icons.favorite_rounded,
                  const Color(0xFF7D376F),
                  favorites.name,
                  '${favorites.tracks.length} треков',
                  onTapAt: (position) => _openPlaylist(
                    context,
                    PlayerController.favoritesPlaylistId,
                    position,
                  ),
                ),
                _LibraryRow(
                  Icons.download_rounded,
                  const Color(0xFF32664E),
                  downloads.name,
                  '${downloads.tracks.length} треков',
                  onTapAt: (position) => _openPlaylist(
                    context,
                    PlayerController.downloadsPlaylistId,
                    position,
                  ),
                ),
                _LibraryRow(
                  Icons.add_rounded,
                  const Color(0xFF34383F),
                  'Добавить плейлист',
                  'Создать свою подборку',
                  onTap: () async {
                    await showCreatePlaylistDialog(context);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Мои плейлисты',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${customPlaylists.length}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                if (customPlaylists.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Созданные тобой подборки появятся здесь.',
                      style: TextStyle(color: Colors.white60, height: 1.4),
                    ),
                  ),
                for (final playlist in customPlaylists)
                  _LibraryRow(
                    Icons.queue_music_rounded,
                    playlist.tracks.isNotEmpty
                        ? playlist.tracks.first.color
                        : const Color(0xFF275F7D),
                    playlist.name,
                    '${playlist.tracks.length} треков',
                    coverPath: playlist.coverPath,
                    onTapAt: (position) =>
                        _openPlaylist(context, playlist.id, position),
                  ),
              ] else if (_category == 1) ...[
                const Text(
                  'Исполнители',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final artist in artists)
                  _LibraryRow(
                    Icons.person_rounded,
                    tracksByArtist[artist]!.first.color,
                    artist,
                    '${tracksByArtist[artist]!.length} треков',
                    onTapAt: (position) => _openCollection(
                      context,
                      artist,
                      tracksByArtist[artist]!,
                      position,
                    ),
                  ),
              ] else ...[
                const Text(
                  'Альбомы',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final album in albums)
                  _LibraryRow(
                    Icons.album_rounded,
                    tracksByAlbum[album]!.first.color,
                    album,
                    '${tracksByAlbum[album]!.length} треков · ${tracksByAlbum[album]!.first.artist}',
                    onTapAt: (position) => _openCollection(
                      context,
                      album,
                      tracksByAlbum[album]!,
                      position,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openPlaylist(
    BuildContext context,
    String playlistId,
    Offset tapPosition,
  ) {
    // Оставляем навигацию и мини-плеер в shell, но сворачиваем большой плеер.
    draggablePlayerKey.currentState?.close();
    final backButtonKey = GlobalKey();
    context.pushCircleReveal(
      page: PlaylistDetailScreen(
        playlistId: playlistId,
        backButtonKey: backButtonKey,
      ),
      tapPosition: tapPosition,
      backButtonKey: backButtonKey,
      backgroundColor: const Color(0xFF08090B),
    );
  }

  void _openCollection(
    BuildContext context,
    String title,
    List<PlayerTrack> tracks,
    Offset tapPosition,
  ) {
    final backButtonKey = GlobalKey();
    context.pushCircleReveal(
      page: CatalogCollectionScreen(
        title: title,
        tracks: tracks,
        backButtonKey: backButtonKey,
      ),
      tapPosition: tapPosition,
      backButtonKey: backButtonKey,
      backgroundColor: const Color(0xFF08090B),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Chip(
          label: Text(label),
          backgroundColor: selected
              ? const Color(0xFFB6F36B).withValues(alpha: .18)
              : const Color(0xFF1A1C20),
          side: BorderSide(
            color: selected ? const Color(0xFFB6F36B) : Colors.white12,
          ),
        ),
      );
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow(
    this.icon,
    this.color,
    this.title,
    this.subtitle, {
    this.onTap,
    this.onTapAt,
    this.coverPath,
  }) : assert(onTap != null || onTapAt != null);

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onTapAt;
  final String? coverPath;

  @override
  Widget build(BuildContext context) {
    Offset? tapPosition;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => tapPosition = details.globalPosition,
      onTap: () {
        if (onTapAt != null) {
          onTapAt!(tapPosition ?? Offset(
            MediaQuery.sizeOf(context).width / 2,
            MediaQuery.sizeOf(context).height / 2,
          ));
        } else {
          onTap?.call();
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        leading: Container(
          width: 52,
          height: 52,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: coverPath == null
              ? Icon(icon, size: 27, color: Colors.white)
              : FileImageBox(
                  path: coverPath!,
                  cacheWidth: 160,
                  fallback: Icon(icon, size: 27, color: Colors.white),
                ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
      ),
    );
  }
}
