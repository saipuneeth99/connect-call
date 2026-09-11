import 'dart:math' as math;
import 'package:flutter/material.dart';

class CallRippleAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final double minRadius;
  final double maxRadius;
  final int ripplesCount;
  final bool animate;

  const CallRippleAnimation({
    super.key,
    required this.child,
    this.color = const Color(0xFF3B82F6),
    this.minRadius = 60,
    this.maxRadius = 140,
    this.ripplesCount = 3,
    this.animate = true,
  });

  @override
  State<CallRippleAnimation> createState() => _CallRippleAnimationState();
}

class _CallRippleAnimationState extends State<CallRippleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CallRippleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RipplesPainter(
        animation: _controller,
        color: widget.color,
        minRadius: widget.minRadius,
        maxRadius: widget.maxRadius,
        count: widget.ripplesCount,
      ),
      child: widget.child,
    );
  }
}

class _RipplesPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final double minRadius;
  final double maxRadius;
  final int count;

  _RipplesPainter({
    required this.animation,
    required this.color,
    required this.minRadius,
    required this.maxRadius,
    required this.count,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < count; i++) {
      final progress = (animation.value + (i / count)) % 1.0;
      final radius = minRadius + (maxRadius - minRadius) * progress;
      final opacity = math.sin(progress * math.pi) * 0.35;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);

      // Subtle filled aura for inner ring
      if (i == 0) {
        final fillPaint = Paint()
          ..color = color.withValues(alpha: (opacity * 0.15).clamp(0.0, 1.0))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RipplesPainter oldDelegate) => true;
}
