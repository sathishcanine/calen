import 'package:flutter/material.dart';

import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import 'raasi_sign_selector_screen.dart';

class RaasiPalanHubScreen extends StatelessWidget {
  const RaasiPalanHubScreen({super.key, required this.repository});

  final CalendarRepository repository;

  void _openSelector(BuildContext context, RaasiPalanType type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RaasiSignSelectorScreen(
          type: type,
          title: title,
          repository: repository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('ராசி பலன்கள்')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's horoscope – full-width card
            _HubListTile(
              iconWidget: _gradientIcon(
                const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                Icons.wb_sunny_rounded,
              ),
              title: 'இன்றைய ராசிபலன்',
              subtitle: "Today's Horoscope",
              onTap: () => _openSelector(
                context,
                RaasiPalanType.today,
                'இன்றைய ராசிபலன்',
              ),
            ),
            const SizedBox(height: 16),

            // Period cards — one by one (full width)
            _PeriodListCard(
              title: 'வார ராசிபலன்',
              subtitle: 'Weekly Horoscope',
              gradient: const LinearGradient(
                colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.calendar_view_week_rounded,
              onTap: () => _openSelector(
                context,
                RaasiPalanType.weekly,
                'வார ராசிபலன்',
              ),
            ),
            const SizedBox(height: 12),
            _PeriodListCard(
              title: 'மாத ராசிபலன்',
              subtitle: 'Monthly Horoscope',
              gradient: const LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.calendar_month_rounded,
              onTap: () => _openSelector(
                context,
                RaasiPalanType.monthly,
                'மாத ராசிபலன்',
              ),
            ),
            const SizedBox(height: 12),
            _PeriodListCard(
              title: 'ஆண்டு ராசிபலன்',
              subtitle: 'Yearly Horoscope',
              gradient: const LinearGradient(
                colors: [Color(0xFFAD1457), Color(0xFFE91E8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              icon: Icons.auto_awesome_rounded,
              onTap: () => _openSelector(
                context,
                RaasiPalanType.yearly,
                'ஆண்டு ராசிபலன்',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientIcon(LinearGradient gradient, IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

// ─────────────────────────────────────────
// Reusable full-width info list tile
// ─────────────────────────────────────────
class _HubListTile extends StatelessWidget {
  const _HubListTile({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget iconWidget;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.maroon.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// Full-width period card (stacked one by one)
// ─────────────────────────────────────────
class _PeriodListCard extends StatelessWidget {
  const _PeriodListCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
