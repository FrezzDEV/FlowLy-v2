import 'package:flutter/material.dart';

import '../player/player_controller.dart';

Future<MusicPlaylist?> showCreatePlaylistDialog(
  BuildContext context, {
  PlayerTrack? initialTrack,
}) async {
  final nameController = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF191A20),
      title: const Text('Новый плейлист'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 40,
        decoration: const InputDecoration(
          hintText: 'Название плейлиста',
          counterText: '',
        ),
        onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(nameController.text),
          child: const Text('Создать'),
        ),
      ],
    ),
  );
  nameController.dispose();

  if (name == null || name.trim().isEmpty || !context.mounted) return null;
  return PlayerController.instance.createPlaylist(
    name,
    initialTrack: initialTrack,
  );
}

Future<void> showSaveTrackToPlaylistSheet(
  BuildContext context,
  PlayerTrack track,
) async {
  final controller = PlayerController.instance;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF17181D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Сохранить в плейлист',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFB6F36B).withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.add_rounded, color: Color(0xFFB6F36B)),
              ),
              title: const Text('Создать новый плейлист'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final playlist = await showCreatePlaylistDialog(
                  context,
                  initialTrack: track,
                );
                if (playlist != null && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Трек добавлен в «${playlist.name}»'),
                    ),
                  );
                }
              },
            ),
            const Divider(color: Colors.white12),
            for (final playlist in controller.playlists.where(
              (item) => item.id != PlayerController.downloadsPlaylistId,
            ))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: playlist.id == PlayerController.favoritesPlaylistId
                        ? const Color(0xFF793A6D)
                        : const Color(0xFF282A31),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    playlist.id == PlayerController.favoritesPlaylistId
                        ? Icons.favorite_rounded
                        : Icons.queue_music_rounded,
                  ),
                ),
                title: Text(playlist.name),
                subtitle: Text('${playlist.tracks.length} треков'),
                trailing: Icon(
                  playlist.tracks.any(
                    (item) =>
                        item.title == track.title &&
                        item.artist == track.artist,
                  )
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  color: const Color(0xFFB6F36B),
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  final added = await controller.addTrackToPlaylist(
                    playlist.id,
                    track,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        added
                            ? 'Добавлено в «${playlist.name}»'
                            : 'Этот трек уже есть в «${playlist.name}»',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showPlaylistDetailsSheet(
  BuildContext context,
  String playlistId,
) async {
  final controller = PlayerController.instance;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.74,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      builder: (context, scrollController) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final playlist = controller.playlistById(playlistId);
          if (playlist == null) return const SizedBox.shrink();
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFF17181D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${playlist.tracks.length} треков',
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Закрыть',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: playlist.tracks.isEmpty
                      ? ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(28),
                          children: const [
                            SizedBox(height: 30),
                            Icon(
                              Icons.queue_music_rounded,
                              size: 52,
                              color: Colors.white38,
                            ),
                            SizedBox(height: 14),
                            Center(
                              child: Text(
                                'Плейлист пока пуст',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            SizedBox(height: 6),
                            Center(
                              child: Text(
                                'Добавляйте сюда треки через меню плеера.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: playlist.tracks.length,
                          itemBuilder: (context, index) {
                            final track = playlist.tracks[index];
                            return Dismissible(
                              key: ValueKey(
                                '$playlistId:${track.title}:${track.artist}',
                              ),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 22),
                                color: Colors.red.withValues(alpha: .2),
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
                                leading: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: track.color,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(track.icon),
                                ),
                                title: Text(track.title),
                                subtitle: Text(track.artist),
                                onTap: () {
                                  controller.playTrack(track);
                                  Navigator.of(sheetContext).pop();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
