import 'package:flutter/material.dart';

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
                  onTap: () => _openPlaylist(
                    context,
                    PlayerController.favoritesPlaylistId,
                  ),
                ),
                _LibraryRow(
                  Icons.download_rounded,
                  const Color(0xFF32664E),
                  downloads.name,
                  '${downloads.tracks.length} треков',
                  onTap: () => _openPlaylist(
                    context,
                    PlayerController.downloadsPlaylistId,
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
                    onTap: () => _openPlaylist(context, playlist.id),
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
                    onTap: () => _openCollection(
                      context,
                      artist,
                      tracksByArtist[artist]!,
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
                    onTap: () => _openCollection(
                      context,
                      album,
                      tracksByAlbum[album]!,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openPlaylist(BuildContext context, String playlistId) {
    // Enter playlist pages in the persistent app shell with the player collapsed,
    // so the bottom navigation and mini-player remain available.
    draggablePlayerKey.currentState?.close();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(playlistId: playlistId),
      ),
    );
  }

  void _openCollection(
    BuildContext context,
    String title,
    List<PlayerTrack> tracks,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CatalogCollectionScreen(title: title, tracks: tracks),
      ),
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
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 27, color: Colors.white),
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
        onTap: onTap,
      );
}
