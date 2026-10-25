import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/flowly_accent.dart';
import 'player_controller.dart';
import 'vertical_track_label.dart';

class Track {
  const Track(
    this.title,
    this.artist, {
    required this.id,
    required this.playerTrack,
  });

  final String id;
  final String title;
  final String artist;
  final PlayerTrack playerTrack;
}

enum DlState { idle, busy, done, deleting }

/// Старый макет большого плеера с отдельными, независимыми анимациями лайка
/// и скачивания/удаления. Воспроизведение остаётся демо-режимом без аудиодвижка.
class BigPlayerContent extends StatefulWidget {
  const BigPlayerContent({
    super.key,
    required this.player,
    required this.active,
  });

  final PlayerController player;
  final bool active;

  @override
  State<BigPlayerContent> createState() => _BigPlayerContentState();
}

class _BigPlayerContentState extends State<BigPlayerContent>
    with TickerProviderStateMixin {
  static const _downloadDuration = Duration(milliseconds: 1300);

  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _t = 0;
  double _shown = 0;
  final ValueNotifier<double> _shownPosition = ValueNotifier<double>(0);

  late final AnimationController _pop;
  late final Animation<double> _popAnim;
  late final AnimationController _ring;
  late final AnimationController _arrowController;
  late final AnimationController _doneController;
  late final AnimationController _del;

  late Track _track;
  final Map<String, bool> _likes = <String, bool>{};
  final Set<String> _downloaded = <String>{};
  final Map<String, Timer> _busy = <String, Timer>{};
  final Map<String, DateTime> _busyStartedAt = <String, DateTime>{};
  DlState _dl = DlState.idle;
  bool _reduceMotion = false;
  bool _transportPressed = false;

  PlayerController get _player => widget.player;
  double get _durationSeconds =>
      math.max(1.0, _track.playerTrack.duration.inMilliseconds / 1000.0);

  Track _trackFor(PlayerTrack source) => Track(
        source.title,
        source.artist,
        id: '${source.title}|${source.artist}',
        playerTrack: source,
      );

  @override
  void initState() {
    super.initState();
    _track = _trackFor(_player.currentTrack);
    _t = _player.progress * _durationSeconds;
    _shown = _t;
    _shownPosition.value = _shown;

    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _popAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3)
            .chain(CurveTween(curve: const Cubic(.3, 1.6, .5, 1))),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 55,
      ),
    ]).animate(_pop);

    _ring = AnimationController(vsync: this, duration: _downloadDuration);
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _doneController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _del = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );

    _player.addListener(_handlePlayerChanged);
    _player.setExternalPlaybackClock(widget.active);
    _downloaded.addAll(
      _player.playlistById(PlayerController.downloadsPlaylistId)
              ?.tracks.map((item) => item.title) ??
          const <String>[],
    );
    for (final item in _player
            .playlistById(PlayerController.favoritesPlaylistId)
            ?.tracks ??
        const <PlayerTrack>[]) {
      _likes['${item.title}|${item.artist}'] = true;
    }

    _ticker = createTicker(_onTick);
    if (widget.active) _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshDownload(animate: false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    final short = reduce ? Duration.zero : const Duration(milliseconds: 200);
    _pop.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 380);
    _ring.duration = reduce ? Duration.zero : _downloadDuration;
    _arrowController.duration = short;
    _doneController.duration = short;
    _del.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 1250);
  }

  @override
  void didUpdateWidget(covariant BigPlayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    _lastElapsed = null;
    if (widget.active) {
      // Re-sync to the internal playback clock after the mini-player was active.
      _t = (_player.progress * _durationSeconds)
          .clamp(0.0, _durationSeconds).toDouble();
      _shown = _t;
      _shownPosition.value = _shown;
      _player.setExternalPlaybackClock(true);
      _ticker.start();
    } else {
      _ticker.stop();
      _player.setExternalPlaybackClock(false);
    }
  }

  void _onTick(Duration elapsed) {
    final previous = _lastElapsed;
    _lastElapsed = elapsed;
    if (previous == null) return;
    final dt = (elapsed - previous).inMicroseconds / 1000000.0;
    if (dt <= 0) return;

    final previousWholeSecond = _t.floor();
    if (_player.isPlaying) {
      _t += dt;
      if (_t >= _durationSeconds) {
        _player.next();
        return;
      }
    }

    _shown += (_t - _shown) * math.min(1.0, dt * 12.0).toDouble();
    _shownPosition.value = _shown.clamp(0.0, _durationSeconds).toDouble();

    if (_player.isPlaying && _t.floor() != previousWholeSecond) {
      _player.setExternalProgress(_t / _durationSeconds);
    }
  }

  void _handlePlayerChanged() {
    final next = _trackFor(_player.currentTrack);
    if (next.id != _track.id) {
      // Если во время анимации удаления переключили песню, отменяем только её.
      if (_dl == DlState.deleting) {
        _del.stop();
        _del.value = 0;
      }
      _track = next;
      _t = (_player.progress * _durationSeconds)
          .clamp(0.0, _durationSeconds).toDouble();
      _shown = _t;
      _shownPosition.value = _shown;
      _refreshLike();
      _refreshDownload();
      if (mounted) setState(() {});
      return;
    }

    final favorite = _isFavorite(_track);
    if (_likes[_track.id] != favorite && mounted) {
      setState(() => _likes[_track.id] = favorite);
    }
    if (_syncDownloadsFromLibrary()) _refreshDownload();
  }

  bool _isFavorite(Track track) =>
      _player
          .playlistById(PlayerController.favoritesPlaylistId)
          ?.tracks
          .any((item) =>
              item.title == track.title && item.artist == track.artist) ??
      false;

  void _refreshLike() {
    final liked = _isFavorite(_track);
    if (_likes[_track.id] == liked || !mounted) return;
    setState(() => _likes[_track.id] = liked);
  }

  void _onLikeTap() {
    final liked = !(_likes[_track.id] ?? _isFavorite(_track));
    setState(() => _likes[_track.id] = liked);
    _pop.forward(from: 0);
    if (liked) {
      unawaited(_player.addTrackToPlaylist(
        PlayerController.favoritesPlaylistId,
        _track.playerTrack,
      ));
    } else {
      unawaited(_player.removeTrackFromPlaylist(
        PlayerController.favoritesPlaylistId,
        _track.playerTrack,
      ));
    }
  }

  bool _syncDownloadsFromLibrary() {
    final fromLibrary = _player
            .playlistById(PlayerController.downloadsPlaylistId)
            ?.tracks
            .map((item) => item.title)
            .toSet() ??
        <String>{};
    final before = Set<String>.from(_downloaded);
    _downloaded.addAll(fromLibrary);
    _downloaded.removeWhere(
      (title) => !fromLibrary.contains(title) && !_busy.containsKey(title),
    );
    return before.length != _downloaded.length ||
        !before.containsAll(_downloaded);
  }

  void _refreshDownload({bool animate = true}) {
    if (!mounted) return;
    final title = _track.title;
    final nextState = _downloaded.contains(title)
        ? DlState.done
        : _busy.containsKey(title)
            ? DlState.busy
            : DlState.idle;

    if (_dl == DlState.deleting && nextState != DlState.deleting) {
      _del.stop();
      _del.value = 0;
    }
    if (_dl != nextState) setState(() => _dl = nextState);

    switch (nextState) {
      case DlState.idle:
        _ring.stop();
        _ring.value = 0;
        if (animate) {
          _arrowController.reverse();
          _doneController.reverse();
        } else {
          _arrowController.value = 0;
          _doneController.value = 0;
        }
        break;
      case DlState.busy:
        _doneController.value = 0;
        if (animate) {
          _arrowController.forward();
        } else {
          _arrowController.value = 1;
        }
        final started = _busyStartedAt[title];
        final elapsed =
            started == null ? 0 : DateTime.now().difference(started).inMilliseconds;
        final progress = (elapsed / _downloadDuration.inMilliseconds)
            .clamp(0.0, 1.0).toDouble();
        _ring.stop();
        _ring.value = progress;
        if (progress < 1) {
          _ring.animateTo(
            1,
            duration: Duration(
              milliseconds: math.max(
                0,
                _downloadDuration.inMilliseconds - elapsed,
              ).toInt(),
            ),
            curve: Curves.linear,
          );
        }
        break;
      case DlState.done:
        _ring.stop();
        _ring.value = 1;
        if (animate) {
          _arrowController.forward();
          _doneController.forward();
        } else {
          _arrowController.value = 1;
          _doneController.value = 1;
        }
        break;
      case DlState.deleting:
        break;
    }
  }

  void _startDownload() {
    final title = _track.title;
    if (_busy.containsKey(title)) return;
    final target = _track;
    _busyStartedAt[title] = DateTime.now();
    setState(() => _dl = DlState.busy);
    _arrowController.forward();
    _doneController.reverse();
    _ring.forward(from: 0);
    final delay = _reduceMotion ? Duration.zero : _downloadDuration;
    _busy[title] = Timer(delay, () {
      _busy.remove(title);
      _busyStartedAt.remove(title);
      _downloaded.add(title);
      unawaited(_player.addTrackToPlaylist(
        PlayerController.downloadsPlaylistId,
        target.playerTrack,
      ));
      if (!mounted || _track.title != title) return;
      setState(() => _dl = DlState.done);
      _ring.stop();
      _ring.value = 1;
      _arrowController.forward();
      _doneController.forward();
    });
  }

  void _cancelDownload() {
    final title = _track.title;
    _busy.remove(title)?.cancel();
    _busyStartedAt.remove(title);
    _ring.stop();
    _ring.value = 0;
    setState(() => _dl = DlState.idle);
    _arrowController.reverse();
    _doneController.reverse();
  }

  Future<void> _onDownloadTap() async {
    switch (_dl) {
      case DlState.idle:
        _startDownload();
        break;
      case DlState.busy:
        _cancelDownload();
        break;
      case DlState.done:
        final target = _track;
        final ok = await showDeleteDialog(
          context,
          target.playerTrack,
          disableAnimations: _reduceMotion,
        );
        if (ok != true || !mounted) return;
        _downloaded.remove(target.title);
        await _player.removeTrackFromPlaylist(
          PlayerController.downloadsPlaylistId,
          target.playerTrack,
        );
        if (!mounted) return;
        if (_track.id == target.id) {
          setState(() => _dl = DlState.deleting);
          try {
            await _del.forward(from: 0).orCancel;
          } on TickerCanceled {
            return;
          }
          if (mounted && _dl == DlState.deleting) {
            setState(() => _dl = DlState.idle);
            _arrowController.reverse();
            _doneController.reverse();
            _ring.value = 0;
          }
        } else {
          _refreshDownload();
        }
        break;
      case DlState.deleting:
        break;
    }
  }

  Future<void> _shareCurrentTrack() async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'FlowLy',
        text: '${_track.title} — ${_track.artist}\nСлушаю в FlowLy',
      ),
    );
  }

  void _seek(double value) {
    _t = (value * _durationSeconds).clamp(0.0, _durationSeconds).toDouble();
    _shown = _t;
    _shownPosition.value = _shown;
    _player.setExternalProgress(value.clamp(0.0, 1.0).toDouble());
  }

  static String _formatSeconds(double value) {
    final total = value.floor().clamp(0, 24 * 60 * 60);
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.removeListener(_handlePlayerChanged);
    _player.setExternalPlaybackClock(false);
    _ticker.dispose();
    for (final timer in _busy.values) {
      timer.cancel();
    }
    _busy.clear();
    _shownPosition.dispose();
    _pop.dispose();
    _ring.dispose();
    _arrowController.dispose();
    _doneController.dispose();
    _del.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final duration = _durationSeconds;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VerticalTrackLabel(
                      text: _track.title,
                      trackKey: _track.id,
                      height: 58,
                      duration: _reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 230),
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    VerticalTrackLabel(
                      text: _track.artist,
                      trackKey: _track.id,
                      height: 24,
                      duration: _reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 210),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _LikeAction(
                liked: _likes[_track.id] ?? _isFavorite(_track),
                pop: _popAnim,
                duration: _reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                ink: ink,
                onTap: _onLikeTap,
              ),
            ],
          ),
          const SizedBox(height: 28),
          ValueListenableBuilder<double>(
            valueListenable: _shownPosition,
            builder: (context, seconds, _) => Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: FlowLyAccent.color,
                      inactiveTrackColor: Colors.black,
                      thumbColor: FlowLyAccent.color,
                      overlayColor: Colors.transparent,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: (seconds / duration).clamp(0.0, 1.0).toDouble(),
                      onChanged: _seek,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatSeconds(seconds),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        _formatSeconds(duration),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundAction(
                icon: Icons.share_rounded,
                label: 'Поделиться треком',
                onTap: () => unawaited(_shareCurrentTrack()),
              ),
              _RoundAction(
                icon: Icons.skip_previous_rounded,
                label: 'Предыдущий трек',
                onTap: _player.previous,
              ),
              Semantics(
                button: true,
                label: _player.isPlaying ? 'Пауза' : 'Играть',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _player.togglePlay,
                  onTapDown: (_) => setState(() => _transportPressed = true),
                  onTapUp: (_) => setState(() => _transportPressed = false),
                  onTapCancel: () => setState(() => _transportPressed = false),
                  child: AnimatedScale(
                    scale: _transportPressed ? .9 : 1,
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              _RoundAction(
                icon: Icons.skip_next_rounded,
                label: 'Следующий трек',
                onTap: _player.next,
              ),
              _DownloadAction(
                state: _dl,
                ink: ink,
                ring: _ring,
                arrowController: _arrowController,
                doneController: _doneController,
                deleting: _del,
                reduceMotion: _reduceMotion,
                onTap: _dl == DlState.deleting
                    ? null
                    : () => unawaited(_onDownloadTap()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatefulWidget {
  const _RoundAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_RoundAction> createState() => _RoundActionState();
}

class _RoundActionState extends State<_RoundAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedScale(
                scale: _pressed ? .82 : 1,
                duration: const Duration(milliseconds: 90),
                curve: Curves.easeOut,
                child: Icon(widget.icon, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      );
}

class _LikeAction extends StatelessWidget {
  const _LikeAction({
    required this.liked,
    required this.pop,
    required this.duration,
    required this.ink,
    required this.onTap,
  });

  final bool liked;
  final Animation<double> pop;
  final Duration duration;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: liked,
        label: liked ? 'Убрать из избранного' : 'Добавить в избранное',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedBuilder(
                animation: pop,
                builder: (context, child) => Transform.scale(
                  scale: pop.value,
                  child: child,
                ),
                child: AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey<bool>(liked),
                    color: liked ? const Color(0xFFE0313F) : ink,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _DownloadAction extends StatelessWidget {
  const _DownloadAction({
    required this.state,
    required this.ink,
    required this.ring,
    required this.arrowController,
    required this.doneController,
    required this.deleting,
    required this.reduceMotion,
    required this.onTap,
  });

  final DlState state;
  final Color ink;
  final AnimationController ring;
  final AnimationController arrowController;
  final AnimationController doneController;
  final AnimationController deleting;
  final bool reduceMotion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: state == DlState.deleting
            ? 'Удаление загрузки'
            : state == DlState.done
                ? 'Удалить из загрузок'
                : state == DlState.busy
                    ? 'Отменить загрузку'
                    : 'Скачать трек',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  ring,
                  arrowController,
                  doneController,
                  deleting,
                ]),
                builder: (context, _) => AnimatedScale(
                  scale: 1,
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 150),
                  child: CustomPaint(
                    size: const Size(24, 24),
                    painter: DownloadPainter(
                      state: state,
                      ink: ink,
                      ring: ring.value,
                      arrowScale: 1 - .45 * arrowController.value,
                      arrowAlpha: 1 - doneController.value,
                      checkAlpha: doneController.value,
                      del: deleting.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class DownloadPainter extends CustomPainter {
  const DownloadPainter({
    required this.state,
    required this.ink,
    required this.ring,
    required this.arrowScale,
    required this.arrowAlpha,
    required this.checkAlpha,
    required this.del,
  });

  final DlState state;
  final Color ink;
  final double ring;
  final double arrowScale;
  final double arrowAlpha;
  final double checkAlpha;
  final double del;

  Paint _stroke([double alpha = 1]) => Paint()
    ..color = ink.withValues(alpha: alpha.clamp(0.0, 1.0).toDouble())
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    if (state == DlState.deleting) {
      _paintDeleting(canvas);
      canvas.restore();
      return;
    }
    if (state == DlState.busy || state == DlState.done) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(12, 12), radius: 9),
        -math.pi / 2,
        2 * math.pi * ring.clamp(0.0, 1.0).toDouble(),
        false,
        _stroke(),
      );
    }
    if (arrowAlpha > 0) {
      canvas.save();
      canvas.translate(12, 12);
      canvas.scale(arrowScale);
      canvas.translate(-12, -12);
      final paint = _stroke(arrowAlpha);
      final path = Path()
        ..moveTo(12, 4)
        ..lineTo(12, 15)
        ..moveTo(7.5, 10.5)
        ..lineTo(12, 15)
        ..lineTo(16.5, 10.5);
      canvas.drawPath(path, paint);
      if (state == DlState.idle || state == DlState.busy) {
        canvas.drawLine(const Offset(5, 20), const Offset(19, 20), paint);
      }
      canvas.restore();
    }
    if (checkAlpha > 0) {
      final check = Path()
        ..moveTo(7.5, 12.5)
        ..lineTo(10.5, 15.5)
        ..lineTo(16.5, 9);
      canvas.drawPath(check, _stroke(checkAlpha));
    }
    canvas.restore();
  }

  void _paintDeleting(Canvas canvas) {
    final ms = del.clamp(0.0, 1.0).toDouble() * 1250;
    final u = del.clamp(0.0, 1.0).toDouble();
    final q = ((ms - 1000) / 250).clamp(0.0, 1.0).toDouble();

    canvas.save();
    canvas.translate(12, 20.5);
    canvas.scale(1 - .4 * q);
    canvas.translate(-12, -20.5);
    canvas.saveLayer(
      const Rect.fromLTWH(0, 0, 24, 24),
      Paint()..color = ink.withValues(alpha: 1 - q),
    );

    final circle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, 18, 18),
      const Radius.circular(9),
    );
    final bin = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6.5, 9, 11, 11.5),
      const Radius.circular(2.4),
    );
    final morph = Curves.easeInOutCubic.transform(
      (ms / 420).clamp(0.0, 1.0).toDouble(),
    );
    canvas.drawRRect(RRect.lerp(circle, bin, morph)!, _stroke());

    final lidAlpha = _keys(u, const [(0, 0), (.22, 0), (.34, 1), (1, 1)]);
    final dy = _keys(u, const [(0, -5), (.22, -5), (.34, 0), (1, 0)]);
    final angle = _keys(
      u,
      const [(0, 0), (.34, 0), (.46, 26), (.62, 26), (.74, 0), (1, 0)],
    );
    final lid = Path()
      ..moveTo(4.5, 6.5)
      ..lineTo(19.5, 6.5)
      ..moveTo(9.5, 6.5)
      ..lineTo(9.5, 5)
      ..cubicTo(9.5, 4.3, 10, 3.8, 10.7, 3.8)
      ..lineTo(13.3, 3.8)
      ..cubicTo(14, 3.8, 14.5, 4.3, 14.5, 5)
      ..lineTo(14.5, 6.5);
    canvas.save();
    canvas.translate(0, dy);
    canvas.translate(19.5, 6.5);
    canvas.rotate(angle * math.pi / 180);
    canvas.translate(-19.5, -6.5);
    canvas.drawPath(lid, _stroke(lidAlpha));
    canvas.restore();

    final interiorAlpha =
        _keys(u, const [(0, 0), (.28, 0), (.40, 1), (.84, 1), (1, 1)]);
    final interior = _stroke(interiorAlpha);
    canvas.drawLine(const Offset(10.2, 12.2), const Offset(10.2, 17.5), interior);
    canvas.drawLine(const Offset(13.8, 12.2), const Offset(13.8, 17.5), interior);

    final ck = Curves.easeIn.transform(
      ((ms - 300) / 500).clamp(0.0, 1.0).toDouble(),
    );
    canvas.save();
    canvas.translate(12, 12.25 + 6 * ck);
    canvas.scale(1 - .65 * ck);
    canvas.translate(-12, -12.25);
    final check = Path()
      ..moveTo(7.5, 12.5)
      ..lineTo(10.5, 15.5)
      ..lineTo(16.5, 9);
    canvas.drawPath(check, _stroke(1 - ck));
    canvas.restore();

    canvas.restore();
    canvas.restore();
  }

  static double _keys(double u, List<(double, double)> k) {
    if (u <= k.first.$1) return k.first.$2;
    for (var i = 1; i < k.length; i++) {
      if (u <= k[i].$1) {
        final a = k[i - 1];
        final b = k[i];
        return a.$2 + (b.$2 - a.$2) * ((u - a.$1) / (b.$1 - a.$1));
      }
    }
    return k.last.$2;
  }

  @override
  bool shouldRepaint(covariant DownloadPainter oldDelegate) =>
      oldDelegate.state != state ||
      oldDelegate.ink != ink ||
      oldDelegate.ring != ring ||
      oldDelegate.arrowScale != arrowScale ||
      oldDelegate.arrowAlpha != arrowAlpha ||
      oldDelegate.checkAlpha != checkAlpha ||
      oldDelegate.del != del;
}

Future<bool?> showDeleteDialog(
  BuildContext context,
  PlayerTrack track, {
  required bool disableAnimations,
}) {
  return showGeneralDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: 'Закрыть',
    barrierColor: Colors.black.withValues(alpha: .5),
    transitionDuration: disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 240),
    pageBuilder: (ctx, _, __) => _DeleteDialog(track: track),
    transitionBuilder: (ctx, animation, _, child) {
      if (disableAnimations) return child;
      final curve = CurvedAnimation(
        parent: animation,
        curve: const Cubic(.3, 1.3, .5, 1),
        reverseCurve: Curves.easeIn,
      );
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .05),
            end: Offset.zero,
          ).animate(curve),
          child: ScaleTransition(
            scale: Tween<double>(begin: .92, end: 1).animate(curve),
            child: child,
          ),
        ),
      );
    },
  );
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.track});
  final PlayerTrack track;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onSurface;
    final body =
        'Трек «${track.title}» от автора ${track.artist} будет удалён из загрузок.';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: 'Удалить трек? $body',
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            elevation: 16,
            shadowColor: Colors.black.withValues(alpha: .24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: ink.withValues(alpha: .1)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Удалить трек?',
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextButton(
                            autofocus: true,
                            onPressed: () => Navigator.of(context).pop(false),
                            style: TextButton.styleFrom(
                              backgroundColor: ink.withValues(alpha: .1),
                              foregroundColor: ink,
                              shape: const StadiumBorder(),
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text('Нет'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE0313F),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              overlayColor: Colors.transparent,
                            ),
                            child: const Text('Да'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
