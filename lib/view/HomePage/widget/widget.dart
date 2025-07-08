import 'package:flutter/material.dart';

class TrickCollectAnimation extends StatefulWidget {
  final List<Widget> cardWidgets;
  final List<Offset> fromPositions;
  final Offset toPosition;
  final Duration duration;
  final VoidCallback? onEnd;

  const TrickCollectAnimation({
    super.key,
    required this.cardWidgets,
    required this.fromPositions,
    required this.toPosition,
    this.duration = const Duration(milliseconds: 700),
    this.onEnd,
  });

  @override
  State<TrickCollectAnimation> createState() => _TrickCollectAnimationState();
}

class _TrickCollectAnimationState extends State<TrickCollectAnimation>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.cardWidgets.length, (i) {
      return AnimationController(vsync: this, duration: widget.duration)
        ..forward();
    });
    _animations = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOutQuad))
        .toList();

    _controllers.last.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onEnd?.call();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(widget.cardWidgets.length, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, child) {
            final t = _animations[i].value;
            final dx =
                widget.fromPositions[i].dx +
                (widget.toPosition.dx - widget.fromPositions[i].dx) * t;
            final dy =
                widget.fromPositions[i].dy +
                (widget.toPosition.dy - widget.fromPositions[i].dy) * t;
            return Positioned(left: dx, top: dy, child: child!);
          },
          child: widget.cardWidgets[i],
        );
      }),
    );
  }
}
