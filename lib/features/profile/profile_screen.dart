import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/local_image_storage.dart';
import '../../core/theme/flowly_accent.dart';
import '../player/player_controller.dart';

const _profileBackground = Color(0xFF08090B);
const _profileMuted = Color(0xFF9B9DA4);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.backButtonKey});

  final GlobalKey? backButtonKey;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _nameKey = 'flowly.profile.name';
  static const _usernameKey = 'flowly.profile.username';
  static const _avatarKey = 'flowly.profile.avatar';
  static const _bannerKey = 'flowly.profile.banner';
  static const _avatarScaleKey = 'flowly.profile.avatar.scale';
  static const _avatarXKey = 'flowly.profile.avatar.x';
  static const _avatarYKey = 'flowly.profile.avatar.y';
  static const _bannerScaleKey = 'flowly.profile.banner.scale';
  static const _bannerXKey = 'flowly.profile.banner.x';
  static const _bannerYKey = 'flowly.profile.banner.y';
  static const _frameKey = 'flowly.profile.avatar.frame';
  static const _showPlaylistsKey = 'flowly.profile.showPlaylists';
  static const _showTracksKey = 'flowly.profile.showTracks';
  static const _showAlbumsKey = 'flowly.profile.showAlbums';
  static const _showArtistsKey = 'flowly.profile.showArtists';

  String _name = 'Слушатель FlowLy';
  String _username = 'flowly_listener';
  String? _avatarPath;
  String? _bannerPath;
  double _avatarScale = 1;
  double _avatarX = 0;
  double _avatarY = 0;
  double _bannerScale = 1;
  double _bannerX = 0;
  double _bannerY = 0;
  String _frameStyle = 'none';
  bool _showPlaylists = true;
  bool _showTracks = true;
  bool _showAlbums = true;
  bool _showArtists = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _name = preferences.getString(_nameKey) ?? _name;
        _username = preferences.getString(_usernameKey) ?? _username;
        _avatarPath = preferences.getString(_avatarKey);
        _bannerPath = preferences.getString(_bannerKey);
        _avatarScale = preferences.getDouble(_avatarScaleKey) ?? _avatarScale;
        _avatarX = preferences.getDouble(_avatarXKey) ?? _avatarX;
        _avatarY = preferences.getDouble(_avatarYKey) ?? _avatarY;
        _bannerScale = preferences.getDouble(_bannerScaleKey) ?? _bannerScale;
        _bannerX = preferences.getDouble(_bannerXKey) ?? _bannerX;
        _bannerY = preferences.getDouble(_bannerYKey) ?? _bannerY;
        _frameStyle = preferences.getString(_frameKey) ?? _frameStyle;
        _showPlaylists =
            preferences.getBool(_showPlaylistsKey) ?? _showPlaylists;
        _showTracks = preferences.getBool(_showTracksKey) ?? _showTracks;
        _showAlbums = preferences.getBool(_showAlbumsKey) ?? _showAlbums;
        _showArtists = preferences.getBool(_showArtistsKey) ?? _showArtists;
      });
    } catch (_) {
      // The local demo profile remains usable without a platform preference store.
    }
  }

  Future<void> _editProfile() async {
    final result = await Navigator.of(context).push<_ProfileEditResult>(
      PageRouteBuilder<_ProfileEditResult>(
        pageBuilder: (_, __, ___) => ProfileEditorScreen(
          initialName: _name,
          initialUsername: _username,
          avatarPath: _avatarPath,
          bannerPath: _bannerPath,
          avatarScale: _avatarScale,
          avatarX: _avatarX,
          avatarY: _avatarY,
          bannerScale: _bannerScale,
          bannerX: _bannerX,
          bannerY: _bannerY,
          frameStyle: _frameStyle,
          initialAccentColor: FlowLyAccent.color,
          showPlaylists: _showPlaylists,
          showTracks: _showTracks,
          showAlbums: _showAlbums,
          showArtists: _showArtists,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        transitionsBuilder: (_, __, ___, child) => child,
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _name = result.name;
      _username = result.username;
      _avatarPath = result.avatarPath;
      _bannerPath = result.bannerPath;
      _avatarScale = result.avatarScale;
      _avatarX = result.avatarX;
      _avatarY = result.avatarY;
      _bannerScale = result.bannerScale;
      _bannerX = result.bannerX;
      _bannerY = result.bannerY;
      _frameStyle = result.frameStyle;
      _showPlaylists = result.showPlaylists;
      _showTracks = result.showTracks;
      _showAlbums = result.showAlbums;
      _showArtists = result.showArtists;
    });
    await FlowLyAccent.setColor(result.accentColor);

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_nameKey, _name);
      await preferences.setString(_usernameKey, _username);
      await _writeOptionalString(preferences, _avatarKey, _avatarPath);
      await _writeOptionalString(preferences, _bannerKey, _bannerPath);
      await preferences.setDouble(_avatarScaleKey, _avatarScale);
      await preferences.setDouble(_avatarXKey, _avatarX);
      await preferences.setDouble(_avatarYKey, _avatarY);
      await preferences.setDouble(_bannerScaleKey, _bannerScale);
      await preferences.setDouble(_bannerXKey, _bannerX);
      await preferences.setDouble(_bannerYKey, _bannerY);
      await preferences.setString(_frameKey, _frameStyle);
      await preferences.setBool(_showPlaylistsKey, _showPlaylists);
      await preferences.setBool(_showTracksKey, _showTracks);
      await preferences.setBool(_showAlbumsKey, _showAlbums);
      await preferences.setBool(_showArtistsKey, _showArtists);
    } catch (_) {
      // The profile continues to reflect edits for this session.
    }
  }

  Future<void> _writeOptionalString(
    SharedPreferences preferences,
    String key,
    String? value,
  ) async {
    if (value == null) {
      await preferences.remove(key);
    } else {
      await preferences.setString(key, value);
    }
  }

  Color _frameColor(String style) {
    switch (style) {
      case 'lime':
        return const Color(0xFFB6F36B);
      case 'violet':
        return const Color(0xFFB28BFF);
      case 'blue':
        return const Color(0xFF73C9FF);
      case 'gold':
        return const Color(0xFFFFC66D);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = PlayerController.instance;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            Row(
              children: [
                if (widget.backButtonKey != null)
                  IconButton(
                    key: widget.backButtonKey,
                    tooltip: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  )
                else
                  const SizedBox(width: 48, height: 48),
                const Spacer(),
                IconButton(
                  tooltip: 'Редактировать профиль',
                  onPressed: _editProfile,
                  icon: Icon(
                    Icons.edit_rounded,
                    size: 25,
                    color: FlowLyAccent.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: player,
                builder: (context, _) {
                  final customPlaylists =
                      player.playlists.where((item) => !item.isSystem).toList();
                  final albumsByName = <String, PlayerTrack>{};
                  final artistsByName = <String, PlayerTrack>{};
                  for (final track in PlayerController.catalog) {
                    albumsByName.putIfAbsent(track.album, () => track);
                    artistsByName.putIfAbsent(track.artist, () => track);
                  }
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 28),
                    children: [
                      SizedBox(
                        height: 206,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 158,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: _CropTransformImage(
                                  path: _bannerPath,
                                  scale: _bannerScale,
                                  offsetX: _bannerX,
                                  offsetY: _bannerY,
                                  placeholder: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF345B56),
                                          Color(0xFF263047),
                                          Color(0xFF15171E),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 108,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _SocialCount(
                                      value: '0',
                                      label: 'подписчиков',
                                    ),
                                  ),
                                  Container(
                                    width: 108,
                                    height: 108,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _profileBackground,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _frameColor(_frameStyle),
                                        width: _frameStyle == 'none' ? 0 : 3,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _CropTransformImage(
                                        path: _avatarPath,
                                        scale: _avatarScale,
                                        offsetX: _avatarX,
                                        offsetY: _avatarY,
                                        placeholder: const ColoredBox(
                                          color: Color(0xFF24272B),
                                          child: Center(
                                            child: Icon(
                                              Icons.person_rounded,
                                              size: 44,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _SocialCount(
                                      value: '0',
                                      label: 'подписок',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.3,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '@$_username',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_showPlaylists)
                        _ProfileSection(
                          title: 'Плейлисты',
                          emptyText: 'Созданные плейлисты появятся здесь.',
                          isEmpty: customPlaylists.isEmpty,
                          children: [
                            for (final playlist in customPlaylists)
                              _ProfileContentRow(
                                icon: Icons.queue_music_rounded,
                                title: playlist.name,
                                subtitle: '${playlist.tracks.length} треков',
                                color: playlist.tracks.isEmpty
                                    ? const Color(0xFF275F7D)
                                    : playlist.tracks.first.color,
                                imagePath: playlist.coverPath,
                              ),
                          ],
                        ),
                      if (_showTracks)
                        _ProfileSection(
                          title: 'Треки',
                          emptyText: 'Треки пока не добавлены.',
                          isEmpty: PlayerController.catalog.isEmpty,
                          children: [
                            for (final track
                                in PlayerController.catalog.take(5))
                              _ProfileContentRow(
                                icon: track.icon,
                                title: track.title,
                                subtitle: track.artist,
                                color: track.color,
                                onTap: () => player.playTrack(track),
                              ),
                          ],
                        ),
                      if (_showAlbums)
                        _ProfileSection(
                          title: 'Альбомы',
                          emptyText: 'Альбомы не найдены.',
                          isEmpty: albumsByName.isEmpty,
                          children: [
                            for (final entry in albumsByName.entries)
                              _ProfileContentRow(
                                icon: Icons.album_rounded,
                                title: entry.key,
                                subtitle: entry.value.artist,
                                color: entry.value.color,
                                onTap: () => player.playTrack(entry.value),
                              ),
                          ],
                        ),
                      if (_showArtists)
                        _ProfileSection(
                          title: 'Авторы',
                          emptyText: 'Авторы не найдены.',
                          isEmpty: artistsByName.isEmpty,
                          children: [
                            for (final entry in artistsByName.entries)
                              _ProfileContentRow(
                                icon: Icons.person_rounded,
                                title: entry.key,
                                subtitle: 'Исполнитель',
                                color: entry.value.color,
                                onTap: () => player.playTrack(entry.value),
                              ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialCount extends StatelessWidget {
  const _SocialCount({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: _profileMuted, fontSize: 11),
          ),
        ],
      );
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
    required this.emptyText,
    required this.isEmpty,
  });

  final String title;
  final List<Widget> children;
  final String emptyText;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  emptyText,
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            else
              ...children,
          ],
        ),
      );
}

class _ProfileContentRow extends StatelessWidget {
  const _ProfileContentRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.imagePath,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? imagePath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .45),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: imagePath == null
              ? Icon(icon, color: Colors.white)
              : Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(icon),
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
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        trailing: onTap == null
            ? null
            : const Icon(Icons.play_arrow_rounded, color: Colors.white38),
      );
}

class _ProfileEditResult {
  const _ProfileEditResult({
    required this.name,
    required this.username,
    required this.avatarPath,
    required this.bannerPath,
    required this.avatarScale,
    required this.avatarX,
    required this.avatarY,
    required this.bannerScale,
    required this.bannerX,
    required this.bannerY,
    required this.frameStyle,
    required this.accentColor,
    required this.showPlaylists,
    required this.showTracks,
    required this.showAlbums,
    required this.showArtists,
  });

  final String name;
  final String username;
  final String? avatarPath;
  final String? bannerPath;
  final double avatarScale;
  final double avatarX;
  final double avatarY;
  final double bannerScale;
  final double bannerX;
  final double bannerY;
  final String frameStyle;
  final Color accentColor;
  final bool showPlaylists;
  final bool showTracks;
  final bool showAlbums;
  final bool showArtists;
}

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({
    super.key,
    required this.initialName,
    required this.initialUsername,
    required this.avatarPath,
    required this.bannerPath,
    required this.avatarScale,
    required this.avatarX,
    required this.avatarY,
    required this.bannerScale,
    required this.bannerX,
    required this.bannerY,
    required this.frameStyle,
    required this.initialAccentColor,
    required this.showPlaylists,
    required this.showTracks,
    required this.showAlbums,
    required this.showArtists,
  });

  final String initialName;
  final String initialUsername;
  final String? avatarPath;
  final String? bannerPath;
  final double avatarScale;
  final double avatarX;
  final double avatarY;
  final double bannerScale;
  final double bannerX;
  final double bannerY;
  final String frameStyle;
  final Color initialAccentColor;
  final bool showPlaylists;
  final bool showTracks;
  final bool showAlbums;
  final bool showArtists;

  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.initialName);
  late final TextEditingController _usernameController =
      TextEditingController(text: widget.initialUsername);
  late String? _avatarPath = widget.avatarPath;
  late String? _bannerPath = widget.bannerPath;
  late double _avatarScale = widget.avatarScale.clamp(1.0, 4.0).toDouble();
  late double _avatarX = widget.avatarX;
  late double _avatarY = widget.avatarY;
  late double _bannerScale = widget.bannerScale.clamp(1.0, 4.0).toDouble();
  late double _bannerX = widget.bannerX;
  late double _bannerY = widget.bannerY;
  late String _frameStyle = widget.frameStyle;
  late Color _accentColor = widget.initialAccentColor;
  late bool _showPlaylists = widget.showPlaylists;
  late bool _showTracks = widget.showTracks;
  late bool _showAlbums = widget.showAlbums;
  late bool _showArtists = widget.showArtists;
  String? _validationError;
  String? _imageError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<_CropSelection?> _openCropper(
    String path, {
    required bool isAvatar,
  }) =>
      Navigator.of(context).push<_CropSelection>(
        PageRouteBuilder<_CropSelection>(
          pageBuilder: (_, __, ___) => _ImageCropScreen(
            path: path,
            isAvatar: isAvatar,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, __, ___, child) => child,
        ),
      );

  Future<void> _chooseAvatar() async {
    try {
      final path = await LocalImageStorage.pickAndPersistImage(folder: 'profile');
      if (path == null || !mounted) return;
      final crop = await _openCropper(path, isAvatar: true);
      if (crop == null || !mounted) return;
      setState(() {
        _avatarPath = path;
        _avatarScale = crop.scale;
        _avatarX = crop.offsetX;
        _avatarY = crop.offsetY;
        _imageError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _imageError = 'Не удалось открыть или обрезать фото.');
    }
  }

  Future<void> _chooseBanner() async {
    try {
      final path = await LocalImageStorage.pickAndPersistImage(folder: 'profile');
      if (path == null || !mounted) return;
      final crop = await _openCropper(path, isAvatar: false);
      if (crop == null || !mounted) return;
      setState(() {
        _bannerPath = path;
        _bannerScale = crop.scale;
        _bannerX = crop.offsetX;
        _bannerY = crop.offsetY;
        _imageError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _imageError = 'Не удалось открыть или обрезать фото.');
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim().replaceFirst(
          RegExp(r'^@+'),
          '',
        );
    if (name.isEmpty || username.isEmpty) {
      setState(() => _validationError = 'Имя и юзернейм не могут быть пустыми.');
      return;
    }
    Navigator.of(context).pop(
      _ProfileEditResult(
        name: name,
        username: username,
        avatarPath: _avatarPath,
        bannerPath: _bannerPath,
        avatarScale: _avatarScale,
        avatarX: _avatarX,
        avatarY: _avatarY,
        bannerScale: _bannerScale,
        bannerX: _bannerX,
        bannerY: _bannerY,
        frameStyle: _frameStyle,
        accentColor: _accentColor,
        showPlaylists: _showPlaylists,
        showTracks: _showTracks,
        showAlbums: _showAlbums,
        showArtists: _showArtists,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _profileBackground,
        appBar: AppBar(
          backgroundColor: _profileBackground,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Редактировать профиль',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          actions: [
            TextButton(
              onPressed: _save,
              child: Text(
                'Сохранить',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              const _EditorSectionTitle(
                title: 'Баннер',
                subtitle: 'Выбери изображение. После выбора можно передвинуть его и настроить кадр.',
              ),
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _CropTransformImage(
                    key: ValueKey('banner-preview:${_bannerPath ?? 'empty'}'),
                    path: _bannerPath,
                    scale: _bannerScale,
                    offsetX: _bannerX,
                    offsetY: _bannerY,
                    placeholder: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF345B56),
                            Color(0xFF263047),
                            Color(0xFF15171E),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _chooseBanner,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _bannerPath == null ? 'Выбрать баннер' : 'Заменить баннер',
                ),
              ),
              if (_bannerPath != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _bannerPath = null;
                      _bannerScale = 1;
                      _bannerX = 0;
                      _bannerY = 0;
                    }),
                    child: const Text('Убрать баннер'),
                  ),
                ),
              const SizedBox(height: 26),
              const _EditorSectionTitle(
                title: 'Аватарка',
                subtitle: 'После выбора откроется экран кадрирования с перемещением и масштабированием двумя пальцами.',
              ),
              Center(
                child: Container(
                  width: 156,
                  height: 156,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _framePreviewColor(_frameStyle),
                      width: _frameStyle == 'none' ? 0 : 3,
                    ),
                  ),
                  child: ClipOval(
                    child: _CropTransformImage(
                      key: ValueKey('avatar-preview:${_avatarPath ?? 'empty'}'),
                      path: _avatarPath,
                      scale: _avatarScale,
                      offsetX: _avatarX,
                      offsetY: _avatarY,
                      placeholder: const ColoredBox(
                        color: Color(0xFF24272B),
                        child: Center(
                          child: Icon(Icons.person_rounded, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _chooseAvatar,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _avatarPath == null ? 'Выбрать аватарку' : 'Заменить аватарку',
                ),
              ),
              if (_avatarPath != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _avatarPath = null;
                      _avatarScale = 1;
                      _avatarX = 0;
                      _avatarY = 0;
                    }),
                    child: const Text('Убрать аватарку'),
                  ),
                ),
              const SizedBox(height: 26),
              TextField(
                controller: _nameController,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _usernameController,
                maxLength: 30,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Юзернейм',
                  prefixText: '@',
                  counterText: '',
                ),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              if (_imageError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _imageError!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 30),
              const _EditorSectionTitle(
                title: 'Акцентный цвет',
                subtitle: 'Меняет цвет кнопок, выделений и активных элементов во всём приложении.',
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AccentChoice(
                    title: 'Белый',
                    color: const Color(0xFFF5F5F5),
                    selected: _accentColor.toARGB32() == 0xFFF5F5F5,
                    onTap: () => setState(
                      () => _accentColor = const Color(0xFFF5F5F5),
                    ),
                  ),
                  _AccentChoice(
                    title: 'Голубой',
                    color: const Color(0xFF73C9FF),
                    selected: _accentColor.toARGB32() == 0xFF73C9FF,
                    onTap: () => setState(
                      () => _accentColor = const Color(0xFF73C9FF),
                    ),
                  ),
                  _AccentChoice(
                    title: 'Фиолетовый',
                    color: const Color(0xFFB28BFF),
                    selected: _accentColor.toARGB32() == 0xFFB28BFF,
                    onTap: () => setState(
                      () => _accentColor = const Color(0xFFB28BFF),
                    ),
                  ),
                  _AccentChoice(
                    title: 'Розовый',
                    color: const Color(0xFFFF70A6),
                    selected: _accentColor.toARGB32() == 0xFFFF70A6,
                    onTap: () => setState(
                      () => _accentColor = const Color(0xFFFF70A6),
                    ),
                  ),
                  _AccentChoice(
                    title: 'Золотой',
                    color: const Color(0xFFFFC66D),
                    selected: _accentColor.toARGB32() == 0xFFFFC66D,
                    onTap: () => setState(
                      () => _accentColor = const Color(0xFFFFC66D),
                    ),
                  ),
                  _AccentChoice(
                    title: 'Лайм',
                    color: const Color(0xFFB6F36B),
                    selected: _accentColor.toARGB32() == 0xFFB6F36B,
                    onTap: () => setState(
                      () => _accentColor = const Color(0xFFB6F36B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _EditorSectionTitle(
                title: 'Рамка аватарки',
                subtitle: 'Выбери оформление вокруг фотографии.',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FrameChoice(
                    title: 'Без рамки',
                    style: 'none',
                    color: Colors.white24,
                    selected: _frameStyle == 'none',
                    onTap: () => setState(() => _frameStyle = 'none'),
                  ),
                  _FrameChoice(
                    title: 'Лайм',
                    style: 'lime',
                    color: const Color(0xFFB6F36B),
                    selected: _frameStyle == 'lime',
                    onTap: () => setState(() => _frameStyle = 'lime'),
                  ),
                  _FrameChoice(
                    title: 'Фиолетовая',
                    style: 'violet',
                    color: const Color(0xFFB28BFF),
                    selected: _frameStyle == 'violet',
                    onTap: () => setState(() => _frameStyle = 'violet'),
                  ),
                  _FrameChoice(
                    title: 'Голубая',
                    style: 'blue',
                    color: const Color(0xFF73C9FF),
                    selected: _frameStyle == 'blue',
                    onTap: () => setState(() => _frameStyle = 'blue'),
                  ),
                  _FrameChoice(
                    title: 'Золотая',
                    style: 'gold',
                    color: const Color(0xFFFFC66D),
                    selected: _frameStyle == 'gold',
                    onTap: () => setState(() => _frameStyle = 'gold'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _EditorSectionTitle(
                title: 'Разделы профиля',
                subtitle: 'Выбери, какие подборки показывать под аватаркой.',
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать плейлисты'),
                value: _showPlaylists,
                onChanged: (value) => setState(() => _showPlaylists = value),
                activeTrackColor: _accentColor,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать треки'),
                value: _showTracks,
                onChanged: (value) => setState(() => _showTracks = value),
                activeTrackColor: _accentColor,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать альбомы'),
                value: _showAlbums,
                onChanged: (value) => setState(() => _showAlbums = value),
                activeTrackColor: _accentColor,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Показывать авторов'),
                value: _showArtists,
                onChanged: (value) => setState(() => _showArtists = value),
                activeTrackColor: _accentColor,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: _accentColor.computeLuminance() > .55
                      ? const Color(0xFF11130D)
                      : Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'Сохранить изменения',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );

  Color _framePreviewColor(String style) {
    switch (style) {
      case 'lime':
        return const Color(0xFFB6F36B);
      case 'violet':
        return const Color(0xFFB28BFF);
      case 'blue':
        return const Color(0xFF73C9FF);
      case 'gold':
        return const Color(0xFFFFC66D);
      default:
        return Colors.transparent;
    }
  }
}

class _CropSelection {
  const _CropSelection({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  final double scale;
  final double offsetX;
  final double offsetY;
}

class _ImageCropScreen extends StatefulWidget {
  const _ImageCropScreen({
    required this.path,
    required this.isAvatar,
  });

  final String path;
  final bool isAvatar;

  @override
  State<_ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<_ImageCropScreen> {
  double _scale = 1;
  double _offsetX = 0;
  double _offsetY = 0;

  void _save() {
    Navigator.of(context).pop(
      _CropSelection(
        scale: _scale,
        offsetX: _offsetX,
        offsetY: _offsetY,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _profileBackground,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: _profileBackground,
          surfaceTintColor: Colors.transparent,
          title: Text(widget.isAvatar ? 'Обрезать аватар' : 'Обрезать баннер'),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth =
                        math.max(0.0, constraints.maxWidth - 32).toDouble();
                    final availableHeight =
                        math.max(0.0, constraints.maxHeight - 32).toDouble();
                    final width = widget.isAvatar
                        ? math.min(
                            availableWidth,
                            availableHeight * .84,
                          ).toDouble()
                        : math.min(
                            availableWidth,
                            availableHeight * 2.15,
                          ).toDouble();
                    final height = widget.isAvatar ? width : width / 2.15;
                    return Center(
                      child: SizedBox(
                        width: width,
                        height: height,
                        child: ClipRect(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _CropTransformImage(
                                path: widget.path,
                                scale: _scale,
                                offsetX: _offsetX,
                                offsetY: _offsetY,
                                interactive: true,
                                onTransformChanged: (scale, x, y) {
                                  setState(() {
                                    _scale = scale;
                                    _offsetX = x;
                                    _offsetY = y;
                                  });
                                },
                                placeholder: const ColoredBox(
                                  color: Color(0xFF24272B),
                                ),
                              ),
                              IgnorePointer(
                                child: CustomPaint(
                                  painter: _CropOverlayPainter(
                                    isCircle: widget.isAvatar,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                child: Text(
                  'Перемещайте фото одним пальцем и меняйте масштаб двумя пальцами. Можно оставить центр без изменений.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: FlowLyAccent.color,
                          foregroundColor:
                              FlowLyAccent.color.computeLuminance() > .55
                                  ? const Color(0xFF11130D)
                                  : Colors.white,
                          minimumSize: const Size.fromHeight(52),
                        ),
                        child: const Text('Использовать фото'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _CropOverlayPainter extends CustomPainter {
  const _CropOverlayPainter({required this.isCircle});

  final bool isCircle;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final cropPath = isCircle
        ? (Path()..addOval(bounds))
        : (Path()
          ..addRRect(
            RRect.fromRectAndRadius(bounds, const Radius.circular(12)),
          ));
    final outside = Path.combine(
      PathOperation.difference,
      Path()..addRect(bounds),
      cropPath,
    );
    canvas.drawPath(
      outside,
      Paint()..color = Colors.black.withValues(alpha: .58),
    );
    canvas.drawPath(
      cropPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: .92),
    );
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.isCircle != isCircle;
}

class _AccentChoice extends StatelessWidget {
  const _AccentChoice({
    required this.title,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        avatar: Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white54),
          ),
        ),
        label: Text(title),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color.withValues(alpha: .18),
        side: BorderSide(
          color: selected ? color : Colors.white24,
        ),
      );
}

class _EditorSectionTitle extends StatelessWidget {
  const _EditorSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
}

class _FrameChoice extends StatelessWidget {
  const _FrameChoice({
    required this.title,
    required this.style,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String style;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        avatar: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: style == 'none' ? Colors.transparent : color,
            border: Border.all(color: color),
          ),
        ),
        label: Text(title),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: FlowLyAccent.color.withValues(alpha: .16),
        side: BorderSide(
          color: selected ? FlowLyAccent.color : Colors.white24,
        ),
      );
}

class _CropTransformImage extends StatefulWidget {
  const _CropTransformImage({
    super.key,
    required this.path,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
    required this.placeholder,
    this.interactive = false,
    this.onTransformChanged,
  });

  final String? path;
  final double scale;
  final double offsetX;
  final double offsetY;
  final Widget placeholder;
  final bool interactive;
  final void Function(double scale, double x, double y)? onTransformChanged;

  @override
  State<_CropTransformImage> createState() => _CropTransformImageState();
}

class _CropTransformImageState extends State<_CropTransformImage> {
  Size? _sourceSize;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Size _frameSize = Size.zero;
  double _startScale = 1;
  double _startX = 0;
  double _startY = 0;
  Offset _startFocalPoint = Offset.zero;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _CropTransformImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _removeImageListener();
      _sourceSize = null;
      _resolveImage();
    }
  }

  void _removeImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  void _resolveImage() {
    final path = widget.path;
    if (path == null) return;

    final stream = FileImage(File(path)).resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, synchronousCall) {
      final size = Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      );
      info.dispose();
      if (!mounted) return;
      setState(() => _sourceSize = size);
    });
    _imageStream = stream;
    _imageListener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _removeImageListener();
    super.dispose();
  }

  Offset _maxOffsets(Size frame, double scale) {
    final source = _sourceSize;
    if (source == null ||
        frame.width <= 0 ||
        frame.height <= 0 ||
        source.width <= 0 ||
        source.height <= 0) {
      return Offset.zero;
    }
    final coverScale = math.max(
      frame.width / source.width,
      frame.height / source.height,
    ).toDouble();
    final scaledWidth = source.width * coverScale * scale;
    final scaledHeight = source.height * coverScale * scale;
    return Offset(
      math.max(0.0, (scaledWidth - frame.width) / 2).toDouble(),
      math.max(0.0, (scaledHeight - frame.height) / 2).toDouble(),
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _startScale = widget.scale;
    _startX = widget.offsetX;
    _startY = widget.offsetY;
    _startFocalPoint = details.focalPoint;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (!widget.interactive || widget.onTransformChanged == null) return;
    final nextScale =
        (_startScale * details.scale).clamp(1.0, 4.0).toDouble();
    final startMax = _maxOffsets(_frameSize, _startScale);
    final nextMax = _maxOffsets(_frameSize, nextScale);
    final delta = details.focalPoint - _startFocalPoint;
    final pixelX = _startX * startMax.dx + delta.dx;
    final pixelY = _startY * startMax.dy + delta.dy;
    final nextX = nextMax.dx == 0
        ? 0.0
        : (pixelX / nextMax.dx).clamp(-1.0, 1.0).toDouble();
    final nextY = nextMax.dy == 0
        ? 0.0
        : (pixelY / nextMax.dy).clamp(-1.0, 1.0).toDouble();
    widget.onTransformChanged!(nextScale, nextX, nextY);
  }

  @override
  Widget build(BuildContext context) {
    final image = LayoutBuilder(
      builder: (context, constraints) {
        _frameSize = Size(constraints.maxWidth, constraints.maxHeight);
        final path = widget.path;
        final source = _sourceSize;
        if (path == null) {
          return SizedBox.expand(child: widget.placeholder);
        }
        if (source == null) {
          return SizedBox.expand(
            child: Image.file(
              File(path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => widget.placeholder,
            ),
          );
        }

        final coverScale = math.max(
          constraints.maxWidth / source.width,
          constraints.maxHeight / source.height,
        ).toDouble();
        final imageWidth = source.width * coverScale;
        final imageHeight = source.height * coverScale;
        final maxOffset = _maxOffsets(_frameSize, widget.scale);
        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            const ColoredBox(color: Color(0xFF24272B)),
            Center(
              child: Transform.translate(
                offset: Offset(
                  widget.offsetX * maxOffset.dx,
                  widget.offsetY * maxOffset.dy,
                ),
                child: Transform.scale(
                  scale: widget.scale.clamp(1.0, 4.0).toDouble(),
                  child: SizedBox(
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.fill,
                      errorBuilder: (_, __, ___) => widget.placeholder,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (!widget.interactive) return image;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      child: image,
    );
  }
}
