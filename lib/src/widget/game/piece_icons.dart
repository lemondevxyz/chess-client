import 'package:flutter/rendering.dart';

class Pawn extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1

    paint.color = Color(0xffffffff).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 0.98, size.height * 0.3);
    path.cubicTo(size.width * 0.88, size.height * 0.3, size.width * 0.8,
        size.height * 0.35, size.width * 0.8, size.height * 0.43);
    path.cubicTo(size.width * 0.8, size.height * 0.46, size.width * 0.82,
        size.height * 0.48, size.width * 0.84, size.height / 2);
    path.cubicTo(size.width * 0.75, size.height * 0.54, size.width * 0.7,
        size.height * 0.61, size.width * 0.7, size.height * 0.69);
    path.cubicTo(size.width * 0.7, size.height * 0.76, size.width * 0.74,
        size.height * 0.81, size.width * 0.8, size.height * 0.85);
    path.cubicTo(size.width * 0.67, size.height * 0.89, size.width * 0.48,
        size.height * 1.04, size.width * 0.48, size.height * 1.3);
    path.cubicTo(size.width * 0.48, size.height * 1.3, size.width * 1.48,
        size.height * 1.3, size.width * 1.48, size.height * 1.3);
    path.cubicTo(size.width * 1.48, size.height * 1.04, size.width * 1.29,
        size.height * 0.89, size.width * 1.16, size.height * 0.85);
    path.cubicTo(size.width * 1.22, size.height * 0.81, size.width * 1.26,
        size.height * 0.76, size.width * 1.26, size.height * 0.69);
    path.cubicTo(size.width * 1.26, size.height * 0.61, size.width * 1.2,
        size.height * 0.54, size.width * 1.12, size.height / 2);
    path.cubicTo(size.width * 1.14, size.height * 0.48, size.width * 1.15,
        size.height * 0.46, size.width * 1.15, size.height * 0.43);
    path.cubicTo(size.width * 1.15, size.height * 0.35, size.width * 1.07,
        size.height * 0.3, size.width * 0.98, size.height * 0.3);
    path.cubicTo(size.width * 0.98, size.height * 0.3, size.width * 0.98,
        size.height * 0.3, size.width * 0.98, size.height * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
