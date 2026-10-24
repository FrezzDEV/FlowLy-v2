import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Demo-only playback state for the FlowLy UI. No audio engine is connected.
class PlayerTrack {
  const PlayerTrack({
    required this.title,
    required this.artist,
    required this.color,
    required this.icon,
    required this.duration,
  });

  final String title;
  final String artist;
  final Color color;
  final IconData icon;
  final Duration duration;
}

class MusicPlaylist {
  MusicPlaylist({
    required this.id,
    required this.name,
    Iterable<PlayerTrack> tracks = const <PlayerTrack>[],
    this.isSystem = false,
  }) : tracks = List<PlayerTrack>.unmodifiable(tracks);

  final String id;
  final String name;
  final List<PlayerTrack> tracks;
  final bool isSystem;

  MusicPlaylist copyWith({String? name, Iterable<PlayerTrack>? tracks}) =>
      MusicPlaylist(
        id: id,
        name: name ?? this.name,
        tracks: tracks ?? this.tracks,
        isSystem: isSystem,
      );
}

class PlayerController extends ChangeNotifier {
  PlayerController._();

  static final PlayerController instance = PlayerController._();

  static const String favoritesPlaylistId = 'system_favorites';
  static const String downloadsPlaylistId = 'system_downloads';
  static const String _playlistStorageKey = 'flowly.playlists.v1';

  static const List<PlayerTrack> catalog = [
    PlayerTrack(
      title: 'Midnight Flow',
      artist: 'Unknown Artist',
      color: Color(0xFF51416D),
      icon: Icons.music_note_rounded,
      duration: Duration(minutes: 3, seconds: 45),
    ),
    PlayerTrack(
      title: 'Afterlife',
      artist: 'Ed Sheeran',
      color: Color(0xFF1C6788),
      icon: Icons.water_rounded,
      duration: Duration(minutes: 3, seconds: 45),
    ),
    PlayerTrack(
      title: 'Someone You Loved',
      artist: 'Lewis Capaldi',
      color: Color(0xFFB52F17),
      icon: Icons.person_rounded,
      duration: Duration(minutes: 3, seconds: 2),
    ),
    PlayerTrack(
      title: 'Night Drive',
      artist: 'Kavinsky',
      color: Color(0xFF112A45),
      icon: Icons.directions_car_rounded,
      duration: Duration(minutes: 4, seconds: 12),
    ),
    PlayerTrack(
      title: 'The Night We Met',
      artist: 'Lord Huron',
      color: Color(0xFF393943),
      icon: Icons.nightlight_round,
      duration: Duration(minutes: 3, seconds: 28),
    ),
    PlayerTrack(
      title: 'Chill Bill',
      artist: 'Rob Stone',
      color: Color(0xFF4C171D),
      icon: Icons.person_rounded,
      duration: Duration(minutes: 3, seconds: 17),
    ),
    PlayerTrack(
      title: 'As It Was',
      artist: 'Harry Styles',
      color: Color(0xFF332947),
      icon: Icons.door_front_door_rounded,
      duration: Duration(minutes: 2, seconds: 47),
    ),
    PlayerTrack(
      title: 'Sweater Weather',
      artist: 'The Neighbourhood',
      color: Color(0xFF34423A),
      icon: Icons.forest_rounded,
      duration: Duration(minutes: 4),
    ),
  ];

  int _currentIndex = 0;
  PlayerTrack _currentTrack = catalog.first;
  bool _isPlaying = false;
  double _progress = 0;
  Timer? _playbackTimer;
  bool _initialized = false;
  List<MusicPlaylist> _playlists = [
    MusicPlaylist(id: favoritesPlaylistId, name: 'Избранное', isSystem: true),
    MusicPlaylist(id: downloadsPlaylistId, name: 'Скачанные', isSystem: true),
  ];

  PlayerTrack get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isFavorite => playlistById(favoritesPlaylistId)?.tracks.any(
        (track) => _sameTrack(track, _currentTrack),
      ) ?? false;
  double get progress => _progress;
  List<MusicPlaylist> get playlists =>
      List<MusicPlaylist>.unmodifiable(_playlists);

  MusicPlaylist? playlistById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  bool _sameTrack(PlayerTrack first, PlayerTrack second) =>
      first.title == second.title && first.artist == second.artist;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_playlistStorageKey);
      if (encoded != null) {
        final decoded = jsonDecode(encoded);
        if (decoded is List) {
          final loaded = <MusicPlaylist>[];
          for (final item in decoded) {
            if (item is! Map) continue;
            final id = item['id'];
            final name = item['name'];
            if (id is! String || name is! String) continue;
            final tracks = <PlayerTrack>[];
            final savedTracks = item['tracks'];
            if (savedTracks is List) {
              for (final saved in savedTracks) {
                if (saved is! Map) continue;
                final title = saved['title'];
                final artist = saved['artist'];
                if (title is! String || artist is! String) continue;
                for (final track in catalog) {
                  if (track.title == title && track.artist == artist) {
                    tracks.add(track);
                    break;
                  }
                }
              }
            }
            loaded.add(MusicPlaylist(
              id: id,
              name: id == downloadsPlaylistId ? 'Скачанные' : name,
              tracks: tracks,
              isSystem: item['isSystem'] == true,
            ));
          }
          _playlists = loaded;
        }
      }
      _ensureSystemPlaylists();
      await _persistPlaylists(preferences: preferences);
    } catch (_) {
      // The app remains usable in environments without a platform store.
      _ensureSystemPlaylists();
    }
    notifyListeners();
  }

  void _ensureSystemPlaylists() {
    if (!_playlists.any((playlist) => playlist.id == favoritesPlaylistId)) {
      _playlists.insert(0, MusicPlaylist(
        id: favoritesPlaylistId,
        name: 'Избранное',
        isSystem: true,
      ));
    }
    if (!_playlists.any((playlist) => playlist.id == downloadsPlaylistId)) {
      final favoritesIndex = _playlists.indexWhere(
        (playlist) => playlist.id == favoritesPlaylistId,
      );
      _playlists.insert(favoritesIndex < 0 ? 0 : favoritesIndex + 1,
        MusicPlaylist(
          id: downloadsPlaylistId,
          name: 'Загрузки',
          isSystem: true,
        ),
      );
    }
  }

  Future<void> _persistPlaylists({
    SharedPreferences? preferences,
  }) async {
    try {
      final store = preferences ?? await SharedPreferences.getInstance();
      final data = _playlists.map((playlist) => <String, Object>{
        'id': playlist.id,
        'name': playlist.name,
        'isSystem': playlist.isSystem,
        'tracks': playlist.tracks.map((track) => <String, String>{
          'title': track.title,
          'artist': track.artist,
        }).toList(),
      }).toList();
      await store.setString(_playlistStorageKey, jsonEncode(data));
    } catch (_) {
      // In-memory operations still work if a platform store is unavailable.
    }
  }

  Future<MusicPlaylist> createPlaylist(
    String name, {
    PlayerTrack? initialTrack,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const FormatException('Название плейлиста не может быть пустым.');
    }
    final existing = _playlists.where(
      (playlist) => playlist.name.toLowerCase() == cleanName.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      final playlist = existing.first;
      if (initialTrack != null) {
        await addTrackToPlaylist(playlist.id, initialTrack);
      }
      return playlistById(playlist.id) ?? playlist;
    }
    final playlist = MusicPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: cleanName,
      tracks: initialTrack == null ? const <PlayerTrack>[] : [initialTrack],
    );
    _playlists = [..._playlists, playlist];
    notifyListeners();
    await _persistPlaylists();
    return playlist;
  }

  Future<bool> addTrackToPlaylist(String playlistId, PlayerTrack track) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index < 0) return false;
    final playlist = _playlists[index];
    if (playlist.tracks.any((item) => _sameTrack(item, track))) return false;
    final updated = [..._playlists];
    updated[index] = playlist.copyWith(tracks: [...playlist.tracks, track]);
    _playlists = updated;
    notifyListeners();
    await _persistPlaylists();
    return true;
  }

  Future<int> addTracksToPlaylist(
    String playlistId,
    Iterable<PlayerTrack> tracks,
  ) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index < 0) return 0;

    final playlist = _playlists[index];
    final updatedTracks = [...playlist.tracks];
    var addedCount = 0;
    for (final track in tracks) {
      if (updatedTracks.any((item) => _sameTrack(item, track))) continue;
      updatedTracks.add(track);
      addedCount++;
    }
    if (addedCount == 0) return 0;

    final updatedPlaylists = [..._playlists];
    updatedPlaylists[index] = playlist.copyWith(tracks: updatedTracks);
    _playlists = updatedPlaylists;
    notifyListeners();
    await _persistPlaylists();
    return addedCount;
  }

  Future<bool> removeTrackFromPlaylist(
    String playlistId,
    PlayerTrack track,
  ) async {
    final index = _playlists.indexWhere((playlist) => playlist.id == playlistId);
    if (index < 0) return false;
    final playlist = _playlists[index];
    if (!playlist.tracks.any((item) => _sameTrack(item, track))) return false;
    final updated = [..._playlists];
    updated[index] = playlist.copyWith(
      tracks: playlist.tracks.where((item) => !_sameTrack(item, track)),
    );
    _playlists = updated;
    notifyListeners();
    await _persistPlaylists();
    return true;
  }

  Duration get position => Duration(
        seconds: (_currentTrack.duration.inSeconds * _progress).round(),
      );

  void playTrack(PlayerTrack track) {
    _currentTrack = track;
    final index = catalog.indexWhere(
      (item) => item.title == track.title && item.artist == track.artist,
    );
    if (index >= 0) _currentIndex = index;
    _progress = 0;
    _isPlaying = true;
    _startPlaybackTimer();
    notifyListeners();
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    if (_isPlaying) {
      if (_progress >= 1) _progress = 0;
      _startPlaybackTimer();
    } else {
      _playbackTimer?.cancel();
      _playbackTimer = null;
    }
    notifyListeners();
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    if (!_isPlaying || _currentTrack.duration.inSeconds <= 0) {
      _playbackTimer = null;
      return;
    }

    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        _playbackTimer = null;
        return;
      }

      final durationSeconds = _currentTrack.duration.inSeconds;
      _progress = (_progress + 1 / durationSeconds).clamp(0.0, 1.0);
      if (_progress >= 1) {
        next();
      } else {
        notifyListeners();
      }
    });
  }

  void toggleFavorite() {
    if (isFavorite) {
      unawaited(removeTrackFromPlaylist(favoritesPlaylistId, _currentTrack));
    } else {
      unawaited(addTrackToPlaylist(favoritesPlaylistId, _currentTrack));
    }
  }

  void seek(double value) {
    _progress = value.clamp(0.0, 1.0);
    notifyListeners();
  }

  void next() {
    _currentIndex = (_currentIndex + 1) % catalog.length;
    _currentTrack = catalog[_currentIndex];
    _progress = 0;
    _isPlaying = true;

    _startPlaybackTimer();
    notifyListeners();
  }

  void previous() {
    _currentIndex = (_currentIndex - 1 + catalog.length) % catalog.length;
    _currentTrack = catalog[_currentIndex];
    _progress = 0;
    _isPlaying = true;

    _startPlaybackTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
