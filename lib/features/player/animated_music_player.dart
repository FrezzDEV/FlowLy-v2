import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'player_controller.dart';

const _playerBackground = Color(0xFF101014);
const _playerSurface = Color(0xFF282830);
const _playerMuted = Color(0xFF9A9AA5);
const _playerLime = Color(0xFFB6F36B);

/// Persistent compact player shown above the bottom navigation.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final player = PlayerController.instance;
    return AnimatedBuilder(
      animation: player,
      builder: (context, _) {
        final track = player.currentTrack;
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          child: GestureDetector(
            onTap: onOpen,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 72,
                color: _playerSurface,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 10),
                        Hero(
                          tag: 'album_art',
                          child: AlbumCover(track: track, size: 52),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _playerMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: player.isPlaying ? 'Пауза' : 'Воспроизвести',
                          onPressed: player.togglePlay,
                          icon: Icon(
                            player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 31,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 2,
                      child: LinearProgressIndicator(
                        value: player.progress,
                        backgroundColor: Colors.white12,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(_playerLime),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Full-screen player. The matching Hero tag animates the cover out of the
/// mini-player while the route uses the fade/scale transition from the mockup.
class FullScreenPlayer extends StatelessWidget {
  const FullScreenPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = PlayerController.instance;
    final screen = MediaQuery.sizeOf(context);
    final coverSize = math.min(screen.width * 0.76, screen.height < 750 ? 230.0 : 310.0);

    return Scaffold(
      backgroundColor: _playerBackground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: player,
          builder: (context, _) {
            final track = player.currentTrack;
            return LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                tooltip: 'Свернуть плеер',
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'СЕЙЧАС ИГРАЕТ',
                                style: TextStyle(
                                  color: _playerMuted,
                                  fontSize: 11,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Очередь',
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Очередь появится на следующем этапе')),
                                ),
                                icon: const Icon(Icons.queue_music_rounded, color: Colors.white),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Hero(
                            tag: 'album_art',
                            child: AlbumCover(track: track, size: coverSize),
                          ),
                          const SizedBox(height: 34),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      track.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      track.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _playerMuted,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: player.isFavorite ? 'Убрать из избранного' : 'В избранное',
                                onPressed: player.toggleFavorite,
                                icon: Icon(
                                  player.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: player.isFavorite ? _playerLime : Colors.white,
                                  size: 28,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              value: player.progress,
                              onChanged: player.seek,
                              activeColor: _playerLime,
                              inactiveColor: Colors.white24,
                              min: 0,
                              max: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(player.position), style: const TextStyle(color: _playerMuted, fontSize: 12)),
                                Text(_formatDuration(track.duration), style: const TextStyle(color: _playerMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                tooltip: 'Предыдущий трек',
                                onPressed: player.previous,
                                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 42),
                              ),
                              GestureDetector(
                                onTap: player.togglePlay,
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.black,
                                    size: 42,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Следующий трек',
                                onPressed: player.next,
                                icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 42),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.speaker_rounded, color: _playerMuted, size: 18),
                              SizedBox(width: 8),
                              Text('Демо-плеер FlowLy', style: TextStyle(color: _playerMuted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString();
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, required this.track, required this.size});

  final PlayerTrack track;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.08),
          gradient: LinearGradient(
            colors: [track.color, const Color(0xFF24243A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              right: -size * 0.09,
              top: -size * 0.10,
              child: Icon(
                track.icon,
                size: size * 0.65,
                color: Colors.white.withValues(alpha: .12),
              ),
            ),
            Icon(track.icon, color: Colors.white, size: size * .42),
          ],
        ),
      );
}
