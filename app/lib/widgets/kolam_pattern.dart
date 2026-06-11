import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Subtle dot-grid pattern inspired by kolam / rangoli — adds cultural texture without assets.
class KolamPattern extends StatelessWidget {
  const KolamPattern({super.key, required this.child, this.opacity = 0.06});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _KolamPainter(opacity: opacity),
          ),
        ),
        child,
      ],
    );
  }
}

class _KolamPainter extends CustomPainter {
  _KolamPainter({required this.opacity});

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const dotRadius = 1.8;

    for (var x = spacing / 2; x < size.width; x += spacing) {
      for (var y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
