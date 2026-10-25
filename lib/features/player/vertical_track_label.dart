import 'package:flutter/material.dart';

/// Compact track metadata transition shared by the mini and expanded players.
/// The outgoing label slides up while the next label enters from below, inside
/// a fixed-height viewport so short titles do not resize or jump the layout.
class VerticalTrackLabel extends StatefulWidget {
  const VerticalTrackLabel({
    super.key,
    required this.text,
    required this.trackKey,
    required this.height,
    required this.duration,
    required this.style,
    this.maxLines = 1,
  });

  final String text;
  final String trackKey;
  final double height;
  final Duration duration;
  final TextStyle style;
  final int maxLines;

  @override
  State<VerticalTrackLabel> createState() => _VerticalTrackLabelState();
}

class _VerticalTrackLabelState extends State<VerticalTrackLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transition;
  late String _shownText;
  String? _previousText;

  @override
  void initState() {
    super.initState();
    _shownText = widget.text;
    _transition = AnimationController(
      vsync: this,
      value: 1,
      duration: widget.duration,
    )..addStatusListener(_onStatusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _transition.duration = Duration.zero;
      _previousText = null;
      _transition.value = 1;
    } else {
      _transition.duration = widget.duration;
    }
  }

  @override
  void didUpdateWidget(covariant VerticalTrackLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trackKey == widget.trackKey && oldWidget.text == widget.text) {
      if (oldWidget.duration != widget.duration) {
        _transition.duration = widget.duration;
      }
      return;
    }

    _transition.stop();
    _previousText = _shownText;
    _shownText = widget.text;
    _transition.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : widget.duration;
    _transition.forward(from: 0);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousText != null && mounted) {
      setState(() => _previousText = null);
    }
  }

  Widget _text(String value) => Text(
        value,
        maxLines: widget.maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: widget.maxLines > 1,
        style: widget.style,
      );

  @override
  void dispose() {
    _transition
      ..removeStatusListener(_onStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _transition,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_transition.value);
              return Stack(
                fit: StackFit.expand,
                alignment: AlignmentDirectional.centerStart,
                children: [
                  if (_previousText != null)
                    Positioned.fill(
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0).toDouble(),
                        child: Transform.translate(
                          offset: Offset(0, -widget.height * t),
                          child: _text(_previousText!),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0).toDouble(),
                      child: Transform.translate(
                        offset: Offset(0, widget.height * (1 - t)),
                        child: _text(_shownText),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
}
