import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'animated_music_player.dart' show AlbumCover;
import 'player_controller.dart';

/// Один виджет-карточка: мини-плеер и полный плеер — это одно и то же,
/// все размеры/позиции считаются из одного progress (0 = мини, 1 = полный).
class DraggableView extends StatefulWidget {
  const DraggableView({
    super.key,
    this.onOpenStateChanged,
  });

  final ValueChanged<bool>? onOpenStateChanged;

  @override
  State<DraggableView> createState() => DraggableViewState();
}

class DraggableViewState extends State<DraggableView>
    with SingleTickerProviderStateMixin {
  static const double _miniHeight = 56;
  static const double _miniMargin = 8;
  static const double _miniRadius = 12;
  static const double _navBarHeight = 54; // высота NavigationBar в app.dart

  late final AnimationController _progress;
  final PlayerController _player = PlayerController.instance;

  bool get isOpen => _progress.value > 0.5;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  Future<void> open() async {
    if (!mounted) return;
    widget.onOpenStateChanged?.call(true);
    await _progress.animateTo(
      1,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> close() async {
    if (!mounted) return;
    await _progress.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
    widget.onOpenStateChanged?.call(false);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final range = MediaQuery.sizeOf(context).height - _miniHeight;
    if (range <= 0) return;
    _progress.stop();
    _progress.value =
        (_progress.value - (details.primaryDelta ?? 0) / range)\n            .clamp(0.0, 1.0)
            .toDouble();
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity.abs() > 600
        ? (velocity < 0 ? 1.0 : 0.0)
        : (_progress.value > 0.5 ? 1.0 : 0.0);
    if (target == 1) {
      await open();
    } else {
      await close();
    }
  }

  double _remap(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();

  static String _format(Duration value) =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progress, _player]),
      builder: (context, _) {
        final track = _player.currentTrack;
        final size = MediaQuery.sizeOf(context);
        final safeTop = MediaQuery.paddingOf(context).top;
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        final t = _progress.value;

        final artSize = lerpDouble(40, size.width * 0.72, t)!;
        final artTop = lerpDouble(8, safeTop + 90, t)!;
        final artLeft = lerpDouble(8, (size.width - artSize) / 2, t)!;
        final cardWidth = size.width - lerpDouble(_miniMargin * 2, 0, t)!;
        final cardHeight = lerpDouble(_miniHeight, size.height, t)!;
        final bottomMargin =
            lerpDouble(_navBarHeight + safeBottom + 4, 0, t)!;
        final radius = lerpDouble(_miniRadius, 0, t)!;

        final miniOpacity = 1 - _remap(t, 0, 0.3);
        final expandedOpacity = _remap(t, 0.5, 1);

        return Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: Container(
              width: cardWidth,
              height: cardHeight,
              margin: EdgeInsets.only(bottom: bottomMargin),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.lerp(
                  Color.alphaBlend(
                    track.color.withValues(alpha: .35),
                    const Color(0xFF191919),
                  ),
                  const Color(0xFF101014),
                  t,
                ),
                borderRadius: BorderRadius.all(Radius.circular(radius)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: artTop,
                    left: artLeft,
                    width: artSize,
                    height: artSize,
                    child: AlbumCover(track: track, size: artSize),
                  ),
                  Positioned(
                    left: 56,
                    right: 100,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: IgnorePointer(
                        ignoring: t > 0.3,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: open,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 48,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: IgnorePointer(
                        ignoring: t > 0.3,
                        child: _ActionButton(
                          icon: _player.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: _player.togglePlay,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 0,
                    height: _miniHeight,
                    child: Opacity(
                      opacity: miniOpacity,
                      child: IgnorePointer(
                        ignoring: t > 0.3,
                        child: _ActionButton(
                          icon: Icons.skip_next_rounded,
                          onTap: _player.next,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: artTop + artSize + 32,
                    left: 24,
                    right: 24,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        track.artist,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _ActionButton(
                                  icon: _player.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  onTap: _player.toggleFavorite,
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                                overlayColor: Colors.transparent,
                                trackHeight: 4,
                              ),
                              child: Slider(
                                value: _player.progress,
                                onChanged: _player.seek,
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _format(_player.position),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _format(track.duration),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _ActionButton(
                                  icon: Icons.skip_previous_rounded,
                                  size: 64,
                                  onTap: _player.previous,
                                ),
                                GestureDetector(
                                  onTap: _player.togglePlay,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _player.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: 44,
                                    ),
                                  ),
                                ),
                                _ActionButton(
                                  icon: Icons.skip_next_rounded,
                                  size: 64,
                                  onTap: _player.next,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: safeTop + 8,
                    left: 8,
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: _ActionButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          size: 48,
                          onTap: close,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            color: onTap == null ? Colors.white24 : Colors.white,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}
