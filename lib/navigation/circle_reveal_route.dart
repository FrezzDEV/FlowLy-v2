import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Маршрут с круговым раскрытием, не зависящим от содержимого страницы.
class CircleRevealRoute<T> extends PageRouteBuilder<T> {
  CircleRevealRoute({
    required this.page,
    required this.origin,
    this.backButtonKey,
    this.backgroundColor,
    this.disableAnimations = false,
  }) : super(
          opaque: true,
          allowSnapshotting: true,
          transitionDuration: Duration(
            milliseconds: disableAnimations ? 150 : 700,
          ),
          reverseTransitionDuration: Duration(
            milliseconds: disableAnimations ? 150 : 560,
          ),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (
            context,
            animation,
            secondaryAnimation,
            child,
          ) {
            final reduceMotion = disableAnimations ||
                (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

            if (reduceMotion) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            }

            return _CircleRevealTransition(
              animation: animation,
              origin: origin,
              backButtonKey: backButtonKey,
              backgroundColor: backgroundColor,
              child: child,
            );
          },
        );

  final Widget page;

  /// Глобальная позиция нажатия, откуда начинается круг.
  final Offset origin;

  final GlobalKey? backButtonKey;
  final Color? backgroundColor;

  /// Устанавливается хелпером на основе MediaQuery.disableAnimations.
  final bool disableAnimations;
}

/// Навигационный helper: context.pushCircleReveal(page: ..., tapPosition: ...).
extension CircleRevealNavigation on BuildContext {
  Future<T?> pushCircleReveal<T>({
    required Widget page,
    required Offset tapPosition,
    GlobalKey? backButtonKey,
    Color? backgroundColor,
  }) {
    final reduceMotion = MediaQuery.maybeOf(this)?.disableAnimations ?? false;
    return Navigator.of(this).push<T>(
      CircleRevealRoute<T>(
        page: page,
        origin: tapPosition,
        backButtonKey: backButtonKey,
        backgroundColor: backgroundColor,
        disableAnimations: reduceMotion,
      ),
    );
  }
}

class _CircleRevealTransition extends StatefulWidget {
  const _CircleRevealTransition({
    required this.animation,
    required this.origin,
    required this.backButtonKey,
    required this.backgroundColor,
    required this.child,
  });

  final Animation<double> animation;
  final Offset origin;
  final GlobalKey? backButtonKey;
  final Color? backgroundColor;
  final Widget child;

  @override
  State<_CircleRevealTransition> createState() =>
      _CircleRevealTransitionState();
}

class _CircleRevealTransitionState extends State<_CircleRevealTransition> {
  Offset? _exitCenter;

  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_handleStatus);
  }

  @override
  void didUpdateWidget(covariant _CircleRevealTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_handleStatus);
      widget.animation.addStatusListener(_handleStatus);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      // Фиксируем цель схлопывания один раз на старте выхода: кнопка может
      // сама анимироваться, поэтому пересчёт центра каждый кадр даёт дрожание.
      _exitCenter = _resolveExitCenter();
    } else if (status == AnimationStatus.forward) {
      _exitCenter = null;
    }
  }

  Offset _resolveExitCenter() {
    final buttonContext = widget.backButtonKey?.currentContext;
    final renderObject = buttonContext?.findRenderObject();

    if (renderObject is RenderBox && renderObject.hasSize) {
      // При выходе круг схлопывается к глобальному центру кнопки «назад».
      return renderObject.localToGlobal(
        renderObject.size.center(Offset.zero),
      );
    }

    // Если ключ не задан или кнопка ещё недоступна, схлопываем к origin.
    return widget.origin;
  }

  double _maxRadius(Size size, Offset center) {
    // Радиус до самого дальнего угла: гипотенуза из максимальных расстояний
    // по горизонтали и вертикали от выбранного центра.
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_handleStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        // forward — раскрываем круг от origin; reverse — сжимаем его к кнопке.
        final isExiting =
            widget.animation.status == AnimationStatus.reverse;
        final center = isExiting
            ? (_exitCenter ?? _resolveExitCenter())
            : widget.origin;
        final size = MediaQuery.sizeOf(context);
        final rawProgress =
            widget.animation.value.clamp(0.0, 1.0).toDouble();
        final progress = Curves.easeInOutCubic.transform(rawProgress);
        final radius = _maxRadius(size, center) * progress;

        var opacity = 1.0;
        if (isExiting) {
          // Содержимое гаснет за первые 240 мс из 560 мс обратного перехода.
          const fadeWindow = 240 / 560;
          final fadeProgress =
              ((rawProgress - (1 - fadeWindow)) / fadeWindow)
                  .clamp(0.0, 1.0)
                  .toDouble();
          opacity = Curves.easeOut.transform(fadeProgress);
        }

        return ClipPath(
          clipper: _CircleClipper(center: center, radius: radius),
          child: Opacity(
            opacity: opacity,
            child: widget.backgroundColor == null
                ? widget.child
                : ColoredBox(
                    color: widget.backgroundColor!,
                    child: widget.child,
                  ),
          ),
        );
      },
    );
  }
}

class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}
