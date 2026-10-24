import 'dart:math' as math;\nimport 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'player_controller.dart';

const _playerBackground = Color(0xFF101014);
const _playerSurface = Color(0xFF282830);
const _playerMuted = Color(0xFF9A9AA5);
const _playerLime = Color(0xFFB6F36B);

/// Compact player based on the original FlowLy v1.0.15 PlayWidget.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({
    super.key,
    required this.onOpen,
  });

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
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black12, width: 0.5),
                borderRadius: BorderRadius.circular(10),
                boxShadow: kElevationToShadow[9],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            track.color.withValues(alpha: .88),
                            const Color(0xFF191919),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -16,
                      top: -36,
                      child: Icon(
                        track.icon,
                        size: 112,
                        color: Colors.white.withValues(alpha: .15),
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: .32),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: AlbumCover(track: track, size: 40),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: player.togglePlay,
                            tooltip: player.isPlaying ? 'Пауза' : 'Воспроизвести',
                            icon: Icon(
                              player.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ],
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

/// A drag-driven player surface: while dragging, its cover position and size
/// are interpolated directly from the finger's progress, rather than a route
/// transition that only starts after the gesture ends.
class PlayerTransitionOverlay extends StatelessWidget {
  const PlayerTransitionOverlay({
    super.key,
    required this.progress,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onClose,
  });

  final double progress;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final ValueChanged<double> onDragEnd;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final player = PlayerController.instance;
    final media = MediaQuery.of(context);
    final screen = media.size;
    final p = progress.clamp(0.0, 1.0);
    final expandedCoverSize =
        math.min(screen.width * 0.76, screen.height < 750 ? 230.0 : 310.0);
    final miniCoverLeft = 20.0;
    final miniCoverTop = screen.height - media.padding.bottom - 124.0;
    final expandedCoverLeft = (screen.width - expandedCoverSize) / 2;
    final expandedCoverTop =
        math.max(media.padding.top + 68.0, screen.height * 0.17);
    final coverSize = 52 + (expandedCoverSize - 52) * p;
    final coverLeft = miniCoverLeft + (expandedCoverLeft - miniCoverLeft) * p;
    final coverTop = miniCoverTop + (expandedCoverTop - miniCoverTop) * p;
    final detailsTop = expandedCoverTop + expandedCoverSize + 25;
    final detailsOpacity = ((p - 0.16) / 0.72).clamp(0.0, 1.0);
    final controlsOpacity = ((p - 0.36) / 0.58).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => onDragStart(),
      onVerticalDragUpdate: (details) => onDragUpdate(details.delta.dy),
      onVerticalDragEnd: (details) => onDragEnd(details.primaryVelocity ?? 0),
      child: AnimatedBuilder(
        animation: player,
        builder: (context, _) {
          final track = player.currentTrack;
          return Material(
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
              ColoredBox(
                color: _playerBackground.withValues(alpha: p),
              ),
              Positioned(
                left: coverLeft,
                top: coverTop,
                child: AlbumCover(track: track, size: coverSize),
              ),
              Positioned(
                top: media.padding.top + 4,
                left: 12,
                right: 12,
                child: Opacity(
                  opacity: p,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Свернуть плеер',
                        onPressed: onClose,
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
                ),
              ),
              Positioned(
                top: detailsTop,
                left: 24,
                right: 20,
                child: IgnorePointer(
                  ignoring: p < 0.94,
                  child: Opacity(
                    opacity: detailsOpacity,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                style: const TextStyle(color: _playerMuted, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: player.isFavorite ? 'Убрать из избранного' : 'В избранное',
                          onPressed: player.toggleFavorite,
                          icon: Icon(
                            player.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: player.isFavorite ? _playerLime : Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: detailsTop + 102,
                left: 21,
                right: 21,
                child: IgnorePointer(
                  ignoring: p < 0.94,
                  child: Opacity(
                    opacity: controlsOpacity,
                    child: SliderTheme(
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
                  ),
                ),
              ),
              Positioned(
                top: detailsTop + 137,
                left: 27,
                right: 27,
                child: IgnorePointer(
                  ignoring: p < 0.94,
                  child: Opacity(
                    opacity: controlsOpacity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(player.position), style: const TextStyle(color: _playerMuted, fontSize: 12)),
                        Text(_formatDuration(track.duration), style: const TextStyle(color: _playerMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: detailsTop + 175,
                left: 45,
                right: 45,
                child: IgnorePointer(
                  ignoring: p < 0.94,
                  child: Opacity(
                    opacity: controlsOpacity,
                    child: Row(
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
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
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
                  ),
                ),
              ),
              Positioned(
                bottom: media.padding.bottom + 18,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: controlsOpacity,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.speaker_rounded, color: _playerMuted, size: 18),
                        SizedBox(width: 8),
                        Text('Демо-плеер FlowLy', style: TextStyle(color: _playerMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              ],
            ),
          );
        },
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
