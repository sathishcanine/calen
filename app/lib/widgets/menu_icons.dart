import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Thematic menu icons — kaalavidya-inspired spiritual glyphs via CustomPaint.
enum MenuIconKind {
  panchangam,
  inauspicious,
  gowri,
  hora,
  kariNaatkal,
  vastu,
  panchaPakshi,
  marriage,
  numerology,
  nazhigai,
  chandrashtamam,
  kanavu,
  palliVizhum,
  palliSollum,
  manaiyadi,
  tara,
  macha,
  dhana,
  vilakku,
  dailyCalendar,
  monthlyCalendar,
}

class MenuIcon extends StatelessWidget {
  const MenuIcon({
    super.key,
    required this.kind,
    this.size = 32,
    this.color = Colors.white,
  });

  final MenuIconKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MenuIconPainter(kind: kind, color: color),
      ),
    );
  }
}

class _MenuIconPainter extends CustomPainter {
  _MenuIconPainter({required this.kind, required this.color});

  final MenuIconKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    switch (kind) {
      case MenuIconKind.panchangam:
        _drawSun(canvas, cx - r * 0.35, cy - r * 0.1, r * 0.45, fill);
        _drawCrescent(canvas, cx + r * 0.4, cy - r * 0.15, r * 0.35, paint, fill);
        for (var i = 0; i < 5; i++) {
          final a = -math.pi / 2 + i * math.pi / 3;
          canvas.drawCircle(
            Offset(cx + math.cos(a) * r * 0.9, cy + math.sin(a) * r * 0.9),
            size.width * 0.025,
            fill,
          );
        }
      case MenuIconKind.inauspicious:
        canvas.drawCircle(Offset(cx, cy), r, paint);
        final hand = Path()
          ..moveTo(cx, cy - r * 0.55)
          ..lineTo(cx, cy + r * 0.15)
          ..moveTo(cx - r * 0.3, cy - r * 0.15)
          ..lineTo(cx, cy + r * 0.15)
          ..lineTo(cx + r * 0.3, cy - r * 0.15);
        canvas.drawPath(hand, paint..strokeWidth = size.width * 0.09);
        canvas.drawLine(
          Offset(cx - r * 0.5, cy + r * 0.5),
          Offset(cx + r * 0.5, cy - r * 0.5),
          paint..strokeWidth = size.width * 0.08,
        );
      case MenuIconKind.gowri:
        _drawStar(canvas, cx, cy, r, 5, fill);
        canvas.drawCircle(Offset(cx, cy), r * 0.22, Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill);
      case MenuIconKind.hora:
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset(cx, cy),
            Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
            paint..strokeWidth = size.width * 0.05,
          );
        }
        canvas.drawCircle(Offset(cx, cy), r * 0.28, fill);
      case MenuIconKind.kariNaatkal:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 1.6, height: r * 1.4),
          Radius.circular(r * 0.2),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawLine(Offset(cx - r * 0.5, cy - r * 0.35), Offset(cx + r * 0.5, cy + r * 0.35), paint..strokeWidth = size.width * 0.09);
      case MenuIconKind.vastu:
        _drawGopuram(canvas, cx, cy, r, paint, fill);
      case MenuIconKind.panchaPakshi:
        for (var row = 0; row < 2; row++) {
          for (var col = 0; col < 2; col++) {
            final ox = cx + (col - 0.5) * r * 0.9;
            final oy = cy + (row - 0.5) * r * 0.9;
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(ox, oy), width: r * 0.55, height: r * 0.55),
                const Radius.circular(4),
              ),
              paint..strokeWidth = size.width * 0.06,
            );
            _drawBird(canvas, ox, oy, r * 0.18, fill);
          }
        }
      case MenuIconKind.marriage:
        final heart = Path();
        heart.moveTo(cx, cy + r * 0.35);
        heart.cubicTo(cx - r, cy - r * 0.1, cx - r * 0.5, cy - r * 0.7, cx, cy - r * 0.25);
        heart.cubicTo(cx + r * 0.5, cy - r * 0.7, cx + r, cy - r * 0.1, cx, cy + r * 0.35);
        canvas.drawPath(heart, fill);
      case MenuIconKind.numerology:
        final textPainter = TextPainter(
          text: TextSpan(
            text: '123',
            style: TextStyle(color: color, fontSize: size.width * 0.38, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, Offset(cx - textPainter.width / 2, cy - textPainter.height / 2));
      case MenuIconKind.nazhigai:
        canvas.drawCircle(Offset(cx, cy), r, paint);
        canvas.drawLine(Offset(cx, cy), Offset(cx, cy - r * 0.55), paint..strokeWidth = size.width * 0.08);
        canvas.drawLine(Offset(cx, cy), Offset(cx + r * 0.4, cy + r * 0.1), paint);
      case MenuIconKind.chandrashtamam:
        _drawCrescent(canvas, cx, cy, r * 0.7, paint, fill);
        canvas.drawCircle(Offset(cx + r * 0.55, cy), r * 0.12, fill);
      case MenuIconKind.kanavu:
        _drawCrescent(canvas, cx, cy, r * 0.65, paint, fill);
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(Offset(cx - r * 0.3 + i * r * 0.3, cy + r * 0.55), size.width * 0.03, fill);
        }
      case MenuIconKind.palliVizhum:
        final body = Path()
          ..moveTo(cx - r * 0.7, cy)
          ..quadraticBezierTo(cx, cy - r * 0.5, cx + r * 0.7, cy)
          ..lineTo(cx + r * 0.5, cy + r * 0.3)
          ..lineTo(cx - r * 0.5, cy + r * 0.3)
          ..close();
        canvas.drawPath(body, fill);
        canvas.drawCircle(Offset(cx + r * 0.45, cy - r * 0.05), r * 0.08, Paint()..color = color);
      case MenuIconKind.palliSollum:
        canvas.drawCircle(Offset(cx - r * 0.3, cy), r * 0.35, paint);
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx + r * 0.2, cy), width: r * 0.9, height: r * 0.7),
          -math.pi / 4,
          math.pi / 2,
          false,
          paint,
        );
      case MenuIconKind.manaiyadi:
        final house = Path()
          ..moveTo(cx, cy - r * 0.65)
          ..lineTo(cx + r * 0.7, cy)
          ..lineTo(cx + r * 0.7, cy + r * 0.55)
          ..lineTo(cx - r * 0.7, cy + r * 0.55)
          ..lineTo(cx - r * 0.7, cy)
          ..close();
        canvas.drawPath(house, paint..style = PaintingStyle.stroke);
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy + r * 0.2), width: r * 0.35, height: r * 0.4),
          paint,
        );
      case MenuIconKind.tara:
        _drawStar(canvas, cx, cy, r * 0.85, 6, fill);
        canvas.drawCircle(Offset(cx, cy), r * 0.2, Paint()..color = color.withValues(alpha: 0.4)..style = PaintingStyle.fill);
      case MenuIconKind.macha:
        canvas.drawCircle(Offset(cx, cy - r * 0.1), r * 0.55, paint);
        canvas.drawCircle(Offset(cx - r * 0.2, cy - r * 0.15), r * 0.07, fill);
        canvas.drawCircle(Offset(cx + r * 0.25, cy + r * 0.05), r * 0.06, fill);
      case MenuIconKind.dhana:
        final hand = Path()
          ..moveTo(cx - r * 0.5, cy + r * 0.3)
          ..quadraticBezierTo(cx, cy - r * 0.2, cx + r * 0.5, cy + r * 0.3)
          ..lineTo(cx, cy + r * 0.55)
          ..close();
        canvas.drawPath(hand, fill);
        _drawHeart(canvas, cx, cy - r * 0.35, r * 0.3, fill);
      case MenuIconKind.vilakku:
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy + r * 0.35), width: r * 0.5, height: r * 0.45),
          fill,
        );
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 0.7, height: r * 0.25), fill);
        final flame = Path()
          ..moveTo(cx, cy - r * 0.65)
          ..quadraticBezierTo(cx + r * 0.25, cy - r * 0.1, cx, cy + r * 0.05)
          ..quadraticBezierTo(cx - r * 0.25, cy - r * 0.1, cx, cy - r * 0.65);
        canvas.drawPath(flame, fill);
      case MenuIconKind.dailyCalendar:
        _drawSun(canvas, cx, cy, r * 0.55, fill);
      case MenuIconKind.monthlyCalendar:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 1.5, height: r * 1.3),
          Radius.circular(r * 0.15),
        );
        canvas.drawRRect(rect, paint);
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 3; col++) {
            canvas.drawCircle(
              Offset(cx - r * 0.45 + col * r * 0.45, cy - r * 0.25 + row * r * 0.35),
              size.width * 0.04,
              fill,
            );
          }
        }
    }
  }

  void _drawSun(Canvas canvas, double cx, double cy, double r, Paint fill) {
    canvas.drawCircle(Offset(cx, cy), r * 0.45, fill);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * r * 0.55, cy + math.sin(a) * r * 0.55),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        fill..style = PaintingStyle.stroke..strokeWidth = r * 0.12,
      );
    }
    fill.style = PaintingStyle.fill;
  }

  void _drawCrescent(Canvas canvas, double cx, double cy, double r, Paint stroke, Paint fill) {
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -math.pi / 3, math.pi * 4 / 3, false, stroke);
    canvas.drawCircle(Offset(cx + r * 0.35, cy), r * 0.75, Paint()..color = stroke.color..blendMode = BlendMode.dstOut);
  }

  void _drawStar(Canvas canvas, double cx, double cy, double r, int points, Paint fill) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / points;
      final rad = i.isEven ? r : r * 0.45;
      final x = cx + math.cos(a) * rad;
      final y = cy + math.sin(a) * rad;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
  }

  void _drawGopuram(Canvas canvas, double cx, double cy, double r, Paint stroke, Paint fill) {
    final base = Path()
      ..moveTo(cx - r * 0.6, cy + r * 0.5)
      ..lineTo(cx + r * 0.6, cy + r * 0.5)
      ..lineTo(cx + r * 0.45, cy + r * 0.1)
      ..lineTo(cx - r * 0.45, cy + r * 0.1)
      ..close();
    canvas.drawPath(base, stroke);
    for (var i = -1; i <= 1; i++) {
      final tx = cx + i * r * 0.35;
      final tier = Path()
        ..moveTo(tx - r * 0.2, cy + r * 0.1)
        ..lineTo(tx, cy - r * 0.55)
        ..lineTo(tx + r * 0.2, cy + r * 0.1);
      canvas.drawPath(tier, stroke);
    }
    canvas.drawCircle(Offset(cx, cy - r * 0.6), r * 0.1, fill);
  }

  void _drawBird(Canvas canvas, double cx, double cy, double r, Paint fill) {
    final bird = Path()
      ..moveTo(cx - r, cy)
      ..quadraticBezierTo(cx, cy - r, cx + r, cy)
      ..lineTo(cx, cy + r * 0.3)
      ..close();
    canvas.drawPath(bird, fill);
  }

  void _drawHeart(Canvas canvas, double cx, double cy, double r, Paint fill) {
    final heart = Path();
    heart.moveTo(cx, cy + r * 0.35);
    heart.cubicTo(cx - r, cy - r * 0.1, cx - r * 0.5, cy - r * 0.7, cx, cy - r * 0.25);
    heart.cubicTo(cx + r * 0.5, cy - r * 0.7, cx + r, cy - r * 0.1, cx, cy + r * 0.35);
    canvas.drawPath(heart, fill);
  }

  @override
  bool shouldRepaint(covariant _MenuIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

MenuIconKind menuIconKindFromPalangalId(String id) {
  switch (id) {
    case 'kanavu':
      return MenuIconKind.kanavu;
    case 'palli_vizhum':
      return MenuIconKind.palliVizhum;
    case 'palli_sollum':
      return MenuIconKind.palliSollum;
    case 'manaiyadi':
      return MenuIconKind.manaiyadi;
    case 'tara':
      return MenuIconKind.tara;
    case 'macha':
      return MenuIconKind.macha;
    case 'dhana':
      return MenuIconKind.dhana;
    case 'vilakku':
      return MenuIconKind.vilakku;
    default:
      return MenuIconKind.tara;
  }
}
