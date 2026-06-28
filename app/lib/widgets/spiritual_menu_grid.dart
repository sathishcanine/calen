import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SpiritualMenuItem {
  const SpiritualMenuItem({
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

/// SS1 spiritual shortcuts — 3-column grid.
class SpiritualMenuGrid extends StatelessWidget {
  const SpiritualMenuGrid({
    super.key,
    required this.onOpenPanchangam,
    required this.onOpenInauspicious,
    required this.onOpenGowri,
    required this.onOpenHora,
    required this.onOpenKariNaatkal,
    required this.onOpenVastu,
    required this.onOpenPanchaPakshi,
  });

  final VoidCallback onOpenPanchangam;
  final VoidCallback onOpenInauspicious;
  final VoidCallback onOpenGowri;
  final VoidCallback onOpenHora;
  final VoidCallback onOpenKariNaatkal;
  final VoidCallback onOpenVastu;
  final VoidCallback onOpenPanchaPakshi;

  @override
  Widget build(BuildContext context) {
    final items = [
      SpiritualMenuItem(
        label: 'இன்றைய பஞ்சாங்கம்',
        icon: Icons.auto_awesome,
        color: const Color(0xFF2C1F5C),
        onTap: onOpenPanchangam,
      ),
      SpiritualMenuItem(
        label: 'இராகு, குளிகை, எமகண்டம்',
        icon: Icons.schedule_rounded,
        color: const Color(0xFF2D9B9B),
        onTap: onOpenInauspicious,
      ),
      SpiritualMenuItem(
        label: 'கௌரி பஞ்சாங்கம்',
        icon: Icons.star_outline_rounded,
        color: const Color(0xFF2E8B57),
        onTap: onOpenGowri,
      ),
      SpiritualMenuItem(
        label: 'கிரக ஓரைகளின் காலம்',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFC62828),
        onTap: onOpenHora,
      ),
      SpiritualMenuItem(
        label: 'கரி நாட்கள், அஷ்டமி, நவமி மற்றும் தசமி',
        icon: Icons.event_busy_rounded,
        color: const Color(0xFF8B6914),
        onTap: onOpenKariNaatkal,
      ),
      SpiritualMenuItem(
        label: 'வாஸ்து நாட்கள் / தகவல்கள்',
        icon: Icons.temple_hindu_rounded,
        color: const Color(0xFF5D4037),
        onTap: onOpenVastu,
      ),
      SpiritualMenuItem(
        label: 'பஞ்ச பட்சி சாஸ்திரம் / கணக்கீடு',
        icon: Icons.grid_view_rounded,
        color: const Color(0xFFF9A825),
        onTap: onOpenPanchaPakshi,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ஆன்மிக தகவல்கள்',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            mainAxisExtent: 128,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _SpiritualMenuTile(item: items[index]),
        ),
      ],
    );
  }
}

class _SpiritualMenuTile extends StatelessWidget {
  const _SpiritualMenuTile({required this.item});

  final SpiritualMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
