import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Анимация элемента списка относительно входа родительского маршрута.
///
/// Задержка рассчитывается от индекса, но ограничена 1200 мс для длинных
/// списков. Отдельная временная шкала позволяет последним элементам завершить
/// появление даже после окончания 700-миллисекундного кругового раскрытия.
class RevealStagger extends StatefulWidget {
  const RevealStagger({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<RevealStagger> createState() => _RevealStaggerState();
}

class _RevealStaggerState extends State<RevealStagger>
    with SingleTickerProviderStateMixin {
  static const int _firstDelayMs = 300;
  static const int _stepMs = 45;
  static const int _maxDelayMs = 1200;
  static const int _itemDurationMs = 520;
  static const int _timelineDurationMs = _maxDelayMs + _itemDurationMs;

  late final AnimationController _timelineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _timelineDurationMs),
  );

  Animation<double>? _routeAnimation;
  bool _hasStarted = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final nextAnimation = ModalRoute.of(context)?.animation;
    if (nextAnimation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_handleRouteStatus);
      _routeAnimation = nextAnimation;
      _routeAnimation?.addStatusListener(_handleRouteStatus);
    }

    if (_reduceMotion) {
      _timelineController.value = 1;
      _hasStarted = true;
    } else if (nextAnimation == null ||
        nextAnimation.status == AnimationStatus.completed) {
      // Полезно для элементов, созданных позже при прокрутке длинного списка.
      _startTimeline();
    } else if (nextAnimation.status == AnimationStatus.forward) {
      _startTimeline();
    }
  }

  void _handleRouteStatus(AnimationStatus status) {
    if (status == AnimationStatus.forward) {
      _startTimeline();
    } else if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      _timelineController.stop();
    }
  }

  void _startTimeline() {
    if (_hasStarted || _reduceMotion || !mounted) {
      return;
    }
    _hasStarted = true;
    _timelineController.forward(from: 0);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteStatus);
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return widget.child;
    }

    final delayMs = math.min(
      _firstDelayMs + math.max(0, widget.index) * _stepMs,
      _maxDelayMs,
    );
    final begin = delayMs / _timelineDurationMs;
    final end = (delayMs + _itemDurationMs) / _timelineDurationMs;

    final scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _timelineController,
        curve: Interval(begin, end, curve: Curves.easeOutBack),
      ),
    );
    final opacity = CurvedAnimation(
      parent: _timelineController,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: _timelineController,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: opacity.value.clamp(0.0, 1.0).toDouble(),
        child: Transform.scale(
          scale: scale.value,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Плавное появление заголовка и кнопки «назад» в первые 420 мс после задержки
/// 220 мс. Для маршрутов без анимации (например, вкладок) виджет прозрачен
/// к текущему состоянию: он просто возвращает дочерний элемент.
class RevealHeader extends StatelessWidget {
  const RevealHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }

    final routeAnimation = ModalRoute.of(context)?.animation;
    if (routeAnimation == null) return child;

    const totalDurationMs = 700.0;
    final headerAnimation = CurvedAnimation(
      parent: routeAnimation,
      curve: const Interval(
        220 / totalDurationMs,
        (220 + 420) / totalDurationMs,
        curve: Curves.easeOut,
      ),
    );
    return AnimatedBuilder(
      animation: headerAnimation,
      child: child,
      builder: (context, child) {
        final progress =
            headerAnimation.value.clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            // Это смещение в физических логических пикселях, а не доля высоты.
            offset: Offset(0, 10 * (1 - progress)),
            child: child,
          ),
        );
      },
    );
  }
}
