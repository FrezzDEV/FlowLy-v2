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
    with TickerProviderStateMixin {
  static const double _miniHeight = 56;
  static const double _miniMargin = 8;
  static const double _miniRadius = 12;
  static const double _navBarHeight = 54; // высота NavigationBar в app.dart

  late final AnimationController _progress;
  late final AnimationController _coverReveal;
  final PlayerController _player = PlayerController.instance;
  late PlayerTrack _coverTrack;
  PlayerTrack? _incomingTrack;
  bool _coverForward = true;

  bool get isOpen => _progress.value > 0.5;

  @override
  void initState() {
    super.initState();
    _coverTrack = _player.currentTrack;
    _progress = AnimationController(vsync: this, value: 0);
    _coverReveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener(_onCoverRevealStatus);
    _player.addListener(_onPlayerTrackChanged);
  }

  void _onCoverRevealStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final incoming = _incomingTrack;
    if (incoming == null) return;
    setState(() {
      _coverTrack = incoming;
      _incomingTrack = null;
    });
    _coverReveal.value = 0;
  }

  void _onPlayerTrackChanged() {
    final next = _player.currentTrack;
    if (identical(next, _coverTrack) || identical(next, _incomingTrack)) return;

    // In the collapsed mini-player, swap the cover immediately without a reveal.
    if (_progress.value < 0.5) {
      _coverReveal
        ..stop()
        ..value = 0;
      _coverTrack = next;
      _incomingTrack = null;
      if (mounted) setState(() {});
      return;
    }

    // Finish an interrupted reveal first, so rapid next/previous taps never leave stale art.
    if (_incomingTrack != null) {
      _coverTrack = _incomingTrack!;
      _incomingTrack = null;
      _coverReveal.stop();
      _coverReveal.value = 0;
    }

    final catalog = PlayerController.catalog;
    final oldIndex = catalog.indexOf(_coverTrack);
    final newIndex = catalog.indexOf(next);
    _coverForward = oldIndex < 0 || newIndex < 0
        ? true
        : newIndex == (oldIndex + 1) % catalog.length;
    _incomingTrack = next;
    _coverReveal.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 1500);
    if (mounted) setState(() {});
    _coverReveal.forward(from: 0);
  }

  @override
  void dispose() {
    _player.removeListener(_onPlayerTrackChanged);
    _coverReveal
      ..removeStatusListener(_onCoverRevealStatus)
      ..dispose();
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

  Widget _demoTintedCover(PlayerTrack track, double size) => Stack(
        fit: StackFit.expand,
        children: [
          AlbumCover(track: track, size: size),
          // DEMO ONLY: remove this tint line at release when final cover art is ready.
          ColoredBox(color: track.color.withValues(alpha: .12)),
        ],
      );

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

        final playerBackground = Color.alphaBlend(
          track.color.withValues(alpha: .35),
          const Color(0xFF191919),
        );
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
                    child: ClipRRect(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      borderRadius: BorderRadius.circular(artSize * .08),
                      child: AnimatedBuilder(
                        animation: _coverReveal,
                        builder: (context, _) {
                          // Mini-player art changes immediately; the circular
                          // reveal is reserved for the expanded player.
                          if (_progress.value < 0.5) {
                            return _demoTintedCover(track, artSize);
                          }
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              _demoTintedCover(_coverTrack, artSize),
                              if (_incomingTrack != null)
                                ClipRRect(
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  borderRadius: BorderRadius.circular(artSize * .08),
                                  child: ClipPath(
                                    clipper: _TrackCircleRevealClipper(
                                      t: Curves.easeInOutCubic.transform(
                                        _coverReveal.value,
                                      ),
                                      forward: _coverForward,
                                    ),
                                    child: _demoTintedCover(
                                      _incomingTrack!,
                                      artSize,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
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
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 360),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, .18),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  track.title,
                                  key: ValueKey('mini-title-${track.title}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 420),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, .18),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  track.artist,
                                  key: ValueKey('mini-artist-${track.artist}'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
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
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: t < 0.5,
                      child: Opacity(
                        opacity: expandedOpacity,
                        child: Offstage(
                          offstage: t < 0.3,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              artTop + artSize + 32,
                              24,
                              16,
                            ),
                            child: BigPlayerContent(
                              player: _player,
                              active: t > 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (t >= 0.3)
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
                  if (t >= 0.3)
                    Positioned(
                      top: safeTop + 16,
                      left: 64,
                      right: 64,
                      child: IgnorePointer(
                        ignoring: t < 0.5,
                        child: Opacity(
                          opacity: expandedOpacity,
                          child: const Center(
                            child: Text(
                              'Сейчас играет',
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (t >= 0.3)
                    Positioned(
                      top: safeTop + 8,
                      right: 8,
                      child: IgnorePointer(
                        ignoring: t < 0.5,
                        child: Opacity(
                          opacity: expandedOpacity,
                          child: _ActionButton(
                            icon: Icons.more_horiz_rounded,
                            size: 48,
                            onTap: () => showSaveTrackToPlaylistSheet(
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


/// Reveals the incoming track cover from a circle growing below the artwork.
class _TrackCircleRevealClipper extends CustomClipper<Path> {
  const _TrackCircleRevealClipper({required this.t, required this.forward});

  final double t;
  final bool forward;

  @override
  Path getClip(Size size) {
    // Start clearly inside the cover, not on its clipped corner.
    final center = Offset(
      size.width * (forward ? .82 : .18),
      size.height * .82,
    );
    return Path()
      ..addOval(
        Rect.fromCircle(
          center: center,
          radius: size.width * 1.65 * t,
        ),
      );
  }

  @override
  bool shouldReclip(covariant _TrackCircleRevealClipper oldClipper) =>
      oldClipper.t != t || oldClipper.forward != forward;
}
