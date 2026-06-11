import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.goldAccent = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool goldAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: goldAccent ? AppDecorations.goldBorder() : AppDecorations.card(color: color),
      child: Padding(padding: padding, child: child),
    );
  }
}
