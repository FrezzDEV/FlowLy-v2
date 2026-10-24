import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'animated_music_player.dart' show AlbumCover;
import 'big_player_content.dart';
import 'player_controller.dart';
import '../library/playlist_sheets.dart';

final GlobalKey<DraggableViewState> draggablePlayerKey =
    GlobalKey<DraggableViewState>();

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
        (_progress.value - (details.primaryDelta ?? 0) / range)
            .clamp(0.0, 1.0)
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


  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontFamilyFallback: ['sans-serif'],
        letterSpacing: 0,
        decoration: TextDecoration.none,
        decorationColor: Colors.transparent,
      ),
      child: AnimatedBuilder(
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

        final playerBackground = Theme.of(context).colorScheme.surface;
        final miniOpacity = 1 - _remap(t, 0, 0.3);
        final expandedOpacity = _remap(t, 0.5, 1);

        return Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomMargin),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // Every part of the mini-player bar opens the full player;
              // child controls keep their own tap handlers.
              onTap: () {
                if (_progress.value < 0.5) open();
              },
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: playerBackground,
                borderRadius: BorderRadius.all(Radius.circular(radius)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: artTop,
                    left: artLeft,
                    width: artSize,
                    height: artSize,
                    child: Opacity(
                      opacity: 1 - expandedOpacity,
                      child: AlbumCover(track: track, size: artSize),
                    ),
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
                  if (t >= 0.3)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: t < 0.5,
                        child: Opacity(
                          opacity: expandedOpacity,
                          child: BigPlayerContent(
                            player: _player,
                            active: t > 0.5 || _player.isPlaying,
                            onClose: close,
                            onMore: () => showSaveTrackToPlaylistSheet(
                              context,
                              track,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
        },
      ),
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
