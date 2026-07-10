import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Panchangam category glyph kind — each one hand-drawn with [CustomPainter]
/// so the screen never depends on external icon packs or network images.
enum PanchangamGlyphKind { tithi, nakshatram, yogam, karanam, sunrise, sunset, moonRasi }

/// Small rounded-square badge with a hand-drawn glyph inside — used in the
/// panchangam detail grid (திதி / நட்சத்திரம் / யோகம் / கரணம் ...).
class PanchangamGlyphBadge extends StatelessWidget {
  const PanchangamGlyphBadge({
    super.key,
    required this.kind,
    this.size = 30,
    this.color = AppColors.crimson,
  });

  final PanchangamGlyphKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.all(size * 0.2),
      child: CustomPaint(painter: _GlyphPainter(kind: kind, color: Colors.white)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.kind, required this.color});

  final PanchangamGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case PanchangamGlyphKind.tithi:
        _paintTithi(canvas, size);
      case PanchangamGlyphKind.nakshatram:
        _paintStar(canvas, size);
      case PanchangamGlyphKind.yogam:
        _paintYogam(canvas, size);
      case PanchangamGlyphKind.karanam:
        _paintKaranam(canvas, size);
      case PanchangamGlyphKind.sunrise:
        _paintSun(canvas, size, rising: true);
      case PanchangamGlyphKind.sunset:
        _paintSun(canvas, size, rising: false);
      case PanchangamGlyphKind.moonRasi:
        _paintMoonRasi(canvas, size);
    }
  }

  void _paintTithi(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = s.shortestSide / 2;
    canvas.saveLayer(Rect.fromLTWH(0, 0, s.width, s.height), Paint());
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    canvas.drawCircle(
      Offset(cx + r * 0.62, cy - r * 0.18),
      r * 0.86,
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.restore();
  }

  void _paintStar(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final rOuter = s.shortestSide / 2;
    final rInner = rOuter * 0.42;
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? rOuter : rInner;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(Offset(cx, cy), rInner * 0.55, Paint()..color = color.withValues(alpha: 0.55));
  }

  void _paintYogam(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = s.shortestSide * 0.24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.shortestSide * 0.16
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(Offset(cx - r * 0.75, cy), r, stroke);
    canvas.drawCircle(Offset(cx + r * 0.75, cy), r, stroke);
  }

  void _paintKaranam(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = s.shortestSide / 2;
    final paint = Paint()..color = color;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), math.pi, math.pi, true, paint);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.32
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.62),
      0,
      math.pi,
      false,
      stroke,
    );
  }

  void _paintSun(Canvas canvas, Size s, {required bool rising}) {
    final cx = s.width / 2;
    final horizonY = s.height * 0.66;
    final sunCy = rising ? horizonY : horizonY;
    final r = s.shortestSide * 0.24;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, s.width, horizonY + 0.01));
    canvas.drawCircle(Offset(cx, sunCy), r, Paint()..color = color);
    canvas.restore();

    final rayPaint = Paint()
      ..color = color
      ..strokeWidth = s.shortestSide * 0.09
      ..strokeCap = StrokeCap.round;
    const rayCount = 6;
    for (var i = 0; i < rayCount; i++) {
      final angle = math.pi + (i / (rayCount - 1)) * math.pi;
      final inner = Offset(cx + math.cos(angle) * (r + s.shortestSide * 0.08), sunCy + math.sin(angle) * (r + s.shortestSide * 0.08));
      final outer = Offset(cx + math.cos(angle) * (r + s.shortestSide * 0.26), sunCy + math.sin(angle) * (r + s.shortestSide * 0.26));
      if (outer.dy <= horizonY + 1) {
        canvas.drawLine(inner, outer, rayPaint);
      }
    }

    final horizon = Paint()
      ..color = color
      ..strokeWidth = s.shortestSide * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s.width * 0.08, horizonY), Offset(s.width * 0.92, horizonY), horizon);

    if (rising) {
      final arrow = Path()
        ..moveTo(cx - r * 0.5, sunCy - r * 1.55)
        ..lineTo(cx, sunCy - r * 2.15)
        ..lineTo(cx + r * 0.5, sunCy - r * 1.55);
      canvas.drawPath(
        arrow,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.shortestSide * 0.09
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      final arrow = Path()
        ..moveTo(cx - r * 0.5, sunCy - r * 1.95)
        ..lineTo(cx, sunCy - r * 1.35)
        ..lineTo(cx + r * 0.5, sunCy - r * 1.95);
      canvas.drawPath(
        arrow,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.shortestSide * 0.09
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  void _paintMoonRasi(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = s.shortestSide / 2;
    canvas.saveLayer(Rect.fromLTWH(0, 0, s.width, s.height), Paint());
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    canvas.drawCircle(
      Offset(cx + r * 0.55, cy - r * 0.25),
      r * 0.78,
      Paint()..blendMode = BlendMode.dstOut,
    );
    canvas.restore();
    canvas.drawCircle(Offset(cx - r * 0.32, cy + r * 0.1), r * 0.1, Paint()..color = color.withValues(alpha: 0.6));
    canvas.drawCircle(Offset(cx - r * 0.05, cy - r * 0.35), r * 0.06, Paint()..color = color.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

/// Circular "auspicious time" checkmark — hand drawn, no icon-font dependency.
class AuspiciousCheckGlyph extends StatelessWidget {
  const AuspiciousCheckGlyph({super.key, this.size = 20, this.color = AppColors.emerald});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CheckPainter(color: color)),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide / 2;
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    final tick = Path()
      ..moveTo(cx - r * 0.48, cy + r * 0.02)
      ..lineTo(cx - r * 0.12, cy + r * 0.38)
      ..lineTo(cx + r * 0.5, cy - r * 0.32);
    canvas.drawPath(
      tick,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.14
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) => oldDelegate.color != color;
}

/// Clean vector placeholder frame for the deity-image slot at the top-left of
/// the daily panchangam header — an arched gopuram-style frame with a subtle
/// lotus/diya glyph, so we never rely on a network image that can 404.
class DeityFramePlaceholder extends StatelessWidget {
  const DeityFramePlaceholder({super.key, this.width = 62, this.height = 82});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _DeityFramePainter()),
    );
  }
}

class _DeityFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final h = s.height;
    final archRadius = w * 0.5;

    final frame = Path()
      ..moveTo(0, h)
      ..lineTo(0, archRadius)
      ..arcToPoint(Offset(w, archRadius), radius: Radius.circular(archRadius), clockwise: true)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(
      frame,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.crimsonSoft, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      frame,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final cx = w / 2;
    final cy = h * 0.52;
    final petalPaint = Paint()..color = AppColors.crimson.withValues(alpha: 0.75);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w * 0.14, -h * 0.16, 0, -h * 0.26)
        ..quadraticBezierTo(-w * 0.14, -h * 0.16, 0, 0);
      canvas.drawPath(petal, petalPaint);
      canvas.restore();
    }
    canvas.drawCircle(Offset(cx, cy), h * 0.06, Paint()..color = AppColors.goldDark);

    canvas.drawCircle(
      Offset(cx, h * 0.14),
      h * 0.045,
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
