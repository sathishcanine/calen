import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small panchangam glyphs for monthly calendar date cells (SS2 reference).
class CalendarDayIcon extends StatelessWidget {
  const CalendarDayIcon({
    super.key,
    required this.iconId,
    this.size = 11,
    this.onDark = false,
    this.themed = false,
  });

  final String iconId;
  final double size;
  final bool onDark;
  final bool themed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CalendarDayIconPainter(
          iconId: iconId,
          size: size,
          onDark: onDark,
          themed: themed,
        ),
      ),
    );
  }
}

class _CalendarDayIconPainter extends CustomPainter {
  _CalendarDayIconPainter({
    required this.iconId,
    required this.size,
    required this.onDark,
    required this.themed,
  });

  final String iconId;
  final double size;
  final bool onDark;
  final bool themed;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    switch (iconId) {
      case 'thaali':
        _drawThaali(canvas, canvasSize);
      case 'amavasai':
      case 'sarva_amavasai':
        _drawMoon(canvas, canvasSize, filled: true);
      case 'pournami':
        _drawMoon(canvas, canvasSize, filled: false);
      case 'murugan':
        _drawMurugan(canvas, canvasSize);
      case 'ganesha':
        _drawGanesha(canvas, canvasSize);
      case 'perumal':
        _drawPerumal(canvas, canvasSize);
      case 'nandi':
        _drawNandi(canvas, canvasSize);
      case 'shiva':
        _drawShiva(canvas, canvasSize);
      case 'star':
      case 'thiruvonam':
        _drawStar(canvas, canvasSize, gold: iconId == 'thiruvonam');
      case 'vastu':
        _drawVastu(canvas, canvasSize);
      case 'crescent':
        _drawCrescent(canvas, canvasSize);
      default:
        _drawDot(canvas, canvasSize);
    }
  }

  void _drawThaali(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final thread = Paint()
      ..color = AppColors.goldLight
      ..strokeWidth = size * 0.08
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, size * 0.05), Offset(cx, size * 0.42), thread);

    final pendant = Path()
      ..moveTo(cx, size * 0.42)
      ..quadraticBezierTo(cx - size * 0.22, size * 0.58, cx, size * 0.82)
      ..quadraticBezierTo(cx + size * 0.22, size * 0.58, cx, size * 0.42);
    canvas.drawPath(
      pendant,
      Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(Offset(cx, size * 0.72), size * 0.06, Paint()..color = AppColors.goldDark);
  }

  void _drawMoon(Canvas canvas, Size s, {required bool filled}) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = size * 0.34;
    final Color color;
    if (onDark) {
      color = Colors.white.withValues(alpha: filled ? 0.95 : 0.85);
    } else if (themed) {
      color = filled ? AppColors.textPrimary : AppColors.textSecondary;
    } else {
      color = filled ? Colors.black87 : Colors.black54;
    }
    if (filled) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = color);
    } else {
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.1,
      );
    }
  }

  void _drawMurugan(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final bodyColor = themed ? AppColors.maroon : const Color(0xFFE53935);
    final accentColor = themed ? AppColors.gold : const Color(0xFFFB8C00);
    final body = Paint()..color = bodyColor;
    canvas.drawCircle(Offset(cx, size * 0.38), size * 0.18, body);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, size * 0.68), width: size * 0.28, height: size * 0.28),
      body,
    );
    canvas.drawLine(
      Offset(cx, size * 0.5),
      Offset(cx + size * 0.28, size * 0.18),
      Paint()
        ..color = accentColor
        ..strokeWidth = size * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawGanesha(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final color = themed ? AppColors.labelPink : const Color(0xFF8E24AA);
    canvas.drawCircle(Offset(cx, size * 0.42), size * 0.22, Paint()..color = color);
    canvas.drawCircle(
      Offset(cx - size * 0.12, size * 0.36),
      size * 0.07,
      Paint()..color = themed ? AppColors.goldLight : Colors.white,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + size * 0.12, size * 0.48), width: size * 0.18, height: size * 0.14),
      0,
      math.pi,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.07,
    );
  }

  void _drawPerumal(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final paint = Paint()..color = themed ? AppColors.maroonLight : const Color(0xFF1565C0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size * 0.62), width: size * 0.62, height: size * 0.22),
      paint,
    );
    canvas.drawCircle(Offset(cx - size * 0.12, size * 0.52), size * 0.1, paint);
    canvas.drawCircle(Offset(cx + size * 0.08, size * 0.48), size * 0.08, paint);
  }

  void _drawNandi(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final color = onDark
        ? Colors.white70
        : (themed ? AppColors.textSecondary : const Color(0xFF5D4037));
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size * 0.62), width: size * 0.55, height: size * 0.22),
      paint,
    );
    canvas.drawCircle(Offset(cx - size * 0.18, size * 0.48), size * 0.1, paint);
    canvas.drawLine(
      Offset(cx - size * 0.05, size * 0.42),
      Offset(cx + size * 0.05, size * 0.34),
      Paint()
        ..color = paint.color
        ..strokeWidth = size * 0.06,
    );
  }

  void _drawShiva(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final base = themed ? AppColors.maroonDark : const Color(0xFF455A64);
    final lingam = themed ? AppColors.maroon : const Color(0xFF37474F);
    final top = themed ? AppColors.maroonLight : const Color(0xFF78909C);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size * 0.72), width: size * 0.34, height: size * 0.12),
      Paint()..color = base,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size * 0.48), width: size * 0.14, height: size * 0.34),
        Radius.circular(size * 0.04),
      ),
      Paint()..color = lingam,
    );
    canvas.drawCircle(Offset(cx, size * 0.28), size * 0.07, Paint()..color = top);
  }

  void _drawStar(Canvas canvas, Size s, {bool gold = false}) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = size * 0.38;
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final x = cx + math.cos(a) * r;
      final y = cy + math.sin(a) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      final b = a + math.pi / 5;
      path.lineTo(cx + math.cos(b) * r * 0.45, cy + math.sin(b) * r * 0.45);
    }
    path.close();
    final starColor = gold || themed
        ? AppColors.goldDark
        : const Color(0xFFF9A825);
    canvas.drawPath(path, Paint()..color = starColor);
  }

  void _drawDot(Canvas canvas, Size s) {
    canvas.drawCircle(
      Offset(s.width / 2, s.height / 2),
      size * 0.12,
      Paint()..color = onDark ? Colors.white54 : AppColors.textSecondary,
    );
  }

  void _drawVastu(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final paint = Paint()
      ..color = AppColors.goldDark
      ..strokeWidth = size * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, size * 0.78), Offset(cx, size * 0.22), paint);
    final head = Path()
      ..moveTo(cx, size * 0.18)
      ..lineTo(cx - size * 0.22, size * 0.38)
      ..lineTo(cx + size * 0.22, size * 0.38)
      ..close();
    canvas.drawPath(head, Paint()..color = AppColors.goldDark);
  }

  void _drawCrescent(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final r = size * 0.34;
    final color = onDark
        ? Colors.white70
        : (themed ? AppColors.textPrimary : Colors.black87);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 3,
      math.pi * 4 / 3,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size * 0.11,
    );
  }

  @override
  bool shouldRepaint(covariant _CalendarDayIconPainter oldDelegate) =>
      oldDelegate.iconId != iconId ||
      oldDelegate.onDark != onDark ||
      oldDelegate.themed != themed;
}

/// Split cell icons into top (thaali) and bottom event glyphs.
List<String> calendarTopIcons(List<String> icons) =>
    icons.where((id) => id == 'thaali').toList();

List<String> calendarBottomIcons(List<String> icons, {String? moonPhase}) {
  final bottom = icons.where((id) => id != 'thaali').toList();
  if (moonPhase == 'amavasai' && !bottom.any((id) => id == 'amavasai' || id == 'sarva_amavasai')) {
    bottom.insert(0, 'amavasai');
  }
  if (moonPhase == 'pournami' && !bottom.contains('pournami')) {
    bottom.insert(0, 'pournami');
  }
  return bottom;
}
