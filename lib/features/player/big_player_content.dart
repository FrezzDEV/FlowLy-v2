import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'player_controller.dart';

/// Демо-модель трека с картинкой, загружаемой стандартным ImageProvider.
class Track {
  const Track(
    this.title,
    this.artist,
    this.cover, {
    required this.id,
    required this.playerTrack,
  });

  final String id;
  final String title;
  final String artist;
  final ImageProvider cover;
  final PlayerTrack playerTrack;
}

enum DlState { idle, busy, done, deleting }

class CircleRevealClipper extends CustomClipper<Path> {
  CircleRevealClipper(this.t, this.forward);
  final double t;
  final bool forward;

  @override
  Path getClip(Size s) {
    final c = Offset(s.width * (forward ? .88 : .12), s.height * 1.12);
    return Path()
      ..addOval(Rect.fromCircle(center: c, radius: s.width * 1.7 * t));
  }

  @override
  bool shouldReclip(covariant CircleRevealClipper oldClipper) =>
      oldClipper.t != t || oldClipper.forward != forward;
}

/// Большой плеер остаётся смонтированным при сворачивании, чтобы состояния
/// лайков, загрузок и прерываемого reveal-перехода не терялись.
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
  static const double _durationSeconds = 201;
  static const _downloadDuration = Duration(milliseconds: 1300);

  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _t = 0;
  double _shown = 0;
  final ValueNotifier<double> _shownPosition = ValueNotifier<double>(0);

  late final AnimationController _reveal;
  late final CurvedAnimation _revealCurve;
  late final AnimationController _squeeze;
  late final Animation<double> _squeezeAnim;
  late final AnimationController _pop;
  late final Animation<double> _popAnim;
  late final AnimationController _ring;
  late final AnimationController _arrowController;
  late final AnimationController _doneController;
  late final AnimationController _del;

  Track? _current;
  Track? _coverTrack;
  Track? _incomingTrack;
  final List<Track> _history = [];
  bool _changing = false;
  bool _forward = true;
  bool _textDone = false;
  bool _reduceMotion = false;

  final Map<String, bool> _likes = <String, bool>{};
  final Set<String> _downloaded = <String>{};
  final Map<String, Timer> _busy = <String, Timer>{};
  final Map<String, DateTime> _busyStartedAt = <String, DateTime>{};
  DlState _dl = DlState.idle;

  PlayerController get _player => widget.player;
  Track get _track => _current!;
  Track get _cover => _coverTrack!;
  Track get _incoming => _incomingTrack!;

  static const Map<String, String> _coverUrls = {
    'Midnight Flow':
        'https://images.unsplash.com/photo-1519608487953-e999c86e7455?w=1000&auto=format&fit=crop&q=85',
    'Afterlife':
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=1000&auto=format&fit=crop&q=85',
    'Someone You Loved':
        'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=1000&auto=format&fit=crop&q=85',
    'Night Drive':
        'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=1000&auto=format&fit=crop&q=85',
    'The Night We Met':
        'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1000&auto=format&fit=crop&q=85',
    'Chill Bill':
        'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=1000&auto=format&fit=crop&q=85',
    'As It Was':
        'https://images.unsplash.com/photo-1518837695005-2083093ee35b?w=1000&auto=format&fit=crop&q=85',
    'Sweater Weather':
        'https://images.unsplash.com/photo-1516280440614-37939bbacd81?w=1000&auto=format&fit=crop&q=85',
  };

  Track _trackFor(PlayerTrack source) {
    final url = _coverUrls[source.title] ?? _coverUrls.values.first;
    return Track(
      source.title,
      source.artist,
      NetworkImage(url),
      id: '${source.title}|${source.artist}',
      playerTrack: source,
    );
  }

  @override
  void initState() {
    super.initState();
    _current = _trackFor(_player.currentTrack);
    _coverTrack = _current;
    _incomingTrack = _current;
    _t = (_player.progress * _durationSeconds)
        .clamp(0.0, _durationSeconds).toDouble();
    _shown = _t;
    _shownPosition.value = _shown;

    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(_handleRevealValue);
    _revealCurve = CurvedAnimation(
      parent: _reveal,
      curve: const Cubic(.7, 0, .2, 1),
    );
    _reveal.addStatusListener(_handleRevealStatus);

    _squeeze = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _squeezeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: .96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: .96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 70,
      ),
    ]).animate(_squeeze);

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

    _ring = AnimationController(
      vsync: this,
      duration: _downloadDuration,
    );
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
    _player.setExternalPlaybackClock(true);
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
      if (mounted) _precacheAround(_track);
    });
    _refreshDownload(animate: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == _reduceMotion) return;
    _reduceMotion = reduce;
    final shortDuration =
        reduce ? Duration.zero : const Duration(milliseconds: 200);
    _reveal.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 700);
    _squeeze.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 900);
    _pop.duration = reduce ? Duration.zero : const Duration(milliseconds: 380);
    _ring.duration = reduce ? Duration.zero : _downloadDuration;
    _arrowController.duration = shortDuration;
    _doneController.duration = shortDuration;
    _del.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 1250);
    if (reduce && _changing) _finishChange();
  }

  @override
  void didUpdateWidget(covariant BigPlayerContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    _lastElapsed = null;
    if (widget.active) {
      _ticker.start();
    } else {
      _ticker.stop();
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
      if (_t >= _durationSeconds && !_changing) {
        _t = _durationSeconds;
        _changeTrack(1);
        return;
      }
    }
    _shown += (_t - _shown) * math.min(1.0, dt * 12.0).toDouble();
    _shownPosition.value = _shown.clamp(0.0, _durationSeconds).toDouble();

    // Общая позиция синхронизируется раз в секунду; кадры обновляют только
    // ValueNotifier полосы времени, а не весь экран.
    if (_player.isPlaying && _t.floor() != previousWholeSecond) {
      _player.setExternalProgress(_t / _durationSeconds);
    }
  }

  void _handleRevealValue() {
    if (!_changing || _textDone || _reveal.value < .4) return;
    _textDone = true;
    final incoming = _incoming;
    setState(() => _current = incoming);
    _syncPlayerTo(incoming);
    _refreshLike();
    _refreshDownload();
  }

  void _handleRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finishChange();
  }

  void _finishChange() {
    if (!_changing) return;
    final incoming = _incoming;
    _changing = false;
    _reveal.stop();
    _squeeze.stop();
    setState(() {
      _coverTrack = incoming;
      _current = incoming;
    });
    _reveal.value = 0;
    _squeeze.value = 0;
    _syncPlayerTo(incoming);
    _refreshLike();
    _refreshDownload();
  }

  void _changeTrack(int dir, [Track? song]) {
    _finishChange();
    final current = _track;
    final next = song ?? _adjacentTrack(current, dir);

    _changing = true;
    _forward = dir > 0;
    _incomingTrack = next;
    _textDone = false;
    if (dir > 0) _history.add(current);
    _t = 0;

    _precacheAround(next);
    _reveal.forward(from: 0);
    _squeeze.forward(from: 0);
  }

  Track _adjacentTrack(Track current, int direction) {
    final tracks = PlayerController.catalog;
    final currentIndex = tracks.indexWhere((item) =>
        item.title == current.title && item.artist == current.artist);
    final start = currentIndex < 0 ? 0 : currentIndex;
    final index = (start + direction + tracks.length) % tracks.length;
    return _trackFor(tracks[index]);
  }

  void _syncPlayerTo(Track track) {
    final source = track.playerTrack;
    if (_player.currentTrack.title == source.title &&
        _player.currentTrack.artist == source.artist) {
      return;
    }
    _player.playTrack(source);
  }

  void _precacheAround(Track track) {
    final tracks = PlayerController.catalog;
    final currentIndex = tracks.indexWhere((item) =>
        item.title == track.title && item.artist == track.artist);
    if (currentIndex < 0 || tracks.length < 2) return;
    final previous =
        _trackFor(tracks[(currentIndex - 1 + tracks.length) % tracks.length]);
    final next = _trackFor(tracks[(currentIndex + 1) % tracks.length]);
    for (final item in [previous, next]) {
      unawaited(precacheImage(item.cover, context, onError: (exception, stackTrace) {}));
    }
  }

  void _handlePlayerChanged() {
    final fromPlayer = _trackFor(_player.currentTrack);
    if (_changing && fromPlayer.id == _incoming.id) {
      return; // Синхронизация собственного трека на 40% reveal.
    }

    if (fromPlayer.id != _track.id) {
      _changing = false;
      _reveal.stop();
      _squeeze.stop();
      setState(() {
        _current = fromPlayer;
        _coverTrack = fromPlayer;
        _incomingTrack = fromPlayer;
        _t = (_player.progress * _durationSeconds)
            .clamp(0.0, _durationSeconds).toDouble();
        _shown = _t;
        _shownPosition.value = _shown;
      });
      _reveal.value = 0;
      _squeeze.value = 0;
      _precacheAround(fromPlayer);
      _refreshLike();
      _refreshDownload();
      return;
    }

    final favorite = _isFavorite(_track);
    if (_likes[_track.id] != favorite) {
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
    if (_likes[_track.id] == liked) return;
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
    if (before.length != _downloaded.length) return true;
    return !before.containsAll(_downloaded);
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
        final elapsed = started == null
            ? 0
            : DateTime.now().difference(started).inMilliseconds;
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
          target,
          disableAnimations: _reduceMotion,
        );
        if (ok != true || !mounted) return;
        _downloaded.remove(target.title);
        await _player.removeTrackFromPlaylist(
          PlayerController.downloadsPlaylistId,
          target.playerTrack,
        );
        if (!mounted) return;
        if (identical(_current, target)) {
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
        return;
    }
  }

  void _seekBy(double delta) {
    _t = (_t + delta).clamp(0.0, _durationSeconds).toDouble();
    _shown = _t;
    _shownPosition.value = _shown;
    _player.setExternalProgress(_t / _durationSeconds);
  }

  void _onPrevious() {
    if (_t > 3 || _history.isEmpty) {
      _t = 0;
      _shown = 0;
      _shownPosition.value = 0;
      _player.setExternalProgress(0);
      return;
    }
    _changeTrack(-1, _history.removeLast());
  }

  static String _formatSeconds(double value) {
    final total = value.floor().clamp(0, 201);
    final minutes = total ~/ 60;
    final seconds = total % 60;
    return '$minutes:${seconds.toString().padLeft(2, "0")}';
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
    _reveal.removeListener(_handleRevealValue);
    _reveal.removeStatusListener(_handleRevealStatus);
    _revealCurve.dispose();
    _reveal.dispose();
    _squeeze.dispose();
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
    final bg = scheme.surface;
    final hint = scheme.onSurfaceVariant;
    final size = MediaQuery.sizeOf(context);
    final coverWidth = math.min(size.width * .8, 360.0).toDouble();

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.paddingOf(context).top + 60,
              16,
              MediaQuery.paddingOf(context).bottom + 16,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: coverWidth,
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _buildCover(coverWidth),
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: coverWidth,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TrackMeta(
                                track: _track,
                                reduceMotion: _reduceMotion,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(8, 0),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: _LikeAction(
                                  liked: _likes[_track.id] ?? _isFavorite(_track),
                                  pop: _popAnim,
                                  duration: _reduceMotion
                                      ? Duration.zero
                                      : const Duration(milliseconds: 200),
                                  ink: ink,
                                  onTap: _onLikeTap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: coverWidth,
                        child: _ProgressAndTime(
                          position: _shownPosition,
                          ink: ink,
                          hint: hint,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: constraints.maxWidth,
                        height: 64,
                        child: _buildControls(ink, bg, constraints.maxWidth),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCover(double width) {
    return AnimatedBuilder(
      animation: Listenable.merge([_revealCurve, _squeezeAnim]),
      builder: (context, _) => Transform.scale(
        scale: _squeezeAnim.value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(width * .132),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                blurRadius: 40,
                spreadRadius: -18,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(width * .132),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _TrackImage(track: _cover),
                if (_changing)
                  ClipPath(
                    clipper: CircleRevealClipper(_revealCurve.value, _forward),
                    child: _TrackImage(track: _incoming),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CoverSeekMark(
                        icon: Icons.skip_previous_rounded,
                        label: '-10',
                        onTap: () => _seekBy(-10),
                      ),
                      _CoverSeekMark(
                        icon: Icons.skip_next_rounded,
                        label: '+10',
                        onTap: () => _seekBy(10),
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
  }

  Widget _buildControls(Color ink, Color bg, double width) {
    final narrow = MediaQuery.sizeOf(context).width < 320;
    final gap = narrow ? 12.0 : 20.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Align(
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PressScale(
                label: 'Предыдущий трек',
                width: 52,
                height: 52,
                scaleDown: .88,
                ink: ink,
                onTap: _onPrevious,
                child: Icon(Icons.skip_previous_rounded, size: 28, color: ink),
              ),
              SizedBox(width: gap),
              _PressScale(
                label: _player.isPlaying ? 'Пауза' : 'Играть',
                width: 64,
                height: 64,
                scaleDown: .94,
                ink: bg,
                background: ink,
                onTap: _player.togglePlay,
                child: Icon(
                  _player.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 26,
                  color: bg,
                ),
              ),
              SizedBox(width: gap),
              _PressScale(
                label: 'Следующий трек',
                width: 52,
                height: 52,
                scaleDown: .88,
                ink: ink,
                onTap: () => _changeTrack(1),
                child: Icon(Icons.skip_next_rounded, size: 28, color: ink),
              ),
            ],
          ),
        ),
        Positioned(
          left: width / 2 + 84 + gap + 8,
          top: 10,
          width: 44,
          height: 44,
          child: _PressScale(
            label: _dl == DlState.deleting
                ? 'Удаление загрузки'
                : _dl == DlState.done
                    ? 'Удалить из загрузок'
                    : _dl == DlState.busy
                        ? 'Отменить загрузку'
                        : 'Скачать трек',
            width: 44,
            height: 44,
            scaleDown: .88,
            ink: ink,
            onTap: _dl == DlState.deleting
                ? null
                : () => unawaited(_onDownloadTap()),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _ring,
                _arrowController,
                _doneController,
                _del,
              ]),
              builder: (context, _) => CustomPaint(
                size: const Size(24, 24),
                painter: DownloadPainter(
                  state: _dl,
                  ink: ink,
                  ring: _ring.value,
                  arrowScale: 1 - .45 * _arrowController.value,
                  arrowAlpha: 1 - _doneController.value,
                  checkAlpha: _doneController.value,
                  del: _del.value,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TrackMeta extends StatelessWidget {
  const TrackMeta({
    super.key,
    required this.track,
    required this.reduceMotion,
  });

  final Track track;
  final bool reduceMotion;
  static const int _out = 150;
  static const int _in = 240;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRect(
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: _out + _in),
        reverseDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: _out),
        switchInCurve: reduceMotion
            ? Curves.linear
            : const Interval(
                _out / (_out + _in),
                1,
                curve: Cubic(.2, .8, .2, 1),
              ),
        switchOutCurve: Curves.linear,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey<String>(track.id);
          final slide = Tween<Offset>(
            begin: Offset(0, incoming ? .4 : -.4),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: Column(
          key: ValueKey<String>(track.id),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 21,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              track.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackImage extends StatelessWidget {
  const _TrackImage({required this.track});
  final Track track;

  @override
  Widget build(BuildContext context) => Image(
        image: track.cover,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF24272B),
          alignment: Alignment.center,
          child: Icon(
            track.playerTrack.icon,
            color: Colors.white.withValues(alpha: .9),
            size: 72,
          ),
        ),
      );
}

class _CoverSeekMark extends StatelessWidget {
  const _CoverSeekMark({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label == '+10' ? 'Перемотать вперёд на 10 секунд' : 'Перемотать назад на 10 секунд',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 19, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ProgressAndTime extends StatelessWidget {
  const _ProgressAndTime({
    required this.position,
    required this.ink,
    required this.hint,
  });
  final ValueNotifier<double> position;
  final Color ink;
  final Color hint;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 5,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: ink.withValues(alpha: .16)),
                  ValueListenableBuilder<double>(
                    valueListenable: position,
                    builder: (context, seconds, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: (seconds / 201).clamp(0.0, 1.0).toDouble(),
                        child: ColoredBox(color: ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: position,
            builder: (context, seconds, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _BigPlayerContentState._formatSeconds(seconds),
                  style: TextStyle(
                    color: hint,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  '3:21',
                  style: TextStyle(
                    color: hint,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
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
          child: Center(
            child: AnimatedBuilder(
              animation: pop,
              builder: (context, child) => Transform.scale(
                scale: pop.value,
                child: child,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(
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
        ),
      );
}

class _PressScale extends StatefulWidget {
  const _PressScale({
    required this.child,
    required this.onTap,
    required this.label,
    required this.width,
    required this.height,
    required this.scaleDown,
    required this.ink,
    this.background = Colors.transparent,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String label;
  final double width;
  final double height;
  final double scaleDown;
  final Color ink;
  final Color background;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return FocusableActionDetector(
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? widget.scaleDown : 1,
            duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: widget.background,
                shape: BoxShape.circle,
                border: _focused
                    ? Border.all(
                        color: widget.ink.withValues(alpha: .7),
                        width: 1.4,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
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

    canvas.restore(); // off-screen group
    canvas.restore(); // scaled group
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
  Track track, {
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
  final Track track;

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
