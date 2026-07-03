import 'package:flutter/material.dart';

import '../services/daily_event_details.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'calendar_day_icons.dart';
import 'kolam_pattern.dart';

/// Event summary card for daily calendar detail — matches app maroon/gold theme.
class DayEventsCard extends StatelessWidget {
  const DayEventsCard({super.key, required this.details});

  final DailyEventDetails details;

  @override
  Widget build(BuildContext context) {
    if (details.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
          child: Column(
            children: [
              if (details.headerLabels.isNotEmpty) _HeaderBar(labels: details.headerLabels),
              if (details.iconIds.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: AppColors.cream.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: details.iconIds
                        .map(
                          (id) => CalendarDayIcon(
                            iconId: id,
                            size: 32,
                            themed: true,
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (details.footerLabels.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, 1),
                        painter: _DashedLinePainter(
                          color: AppColors.maroon.withValues(alpha: 0.18),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    children: details.footerLabels
                        .map(
                          (label) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 16,
                                  color: AppColors.maroon.withValues(alpha: 0.65),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppDecorations.headerGradient),
      child: KolamPattern(
        opacity: 0.08,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            labels.join(', '),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.45,
                ),
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var start = 0.0;
    while (start < size.width) {
      canvas.drawLine(Offset(start, 0), Offset(start + dashWidth, 0), paint);
      start += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
