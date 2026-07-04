import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/budget.dart';

/// Line-art category icons matching the spendings manager reference design.
class BudgetCategoryIcon extends StatelessWidget {
  const BudgetCategoryIcon({
    super.key,
    required this.kind,
    this.size = 28,
    this.color,
  });

  final BudgetCategoryKind kind;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BudgetCategoryIconPainter(
          kind: kind,
          color: color ?? BudgetCategoryIcon.defaultColor(kind),
        ),
      ),
    );
  }

  static Color defaultColor(BudgetCategoryKind kind) {
    switch (kind) {
      case BudgetCategoryKind.salary:
        return const Color(0xFF40916C);
      case BudgetCategoryKind.fuel:
        return const Color(0xFF5B8DEF);
      case BudgetCategoryKind.travel:
        return const Color(0xFFE05D5D);
      case BudgetCategoryKind.general:
        return const Color(0xFFF4C430);
      case BudgetCategoryKind.holidays:
        return const Color(0xFF9B72CF);
      case BudgetCategoryKind.kids:
        return const Color(0xFFE07A9A);
      case BudgetCategoryKind.shopping:
        return const Color(0xFF52B788);
      case BudgetCategoryKind.bills:
        return const Color(0xFFF4C430);
      case BudgetCategoryKind.car:
        return const Color(0xFF5B8DEF);
      case BudgetCategoryKind.clothes:
        return const Color(0xFF9B72CF);
      case BudgetCategoryKind.communications:
        return const Color(0xFF9B72CF);
      case BudgetCategoryKind.eatingOut:
        return const Color(0xFF52B788);
      case BudgetCategoryKind.entertainment:
        return const Color(0xFFE8925A);
      case BudgetCategoryKind.food:
        return const Color(0xFFE07A9A);
      case BudgetCategoryKind.gifts:
        return const Color(0xFFE07A9A);
      case BudgetCategoryKind.health:
        return const Color(0xFFE05D5D);
      case BudgetCategoryKind.house:
        return const Color(0xFF5B8DEF);
      case BudgetCategoryKind.pets:
        return const Color(0xFF52B788);
      case BudgetCategoryKind.sports:
        return const Color(0xFF4ECDC4);
      case BudgetCategoryKind.taxi:
        return const Color(0xFFF4C430);
      case BudgetCategoryKind.toiletry:
        return const Color(0xFF5B8DEF);
      case BudgetCategoryKind.transport:
        return const Color(0xFFE05D5D);
      case BudgetCategoryKind.custom:
        return const Color(0xFF9E9E9E);
    }
  }
}

class _BudgetCategoryIconPainter extends CustomPainter {
  _BudgetCategoryIconPainter({required this.kind, required this.color});

  final BudgetCategoryKind kind;
  final Color color;

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    switch (kind) {
      case BudgetCategoryKind.salary:
        _drawSalary(canvas, cx, cy, r);
      case BudgetCategoryKind.fuel:
        _drawCar(canvas, cx, cy, r);
      case BudgetCategoryKind.travel:
        _drawTrain(canvas, cx, cy, r);
      case BudgetCategoryKind.general:
        _drawCustom(canvas, cx, cy, r);
      case BudgetCategoryKind.holidays:
        _drawGift(canvas, cx, cy, r);
      case BudgetCategoryKind.kids:
        _drawCat(canvas, cx, cy, r);
      case BudgetCategoryKind.shopping:
        _drawBasket(canvas, cx, cy, r);
      case BudgetCategoryKind.bills:
        _drawBills(canvas, cx, cy, r);
      case BudgetCategoryKind.car:
        _drawCar(canvas, cx, cy, r);
      case BudgetCategoryKind.clothes:
        _drawClothes(canvas, cx, cy, r);
      case BudgetCategoryKind.communications:
        _drawPhone(canvas, cx, cy, r);
      case BudgetCategoryKind.eatingOut:
        _drawCutlery(canvas, cx, cy, r);
      case BudgetCategoryKind.entertainment:
        _drawCocktail(canvas, cx, cy, r);
      case BudgetCategoryKind.food:
        _drawBasket(canvas, cx, cy, r);
      case BudgetCategoryKind.gifts:
        _drawGift(canvas, cx, cy, r);
      case BudgetCategoryKind.health:
        _drawThermometer(canvas, cx, cy, r);
      case BudgetCategoryKind.house:
        _drawHouse(canvas, cx, cy, r);
      case BudgetCategoryKind.pets:
        _drawCat(canvas, cx, cy, r);
      case BudgetCategoryKind.sports:
        _drawSports(canvas, cx, cy, r);
      case BudgetCategoryKind.taxi:
        _drawTaxi(canvas, cx, cy, r);
      case BudgetCategoryKind.toiletry:
        _drawToiletry(canvas, cx, cy, r);
      case BudgetCategoryKind.transport:
        _drawTrain(canvas, cx, cy, r);
      case BudgetCategoryKind.custom:
        _drawCustom(canvas, cx, cy, r);
    }
  }

  void _drawSalary(Canvas canvas, double cx, double cy, double r) {
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(cx, cy + i * r * 0.22 - r * 0.22),
        r * 0.42,
        _stroke,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(color: color, fontSize: r * 0.55, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - r * 0.55 - tp.height / 2));
  }

  void _drawBills(Canvas canvas, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx - r * 0.35, cy - r * 0.55)
      ..lineTo(cx + r * 0.45, cy - r * 0.75)
      ..lineTo(cx + r * 0.25, cy + r * 0.65)
      ..lineTo(cx - r * 0.55, cy + r * 0.45)
      ..close();
    canvas.drawPath(path, _stroke);
    final tp = TextPainter(
      text: TextSpan(
        text: '₹',
        style: TextStyle(color: color, fontSize: r * 0.5, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawCar(Canvas canvas, double cx, double cy, double r) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: r * 1.8, height: r * 0.9),
      Radius.circular(r * 0.15),
    );
    canvas.drawRRect(body, _stroke);
    canvas.drawLine(Offset(cx - r * 0.5, cy - r * 0.1), Offset(cx + r * 0.2, cy - r * 0.1), _stroke);
    canvas.drawCircle(Offset(cx - r * 0.55, cy + r * 0.45), r * 0.18, _stroke);
    canvas.drawCircle(Offset(cx + r * 0.55, cy + r * 0.45), r * 0.18, _stroke);
  }

  void _drawClothes(Canvas canvas, double cx, double cy, double r) {
    canvas.drawLine(Offset(cx, cy - r * 0.7), Offset(cx, cy + r * 0.15), _stroke);
    canvas.drawLine(Offset(cx - r * 0.75, cy - r * 0.35), Offset(cx + r * 0.75, cy - r * 0.35), _stroke);
    canvas.drawLine(Offset(cx - r * 0.75, cy - r * 0.35), Offset(cx - r * 0.55, cy + r * 0.65), _stroke);
    canvas.drawLine(Offset(cx + r * 0.75, cy - r * 0.35), Offset(cx + r * 0.55, cy + r * 0.65), _stroke);
  }

  void _drawPhone(Canvas canvas, double cx, double cy, double r) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 0.95, height: r * 1.5),
      Radius.circular(r * 0.2),
    );
    canvas.drawRRect(rect, _stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - r * 0.05, cy + r * 0.55), width: r * 0.55, height: r * 0.35),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      _stroke,
    );
  }

  void _drawCutlery(Canvas canvas, double cx, double cy, double r) {
    canvas.drawLine(Offset(cx - r * 0.35, cy - r * 0.7), Offset(cx - r * 0.35, cy + r * 0.65), _stroke);
    canvas.drawLine(Offset(cx - r * 0.55, cy - r * 0.55), Offset(cx - r * 0.15, cy - r * 0.55), _stroke);
    canvas.drawLine(Offset(cx + r * 0.35, cy - r * 0.7), Offset(cx + r * 0.35, cy + r * 0.65), _stroke);
    canvas.drawLine(Offset(cx + r * 0.15, cy - r * 0.55), Offset(cx + r * 0.55, cy - r * 0.55), _stroke);
  }

  void _drawCocktail(Canvas canvas, double cx, double cy, double r) {
    canvas.drawLine(Offset(cx - r * 0.55, cy - r * 0.65), Offset(cx + r * 0.15, cy + r * 0.55), _stroke);
    canvas.drawLine(Offset(cx + r * 0.15, cy + r * 0.55), Offset(cx + r * 0.55, cy + r * 0.55), _stroke);
    canvas.drawLine(Offset(cx - r * 0.55, cy - r * 0.65), Offset(cx - r * 0.15, cy - r * 0.65), _stroke);
    canvas.drawCircle(Offset(cx + r * 0.35, cy - r * 0.45), r * 0.12, _fill);
  }

  void _drawBasket(Canvas canvas, double cx, double cy, double r) {
    final path = Path()
      ..moveTo(cx - r * 0.65, cy - r * 0.15)
      ..lineTo(cx - r * 0.45, cy + r * 0.65)
      ..lineTo(cx + r * 0.45, cy + r * 0.65)
      ..lineTo(cx + r * 0.65, cy - r * 0.15)
      ..close();
    canvas.drawPath(path, _stroke);
    canvas.drawLine(Offset(cx - r * 0.75, cy - r * 0.15), Offset(cx + r * 0.75, cy - r * 0.15), _stroke);
    canvas.drawLine(Offset(cx - r * 0.35, cy - r * 0.55), Offset(cx - r * 0.15, cy - r * 0.15), _stroke);
    canvas.drawLine(Offset(cx + r * 0.35, cy - r * 0.55), Offset(cx + r * 0.15, cy - r * 0.15), _stroke);
  }

  void _drawGift(Canvas canvas, double cx, double cy, double r) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.1), width: r * 1.2, height: r * 1.0),
      _stroke,
    );
    canvas.drawLine(Offset(cx, cy - r * 0.4), Offset(cx, cy + r * 0.6), _stroke);
    canvas.drawLine(Offset(cx - r * 0.6, cy + r * 0.1), Offset(cx + r * 0.6, cy + r * 0.1), _stroke);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - r * 0.18, cy - r * 0.45), width: r * 0.4, height: r * 0.35),
      math.pi,
      math.pi,
      false,
      _stroke,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + r * 0.18, cy - r * 0.45), width: r * 0.4, height: r * 0.35),
      math.pi,
      math.pi,
      false,
      _stroke,
    );
  }

  void _drawThermometer(Canvas canvas, double cx, double cy, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - r * 0.05), width: r * 0.35, height: r * 1.2),
        Radius.circular(r * 0.18),
      ),
      _stroke,
    );
    canvas.drawCircle(Offset(cx, cy + r * 0.55), r * 0.22, _stroke);
    canvas.drawLine(Offset(cx, cy - r * 0.45), Offset(cx, cy + r * 0.15), _stroke..strokeWidth = 3);
  }

  void _drawHouse(Canvas canvas, double cx, double cy, double r) {
    final roof = Path()
      ..moveTo(cx, cy - r * 0.75)
      ..lineTo(cx - r * 0.75, cy - r * 0.05)
      ..lineTo(cx + r * 0.75, cy - r * 0.05)
      ..close();
    canvas.drawPath(roof, _stroke);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.35), width: r * 1.1, height: r * 0.85),
      _stroke,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy + r * 0.45), width: r * 0.28, height: r * 0.35),
      _stroke,
    );
  }

  void _drawCat(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy + r * 0.1), r * 0.45, _stroke);
    canvas.drawLine(Offset(cx - r * 0.25, cy - r * 0.35), Offset(cx - r * 0.45, cy - r * 0.75), _stroke);
    canvas.drawLine(Offset(cx + r * 0.25, cy - r * 0.35), Offset(cx + r * 0.45, cy - r * 0.75), _stroke);
    canvas.drawCircle(Offset(cx - r * 0.15, cy + r * 0.05), r * 0.06, _fill);
    canvas.drawCircle(Offset(cx + r * 0.15, cy + r * 0.05), r * 0.06, _fill);
  }

  void _drawSports(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx + r * 0.35, cy + r * 0.35), r * 0.28, _stroke);
    canvas.drawLine(Offset(cx - r * 0.65, cy + r * 0.55), Offset(cx + r * 0.05, cy - r * 0.15), _stroke);
    canvas.drawLine(Offset(cx - r * 0.15, cy - r * 0.55), Offset(cx + r * 0.05, cy - r * 0.15), _stroke);
    canvas.drawLine(Offset(cx - r * 0.45, cy - r * 0.05), Offset(cx + r * 0.05, cy - r * 0.15), _stroke);
  }

  void _drawTaxi(Canvas canvas, double cx, double cy, double r) {
    _drawCar(canvas, cx, cy + r * 0.05, r * 0.85);
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - r * 0.55), width: r * 0.55, height: r * 0.22),
      _stroke,
    );
  }

  void _drawToiletry(Canvas canvas, double cx, double cy, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - r * 0.25, cy), width: r * 0.35, height: r * 1.1),
        Radius.circular(r * 0.08),
      ),
      _stroke,
    );
    canvas.drawLine(Offset(cx + r * 0.15, cy - r * 0.55), Offset(cx + r * 0.15, cy + r * 0.55), _stroke);
    canvas.drawLine(Offset(cx + r * 0.45, cy - r * 0.55), Offset(cx + r * 0.45, cy + r * 0.55), _stroke);
    canvas.drawLine(Offset(cx + r * 0.15, cy - r * 0.55), Offset(cx + r * 0.45, cy - r * 0.55), _stroke);
  }

  void _drawTrain(Canvas canvas, double cx, double cy, double r) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: r * 1.3, height: r * 1.0),
        Radius.circular(r * 0.12),
      ),
      _stroke,
    );
    canvas.drawLine(Offset(cx - r * 0.65, cy - r * 0.05), Offset(cx + r * 0.65, cy - r * 0.05), _stroke);
    canvas.drawCircle(Offset(cx - r * 0.35, cy + r * 0.45), r * 0.12, _fill);
    canvas.drawCircle(Offset(cx + r * 0.35, cy + r * 0.45), r * 0.12, _fill);
  }

  void _drawCustom(Canvas canvas, double cx, double cy, double r) {
    canvas.drawCircle(Offset(cx, cy), r * 0.55, _stroke);
    canvas.drawLine(Offset(cx, cy - r * 0.2), Offset(cx, cy + r * 0.2), _stroke);
    canvas.drawLine(Offset(cx - r * 0.2, cy), Offset(cx + r * 0.2, cy), _stroke);
  }

  @override
  bool shouldRepaint(covariant _BudgetCategoryIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

enum BudgetUtilityIconKind { calendar, cash, backspace, pen }

class BudgetUtilityIcon extends StatelessWidget {
  const BudgetUtilityIcon({
    super.key,
    required this.kind,
    this.size = 24,
    this.color = Colors.white,
  });

  final BudgetUtilityIconKind kind;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BudgetUtilityIconPainter(kind: kind, color: color),
      ),
    );
  }
}

class _BudgetUtilityIconPainter extends CustomPainter {
  _BudgetUtilityIconPainter({required this.kind, required this.color});

  final BudgetUtilityIconKind kind;
  final Color color;

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  Paint get _fill => Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.38;

    switch (kind) {
      case BudgetUtilityIconKind.calendar:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy + r * 0.05), width: r * 1.5, height: r * 1.3),
            Radius.circular(3),
          ),
          _stroke,
        );
        canvas.drawLine(Offset(cx - r * 0.55, cy - r * 0.15), Offset(cx + r * 0.55, cy - r * 0.15), _stroke);
        canvas.drawCircle(Offset(cx - r * 0.35, cy + r * 0.25), 2, _fill);
        canvas.drawCircle(Offset(cx + r * 0.35, cy + r * 0.25), 2, _fill);
      case BudgetUtilityIconKind.cash:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx - r * 0.1, cy - r * 0.08), width: r * 1.2, height: r * 0.75),
            Radius.circular(3),
          ),
          _stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx + r * 0.1, cy + r * 0.08), width: r * 1.2, height: r * 0.75),
            Radius.circular(3),
          ),
          _stroke,
        );
        canvas.drawCircle(Offset(cx, cy), r * 0.18, _stroke);
      case BudgetUtilityIconKind.backspace:
        final path = Path()
          ..moveTo(cx + r * 0.55, cy - r * 0.45)
          ..lineTo(cx - r * 0.05, cy - r * 0.45)
          ..lineTo(cx - r * 0.55, cy)
          ..lineTo(cx - r * 0.05, cy + r * 0.45)
          ..lineTo(cx + r * 0.55, cy + r * 0.45)
          ..close();
        canvas.drawPath(path, _stroke);
        canvas.drawLine(Offset(cx + r * 0.05, cy - r * 0.15), Offset(cx + r * 0.35, cy + r * 0.15), _stroke);
        canvas.drawLine(Offset(cx + r * 0.35, cy - r * 0.15), Offset(cx + r * 0.05, cy + r * 0.15), _stroke);
      case BudgetUtilityIconKind.pen:
        canvas.drawLine(Offset(cx - r * 0.45, cy + r * 0.45), Offset(cx + r * 0.35, cy - r * 0.35), _stroke..strokeWidth = 2.2);
        canvas.drawLine(Offset(cx + r * 0.35, cy - r * 0.35), Offset(cx + r * 0.55, cy - r * 0.55), _stroke..strokeWidth = 2.2);
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetUtilityIconPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
