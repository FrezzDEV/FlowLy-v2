import 'package:flutter/material.dart';

import '../player/player_controller.dart';
import 'playlist_detail_screen.dart';
import 'playlist_sheets.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
              const Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _FilterChip(label: 'Плейлисты', selected: true),
                  _FilterChip(label: 'Исполнители'),
                  _FilterChip(label: 'Альбомы'),
                ],
              ),
              const SizedBox(height: 24),
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
                  final playlist = await showCreatePlaylistDialog(context);
                  if (playlist == null || !context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Плейлист «${playlist.name}» создан'),
                    ),
                  );
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
              const SizedBox(height: 20),
              const Text(
                'Недавно прослушанное',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _LibraryRow(
                Icons.history_rounded,
                const Color(0xFF674B31),
                'История прослушивания',
                'Демо-история',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('История прослушивания появится позже'),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPlaylist(BuildContext context, String playlistId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaylistDetailScreen(playlistId: playlistId),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        backgroundColor: selected
            ? const Color(0xFFB6F36B).withValues(alpha: .18)
            : const Color(0xFF1A1C20),
        side: BorderSide(
          color: selected ? const Color(0xFFB6F36B) : Colors.white12,
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
        contentPadding: const EdgeInsets.symmetric(vertical: 5),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      );
}
