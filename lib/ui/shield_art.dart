import 'package:flutter/material.dart';

const teal = Color(0xFF24766A);

class ShieldArt extends StatelessWidget {
  final double size;
  final int variant;
  const ShieldArt({super.key, this.size = 200, this.variant = 0});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: ShieldPainter(variant)),
  );
}

class ShieldPainter extends CustomPainter {
  final int variant;
  ShieldPainter(this.variant);
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = teal.withValues(alpha: 0.12);
    for (final r in [0.37, 0.48, 0.59]) {
      canvas.drawCircle(c, s.width * r, p);
    }
    canvas.drawCircle(
      c,
      s.width * 0.37,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFC6DAC7), Color(0x00DCE7D6)],
        ).createShader(Rect.fromCircle(center: c, radius: s.width * 0.4)),
    );
    canvas.save();
    canvas.translate(s.width * 0.23, s.height * 0.17);
    canvas.rotate(-0.07);
    final w = s.width * 0.59, h = s.height * 0.69;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..cubicTo(w * 0.7, h * 0.12, w * 0.84, h * 0.13, w, h * 0.14)
      ..lineTo(w, h * 0.49)
      ..cubicTo(w, h * 0.73, w * 0.76, h * 0.91, w / 2, h)
      ..cubicTo(w * 0.24, h * 0.91, 0, h * 0.73, 0, h * 0.49)
      ..lineTo(0, h * 0.14)
      ..cubicTo(w * 0.16, h * 0.13, w * 0.3, h * 0.12, w / 2, 0)
      ..close();
    canvas.drawShadow(path, const Color(0xFF2D5F49), 16, true);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB6D2B3), Color(0xFF6B9B7A), Color(0xFF315D4B)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFCDE0C6),
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w * 0.49, h),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.restore();
    final check = Path()
      ..moveTo(w * 0.31, h * 0.47)
      ..lineTo(w * 0.46, h * 0.6)
      ..lineTo(w * 0.72, h * 0.34);
    canvas.drawPath(
      check,
      Paint()
        ..color = const Color(0xFFF1F6E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.width * 0.032
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
    for (final point in [
      Offset(s.width * 0.15, s.height * 0.38),
      Offset(s.width * 0.83, s.height * 0.69),
    ]) {
      canvas.drawCircle(
        point,
        s.width * 0.055,
        Paint()..color = const Color(0xFFF6F8F0),
      );
      canvas.drawCircle(point, s.width * 0.055, p);
      canvas.drawCircle(
        point,
        3,
        Paint()..color = teal.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(ShieldPainter oldDelegate) =>
      oldDelegate.variant != variant;
}
