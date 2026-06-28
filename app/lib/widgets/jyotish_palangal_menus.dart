import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class JyotishMenuItem {
  const JyotishMenuItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class PalangalMenuItem {
  const PalangalMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.kind = 'articles',
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String kind;
}

/// ஜோதிட கணக்கீடு + முக்கிய பலன்கள் — competitor-style home sections.
class JyotishPalangalMenus extends StatelessWidget {
  const JyotishPalangalMenus({
    super.key,
    required this.jyotishItems,
    required this.palangalItems,
  });

  final List<JyotishMenuItem> jyotishItems;
  final List<PalangalMenuItem> palangalItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'ஜோதிட கணக்கீடு',
          child: SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: jyotishItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (context, index) {
                final item = jyotishItems[index];
                return _CircleMenuTile(
                  label: item.label,
                  icon: item.icon,
                  color: item.color,
                  onTap: item.onTap,
                  size: 68,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionCard(
          title: 'முக்கிய பலன்கள்',
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 14,
              crossAxisSpacing: 10,
              mainAxisExtent: 108,
            ),
            itemCount: palangalItems.length,
            itemBuilder: (context, index) {
              final item = palangalItems[index];
              return _SquareMenuTile(
                label: item.label,
                icon: item.icon,
                color: item.color,
                onTap: item.onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CircleMenuTile extends StatelessWidget {
  const _CircleMenuTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.size,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareMenuTile extends StatelessWidget {
  const _SquareMenuTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData palangalIconFromName(String name) {
  switch (name) {
    case 'bedtime':
      return Icons.bedtime_rounded;
    case 'pest_control':
      return Icons.pest_control_rounded;
    case 'record_voice_over':
      return Icons.record_voice_over_rounded;
    case 'home_work':
      return Icons.home_work_rounded;
    case 'stars':
      return Icons.stars_rounded;
    case 'face':
      return Icons.face_rounded;
    case 'volunteer_activism':
      return Icons.volunteer_activism_rounded;
    case 'light_mode':
      return Icons.light_mode_rounded;
    default:
      return Icons.auto_awesome_rounded;
  }
}

Color palangalColorFromHex(String hex) {
  final value = hex.replaceAll('#', '');
  if (value.length == 6) {
    return Color(int.parse('FF$value', radix: 16));
  }
  return AppColors.maroon;
}
