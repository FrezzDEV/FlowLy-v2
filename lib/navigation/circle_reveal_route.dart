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
          allowSnapshotting: false,
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

class _CircleRevealTransition extends StatelessWidget {
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

  Offset _centerForExit(BuildContext context) {
    final buttonContext = backButtonKey?.currentContext;
    final renderObject = buttonContext?.findRenderObject();

    if (renderObject is RenderBox && renderObject.hasSize) {
      // При выходе переносим центр круга к фактическому центру кнопки «назад».
      return renderObject.localToGlobal(
        renderObject.size.center(Offset.zero),
      );
    }

    // Если ключ не передали или кнопка ещё недоступна, используем исходную
    // точку нажатия как безопасный запасной вариант.
    return origin;
  }

  double _maxRadius(Size size, Offset center) {
    // Радиус должен дотянуться до самого дальнего угла экрана от выбранного
    // центра: берём максимальное расстояние по X и Y и гипотенузу.
    final dx = math.max(center.dx, size.width - center.dx);
    final dy = math.max(center.dy, size.height - center.dy);
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        // forward — вход из точки нажатия; reverse — выход к кнопке «назад».
        final isExiting = animation.status == AnimationStatus.reverse;
        final center = isExiting ? _centerForExit(context) : origin;
        final size = MediaQuery.sizeOf(context);
        final rawProgress = animation.value.clamp(0.0, 1.0).toDouble();
        final progress = Curves.easeInOutCubic.transform(rawProgress);
        final radius = _maxRadius(size, center) * progress;

        var opacity = 1.0;
        if (isExiting) {
          // При выходе содержимое гаснет за первые 240 мс из 560 мс,
          // пока круг ещё продолжает сжиматься.
          const fadeWindow = 240 / 560;
          final fadeProgress = ((rawProgress - (1 - fadeWindow)) / fadeWindow)
              .clamp(0.0, 1.0)
              .toDouble();
          opacity = Curves.easeOut.transform(fadeProgress);
        }

        return ClipPath(
          clipper: _CircleClipper(center: center, radius: radius),
          child: Opacity(
            opacity: opacity,
            child: backgroundColor == null
                ? child
                : ColoredBox(color: backgroundColor!, child: child),
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
