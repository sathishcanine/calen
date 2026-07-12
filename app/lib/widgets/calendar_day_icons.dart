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
      case 'krittigai':
        _drawStar(canvas, canvasSize, gold: iconId == 'thiruvonam');
      case 'vastu':
        _drawVastu(canvas, canvasSize);
      case 'crescent':
        _drawCrescent(canvas, canvasSize);
      case 'home_good':
        _drawHomeGood(canvas, canvasSize);
      case 'vehicle_good':
        _drawVehicleGood(canvas, canvasSize);
      case 'land_good':
        _drawLandGood(canvas, canvasSize);
      case 'business_good':
        _drawBusinessGood(canvas, canvasSize);
      case 'jewel_good':
        _drawJewelGood(canvas, canvasSize);
      case 'education_good':
        _drawEducationGood(canvas, canvasSize);
      case 'amman':
        _drawTempleLamp(canvas, canvasSize);
      case 'ashtami':
        _drawTithiBadge(canvas, canvasSize, '8');
      case 'navami':
        _drawTithiBadge(canvas, canvasSize, '9');
      case 'dwadashi':
        _drawTithiBadge(canvas, canvasSize, '12');
      case 'prathamai':
        _drawTithiBadge(canvas, canvasSize, '1');
      case 'tamil_month':
        _drawTamilMonth(canvas, canvasSize);
      case 'festival':
        _drawFestival(canvas, canvasSize);
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
    canvas.drawCircle(
      Offset(cx, size * 0.72),
      size * 0.06,
      Paint()..color = AppColors.goldDark,
    );
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
      Rect.fromCenter(
        center: Offset(cx, size * 0.68),
        width: size * 0.28,
        height: size * 0.28,
      ),
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
    canvas.drawCircle(
      Offset(cx, size * 0.42),
      size * 0.22,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(cx - size * 0.12, size * 0.36),
      size * 0.07,
      Paint()..color = themed ? AppColors.goldLight : Colors.white,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx + size * 0.12, size * 0.48),
        width: size * 0.18,
        height: size * 0.14,
      ),
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
    final paint = Paint()
      ..color = themed ? AppColors.maroonLight : const Color(0xFF1565C0);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size * 0.62),
        width: size * 0.62,
        height: size * 0.22,
      ),
      paint,
    );
    canvas.drawCircle(Offset(cx - size * 0.12, size * 0.52), size * 0.1, paint);
    canvas.drawCircle(
      Offset(cx + size * 0.08, size * 0.48),
      size * 0.08,
      paint,
    );
  }

  void _drawNandi(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final color = onDark
        ? Colors.white70
        : (themed ? AppColors.textSecondary : const Color(0xFF5D4037));
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size * 0.62),
        width: size * 0.55,
        height: size * 0.22,
      ),
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
      Rect.fromCenter(
        center: Offset(cx, size * 0.72),
        width: size * 0.34,
        height: size * 0.12,
      ),
      Paint()..color = base,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size * 0.48),
          width: size * 0.14,
          height: size * 0.34,
        ),
        Radius.circular(size * 0.04),
      ),
      Paint()..color = lingam,
    );
    canvas.drawCircle(
      Offset(cx, size * 0.28),
      size * 0.07,
      Paint()..color = top,
    );
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

  void _drawHomeGood(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final roof = Path()
      ..moveTo(cx, size * 0.16)
      ..lineTo(size * 0.14, size * 0.48)
      ..lineTo(size * 0.24, size * 0.48)
      ..lineTo(size * 0.24, size * 0.82)
      ..lineTo(size * 0.76, size * 0.82)
      ..lineTo(size * 0.76, size * 0.48)
      ..lineTo(size * 0.86, size * 0.48)
      ..close();
    canvas.drawPath(
      roof,
      Paint()..color = themed ? AppColors.maroon : const Color(0xFF7B1A2D),
    );
    canvas.drawRect(
      Rect.fromLTWH(size * 0.44, size * 0.58, size * 0.12, size * 0.24),
      Paint()..color = AppColors.goldLight,
    );
  }

  void _drawVehicleGood(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = themed ? AppColors.auspicious : const Color(0xFF15803D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size * 0.16, size * 0.42, size * 0.68, size * 0.24),
        Radius.circular(size * 0.06),
      ),
      paint,
    );
    final cabin = Path()
      ..moveTo(size * 0.32, size * 0.42)
      ..lineTo(size * 0.42, size * 0.27)
      ..lineTo(size * 0.66, size * 0.27)
      ..lineTo(size * 0.76, size * 0.42)
      ..close();
    canvas.drawPath(cabin, paint);
    final wheel = Paint()
      ..color = themed ? AppColors.maroonDark : Colors.black87;
    canvas.drawCircle(Offset(size * 0.32, size * 0.69), size * 0.08, wheel);
    canvas.drawCircle(Offset(size * 0.68, size * 0.69), size * 0.08, wheel);
  }

  void _drawLandGood(Canvas canvas, Size s) {
    final field = Paint()
      ..color = themed ? AppColors.auspicious : const Color(0xFF2E7D32);
    final gold = Paint()
      ..color = AppColors.goldDark
      ..strokeWidth = size * 0.05
      ..style = PaintingStyle.stroke;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size * 0.16, size * 0.22, size * 0.68, size * 0.56),
      Radius.circular(size * 0.08),
    );
    canvas.drawRRect(rect, field);
    canvas.drawLine(
      Offset(size * 0.24, size * 0.5),
      Offset(size * 0.76, size * 0.5),
      gold,
    );
    canvas.drawLine(
      Offset(size * 0.5, size * 0.28),
      Offset(size * 0.5, size * 0.72),
      gold,
    );
  }

  void _drawBusinessGood(Canvas canvas, Size s) {
    final color = themed ? AppColors.maroon : const Color(0xFF9D174D);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size * 0.2, size * 0.34, size * 0.6, size * 0.42),
        Radius.circular(size * 0.08),
      ),
      Paint()..color = color,
    );
    canvas.drawArc(
      Rect.fromLTWH(size * 0.36, size * 0.22, size * 0.28, size * 0.22),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = color
        ..strokeWidth = size * 0.06
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(size * 0.5, size * 0.54),
      size * 0.05,
      Paint()..color = AppColors.goldLight,
    );
  }

  void _drawJewelGood(Canvas canvas, Size s) {
    final gem = Path()
      ..moveTo(size * 0.5, size * 0.16)
      ..lineTo(size * 0.78, size * 0.38)
      ..lineTo(size * 0.62, size * 0.82)
      ..lineTo(size * 0.38, size * 0.82)
      ..lineTo(size * 0.22, size * 0.38)
      ..close();
    canvas.drawPath(gem, Paint()..color = AppColors.gold);
    canvas.drawLine(
      Offset(size * 0.32, size * 0.4),
      Offset(size * 0.68, size * 0.4),
      Paint()
        ..color = AppColors.goldLight
        ..strokeWidth = size * 0.05,
    );
  }

  void _drawEducationGood(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = themed ? AppColors.maroonLight : const Color(0xFF2563EB);
    final book = Path()
      ..moveTo(size * 0.18, size * 0.28)
      ..quadraticBezierTo(size * 0.36, size * 0.18, size * 0.5, size * 0.32)
      ..quadraticBezierTo(size * 0.64, size * 0.18, size * 0.82, size * 0.28)
      ..lineTo(size * 0.82, size * 0.76)
      ..quadraticBezierTo(size * 0.64, size * 0.66, size * 0.5, size * 0.8)
      ..quadraticBezierTo(size * 0.36, size * 0.66, size * 0.18, size * 0.76)
      ..close();
    canvas.drawPath(book, paint);
    canvas.drawLine(
      Offset(size * 0.5, size * 0.34),
      Offset(size * 0.5, size * 0.78),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = size * 0.035,
    );
  }

  void _drawTempleLamp(Canvas canvas, Size s) {
    final gold = Paint()..color = AppColors.goldDark;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size * 0.5, size * 0.76),
        width: size * 0.5,
        height: size * 0.1,
      ),
      gold,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size * 0.5, size * 0.54),
          width: size * 0.12,
          height: size * 0.36,
        ),
        Radius.circular(size * 0.04),
      ),
      gold,
    );
    final flame = Path()
      ..moveTo(size * 0.5, size * 0.14)
      ..quadraticBezierTo(size * 0.3, size * 0.36, size * 0.5, size * 0.48)
      ..quadraticBezierTo(size * 0.7, size * 0.34, size * 0.5, size * 0.14);
    canvas.drawPath(flame, Paint()..color = const Color(0xFFFF8A00));
  }

  void _drawTamilMonth(Canvas canvas, Size s) {
    _drawTithiBadge(canvas, s, 'தி');
    canvas.drawCircle(
      Offset(size * 0.72, size * 0.27),
      size * 0.1,
      Paint()..color = AppColors.gold,
    );
  }

  void _drawFestival(Canvas canvas, Size s) {
    _drawTempleLamp(canvas, s);
    _drawStar(canvas, s, gold: true);
  }

  void _drawTithiBadge(Canvas canvas, Size s, String text) {
    final fill = Paint()
      ..color = themed ? AppColors.labelPink : const Color(0xFF9D174D);
    canvas.drawCircle(Offset(s.width / 2, s.height / 2), size * 0.38, fill);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * (text.length > 1 ? 0.28 : 0.36),
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    painter.paint(
      canvas,
      Offset((s.width - painter.width) / 2, (s.height - painter.height) / 2),
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
  if (moonPhase == 'amavasai' &&
      !bottom.any((id) => id == 'amavasai' || id == 'sarva_amavasai')) {
    bottom.insert(0, 'amavasai');
  }
  if (moonPhase == 'pournami' && !bottom.contains('pournami')) {
    bottom.insert(0, 'pournami');
  }
  return bottom;
}
