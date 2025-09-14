import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const GoogleLogoWidget({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: BorderRadius.circular(4)),
      child: CustomPaint(painter: GoogleLogoPainter(), size: Size(size, size)),
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Google "G" colors
    final blue = const Color(0xFF4285F4);
    final red = const Color(0xFFEA4335);
    final yellow = const Color(0xFFFBBC05);
    final green = const Color(0xFF34A853);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    // Blue arc (top)
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Red arc (right)
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0, // 0 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Yellow arc (bottom)
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57, // 90 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // Green arc (left)
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, // 180 degrees
      1.57, // 90 degrees
      true,
      paint,
    );

    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.6, paint);

    // Blue "G" shape
    paint.color = blue;
    final path = Path();
    path.moveTo(center.dx - radius * 0.2, center.dy);
    path.lineTo(center.dx + radius * 0.2, center.dy);
    path.lineTo(center.dx + radius * 0.2, center.dy - radius * 0.2);
    path.lineTo(center.dx, center.dy - radius * 0.2);
    path.lineTo(center.dx, center.dy + radius * 0.2);
    path.lineTo(center.dx + radius * 0.3, center.dy + radius * 0.2);
    path.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.3);
    path.lineTo(center.dx - radius * 0.3, center.dy - radius * 0.3);
    path.lineTo(center.dx - radius * 0.3, center.dy + radius * 0.3);
    path.lineTo(center.dx + radius * 0.3, center.dy + radius * 0.3);
    path.lineTo(center.dx + radius * 0.3, center.dy + radius * 0.1);
    path.lineTo(center.dx - radius * 0.1, center.dy + radius * 0.1);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
