import 'package:flutter/material.dart';

class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokeWidth = w * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // Red arc (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.35, 1.55, false, paint);

    // Yellow arc (top-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3.9, 1.55, false, paint);

    // Green arc (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.8, 1.55, false, paint);

    // Blue arc (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.8, 1.6, false, paint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barHeight = strokeWidth;
    canvas.drawRect(
      Rect.fromLTWH(
          center.dx - 1, center.dy - barHeight / 2, radius + 1, barHeight),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
