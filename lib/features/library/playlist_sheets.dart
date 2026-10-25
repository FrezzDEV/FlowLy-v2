import 'package:flutter/material.dart';

import '../../core/storage/image_store.dart';
import '../player/player_controller.dart';
import '../player/draggable_player.dart';

Future<MusicPlaylist?> showCreatePlaylistDialog(
  BuildContext context, {
  PlayerTrack? initialTrack,
}) async {
  final name = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (_) => const _CreatePlaylistDialog(),
  );

  if (name == null || name.trim().isEmpty || !context.mounted) return null;
  return PlayerController.instance.createPlaylist(
    name,
    initialTrack: initialTrack,
  );
}

class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: const Color(0xFF191A20),
        title: const Text('Новый плейлист'),
        content: TextField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Название плейлиста',
            counterText: '',
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Создать'),
          ),
        ],
      );
}

Future<void> showSaveTrackToPlaylistSheet(
  BuildContext context,
  PlayerTrack track,
) async {
  final controller = PlayerController.instance;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (context, scrollController) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Material(
        color: const Color(0xFF17181D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
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
                // Keep the picker mounted under the dialog. The current track
                // is added as part of creation, so the new playlist is ready
                // immediately when the dialog closes.
                await showCreatePlaylistDialog(
                  context,
                  initialTrack: track,
                );
              },
            ),
            const Divider(color: Colors.white12),
            // Keep system playlists first and show the newest custom
            // playlists near the top, where they remain visible after creation.
            for (final playlist in [
              ...controller.playlists.where(
                (item) => item.id == PlayerController.favoritesPlaylistId,
              ),
              ...controller.playlists
                  .where(
                    (item) =>
                        !item.isSystem &&
                        item.id != PlayerController.downloadsPlaylistId,
                  )
                  .toList()
                  .reversed,
            ])
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
                  final alreadyInPlaylist = playlist.tracks.any(
                    (item) =>
                        item.title == track.title &&
                        item.artist == track.artist,
                  );
                  if (alreadyInPlaylist) {
                    await controller.removeTrackFromPlaylist(playlist.id, track);
                  } else {
                    await controller.addTrackToPlaylist(playlist.id, track);
                  }
                  // Keep the picker open so the same row can toggle membership.
                },
              ),
          ],
        ),
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
          return Material(
            color: const Color(0xFF17181D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            clipBehavior: Clip.antiAlias,
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
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    draggablePlayerKey.currentState?.open();
                                  });
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

/// Редактирование пользовательского плейлиста: название и обложка.
Future<void> showEditPlaylistSheet(
  BuildContext context,
  String playlistId,
) async {
  final playlist = PlayerController.instance.playlistById(playlistId);
  if (playlist == null || playlist.isSystem) return;
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditPlaylistSheet(playlistId: playlistId),
  );
}

class _EditPlaylistSheet extends StatefulWidget {
  const _EditPlaylistSheet({required this.playlistId});

  final String playlistId;

  @override
  State<_EditPlaylistSheet> createState() => _EditPlaylistSheetState();
}

class _EditPlaylistSheetState extends State<_EditPlaylistSheet> {
  final PlayerController _controller = PlayerController.instance;
  late final TextEditingController _nameController;
  late final String? _originalCover;

  /// Новая обложка, выбранная в этом окне, но ещё не сохранённая.
  String? _stagedCover;
  bool _coverRemoved = false;
  bool _saved = false;
  bool _picking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final playlist = _controller.playlistById(widget.playlistId);
    _nameController = TextEditingController(text: playlist?.name ?? '');
    _originalCover = playlist?.coverPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Закрыли окно без сохранения: выбранная копия больше не нужна.
    if (!_saved) ImageStore.delete(_stagedCover);
    super.dispose();
  }

  String? get _shownCover {
    if (_stagedCover != null) return _stagedCover;
    if (_coverRemoved) return null;
    return _originalCover;
  }

  Future<void> _pickCover() async {
    if (_picking) return;
    setState(() => _picking = true);
    final path = await pickImageWithFeedback(
      context,
      prefix: 'playlist-cover',
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (!mounted) {
      await ImageStore.delete(path);
      return;
    }
    setState(() {
      _picking = false;
      if (path != null) {
        ImageStore.delete(_stagedCover);
        _stagedCover = path;
        _coverRemoved = false;
      }
    });
  }

  void _removeCover() {
    ImageStore.delete(_stagedCover);
    setState(() {
      _stagedCover = null;
      _coverRemoved = true;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введите название');
      return;
    }
    final renamed = await _controller.renamePlaylist(widget.playlistId, name);
    if (!renamed) {
      if (!mounted) return;
      setState(() => _error = 'Плейлист с таким названием уже есть');
      return;
    }
    String? obsoleteCover;
    if (_stagedCover != null) {
      obsoleteCover = await _controller.setPlaylistCover(
        widget.playlistId,
        _stagedCover,
      );
    } else if (_coverRemoved) {
      obsoleteCover = await _controller.setPlaylistCover(
        widget.playlistId,
        null,
      );
    }
    _saved = true;
    await ImageStore.delete(obsoleteCover);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cover = _shownCover;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final placeholder = Container(
      color: const Color(0xFF282A31),
      child: const Icon(
        Icons.queue_music_rounded,
        size: 44,
        color: Colors.white54,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: const Color(0xFF17181D),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 18),
              const Text(
                'Изменить плейлист',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _pickCover,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 132,
                          height: 132,
                          child: cover == null
                              ? placeholder
                              : FileImageBox(
                                  key: ValueKey(cover),
                                  path: cover,
                                  cacheWidth: 400,
                                  fallback: placeholder,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB6F36B),
                            shape: BoxShape.circle,
                          ),
                          child: _picking
                              ? const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Color(0xFF11130D),
                                  ),
                                )
                              : const Icon(
                                  Icons.photo_camera_rounded,
                                  size: 18,
                                  color: Color(0xFF11130D),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _picking ? null : _pickCover,
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Выбрать обложку'),
                  ),
                  if (cover != null)
                    TextButton(
                      onPressed: _removeCover,
                      child: const Text('Убрать'),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'Название',
                  counterText: '',
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB6F36B),
                  foregroundColor: const Color(0xFF11130D),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
