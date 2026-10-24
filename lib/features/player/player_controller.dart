import 'dart:async';

import 'package:flutter/material.dart';

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

class PlayerController extends ChangeNotifier {
  PlayerController._();

  static final PlayerController instance = PlayerController._();

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
  bool _isFavorite = false;
  double _progress = 0;
  Timer? _playbackTimer;

  PlayerTrack get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  bool get isFavorite => _isFavorite;
  double get progress => _progress;

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
    _isFavorite = !_isFavorite;
    notifyListeners();
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
    _isFavorite = false;
    _startPlaybackTimer();
    notifyListeners();
  }

  void previous() {
    _currentIndex = (_currentIndex - 1 + catalog.length) % catalog.length;
    _currentTrack = catalog[_currentIndex];
    _progress = 0;
    _isPlaying = true;
    _isFavorite = false;
    _startPlaybackTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
