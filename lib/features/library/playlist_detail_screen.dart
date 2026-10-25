import 'dart:io';

import 'package:flutter/material.dart';

import '../../navigation/reveal_stagger.dart';
import '../player/player_controller.dart';
import '../player/draggable_player.dart';
import 'playlist_sheets.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    this.backButtonKey,
  });

  final String playlistId;
  final GlobalKey? backButtonKey;

  @override
  Widget build(BuildContext context) {
    final controller = PlayerController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final playlist = controller.playlistById(playlistId);
        if (playlist == null) {
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
              title: const RevealHeader(child: Text('Плейлист')),
            ),
            body: const Center(child: Text('Плейлист не найден')),
          );
        }

        final isFavorites =
            playlist.id == PlayerController.favoritesPlaylistId;
        final isDownloads =
            playlist.id == PlayerController.downloadsPlaylistId;
        final downloadsPlaylist = controller.playlistById(
          PlayerController.downloadsPlaylistId,
        )!;
        final allTracksDownloaded = playlist.tracks.isNotEmpty &&
            playlist.tracks.every(
              (track) => downloadsPlaylist.tracks.any(
                (downloaded) =>
                    downloaded.title == track.title &&
                    downloaded.artist == track.artist,
              ),
            );
        final bannerColor = isFavorites
            ? const Color(0xFF793A6D)
            : isDownloads
                ? const Color(0xFF32664E)
                : playlist.tracks.isNotEmpty
                    ? playlist.tracks.first.color
                    : const Color(0xFF275F7D);
        final bannerIcon = isFavorites
            ? Icons.favorite_rounded
            : isDownloads
                ? Icons.download_rounded
                : Icons.queue_music_rounded;

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
            title: const RevealHeader(child: Text('Плейлист')),
            centerTitle: true,
            backgroundColor: const Color(0xFF08090B),
            surfaceTintColor: Colors.transparent,
            actions: [
              if (!playlist.isSystem)
                IconButton(
                  tooltip: 'Изменить плейлист',
                  onPressed: () async {
                    await showEditPlaylistDialog(context, playlistId);
                  },
                  icon: const Icon(Icons.edit_rounded),
                ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 214,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                bannerColor,
                                Color.lerp(
                                  bannerColor,
                                  const Color(0xFF101116),
                                  .78,
                                )!,
                              ],
                            ),
                          ),
                          child: Stack(
                            children: [
                              if (playlist.coverPath != null)
                                Positioned.fill(
                                  child: Image.file(
                                    File(playlist.coverPath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              const Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x22000000),
                                        Color(0xCC000000),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -26,
                                top: -36,
                                child: Icon(
                                  bannerIcon,
                                  size: 210,
                                  color: Colors.white.withValues(alpha: .12),
                                ),
                              ),
                              Positioned(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: .13),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(bannerIcon, size: 38),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isFavorites
                                                ? 'Твои любимые треки'
                                                : isDownloads
                                                    ? 'Сохранённая музыка'
                                                    : 'Твоя подборка',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            playlist.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 25,
                                              height: 1.05,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${playlist.tracks.length} треков',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                playlist.tracks.isEmpty
                                    ? 'Пока нет треков'
                                    : 'Треки',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: playlist.tracks.isEmpty ||
                                      isDownloads ||
                                      allTracksDownloaded
                                  ? null
                                  : () async {
                                      await controller.addTracksToPlaylist(
                                        PlayerController.downloadsPlaylistId,
                                        playlist.tracks,
                                      );
                                      // No toast: the button state and downloads list
                                      // already reflect the result.
                                    },
                              icon: const Icon(Icons.download_rounded, size: 18),
                              label: Text(
                                isDownloads || allTracksDownloaded
                                    ? 'Скачано'
                                    : 'Скачать все',
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB6F36B),
                                foregroundColor: const Color(0xFF11130D),
                                disabledBackgroundColor:
                                    const Color(0xFF282A2F),
                                disabledForegroundColor: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        if (!isDownloads && playlist.tracks.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Все треки будут добавлены в список «Скачанные».',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (playlist.tracks.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(32, 12, 32, 44),
                      child: Column(
                        children: [
                          Icon(
                            Icons.queue_music_rounded,
                            size: 54,
                            color: Colors.white30,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Здесь пока пусто',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Добавляй треки через меню с тремя точками в плеере.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
                    sliver: SliverReorderableList(
                      itemCount: playlist.tracks.length,
                      onReorder: (oldIndex, newIndex) {
                        if (!playlist.isSystem) {
                          controller.reorderPlaylistTracks(
                            playlistId,
                            oldIndex,
                            newIndex,
                          );
                        }
                      },
                      itemBuilder: (context, index) {
                        final track = playlist.tracks[index];
                        final isCurrent =
                            track.title == controller.currentTrack.title &&
                            track.artist == controller.currentTrack.artist;
                        final itemId =
                            '$playlistId:${track.title}:${track.artist}';
                        final row = RevealStagger(
                          index: index,
                          child: Dismissible(
                            key: ValueKey('dismiss:$itemId'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 22),
                              color: Colors.red.withValues(alpha: .18),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                            onDismissed: (_) =>
                                controller.removeTrackFromPlaylist(
                              playlistId,
                              track,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: track.color,
                                  borderRadius: BorderRadius.circular(11),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      track.color,
                                      const Color(0xFF17181D),
                                    ],
                                  ),
                                ),
                                child: Icon(track.icon, size: 28),
                              ),
                              title: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isCurrent
                                      ? const Color(0xFFB6F36B)
                                      : Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white60),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!playlist.isSystem)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 4),
                                      child: Icon(
                                        Icons.drag_handle_rounded,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: isCurrent && controller.isPlaying
                                        ? 'Пауза'
                                        : 'Воспроизвести',
                                    icon: Icon(
                                      isCurrent && controller.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: isCurrent
                                          ? const Color(0xFFB6F36B)
                                          : Colors.white70,
                                    ),
                                    onPressed: () {
                                      if (isCurrent) {
                                        controller.togglePlay();
                                      } else {
                                        controller.playTrack(track);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                controller.playTrack(track);
                                draggablePlayerKey.currentState?.open();
                              },
                            ),
                          ),
                        );
                        if (playlist.isSystem) {
                          return KeyedSubtree(
                            key: ValueKey('row:$itemId'),
                            child: row,
                          );
                        }
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('reorder:$itemId'),
                          index: index,
                          child: row,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
