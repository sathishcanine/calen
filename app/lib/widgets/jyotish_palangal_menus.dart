import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_section_header.dart';
import 'menu_icons.dart';
import 'menu_row_tile.dart';

class JyotishMenuItem {
  const JyotishMenuItem({
    required this.label,
    required this.iconKind,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final MenuIconKind iconKind;
  final LinearGradient gradient;
  final VoidCallback onTap;
}

class PalangalMenuItem {
  const PalangalMenuItem({
    required this.id,
    required this.label,
    required this.iconKind,
    required this.gradient,
    required this.onTap,
    this.kind = 'articles',
  });

  final String id;
  final String label;
  final MenuIconKind iconKind;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final String kind;
}

/// ஜோதிட கணக்கீடு + முக்கிய பலன்கள் — modern card layout.
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
        const HomeSectionHeader(title: 'ஜோதிட கணக்கீடு'),
        const SizedBox(height: 12),
        JyotishHorizontalScroller(items: jyotishItems),
        const SizedBox(height: 24),
        const HomeSectionHeader(
          title: 'முக்கிய பலன்கள்',
          subtitle: 'கனவு · பல்லி · தாரா · மச்சம்',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 72,
          ),
          itemCount: palangalItems.length,
          itemBuilder: (context, index) => MenuRowTile(
            label: palangalItems[index].label,
            gradient: palangalItems[index].gradient,
            onTap: palangalItems[index].onTap,
            iconKind: palangalItems[index].iconKind,
          ),
        ),
      ],
    );
  }
}

/// Horizontal ஜோதிட கணக்கீடு scroller — shared by Noolagam & Aanmeegam tabs.
class JyotishHorizontalScroller extends StatelessWidget {
  const JyotishHorizontalScroller({super.key, required this.items});

  final List<JyotishMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _JyotishCard(item: items[index]),
      ),
    );
  }
}

class _JyotishCard extends StatelessWidget {
  const _JyotishCard({required this.item});

  final JyotishMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 130,
          child: Ink(
            decoration: BoxDecoration(
            gradient: item.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: item.gradient.colors.first.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: MenuIcon(kind: item.iconKind, size: 24)),
                ),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ),
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

LinearGradient palangalGradientFromHex(String hex) {
  final base = palangalColorFromHex(hex);
  return LinearGradient(
    colors: [base, Color.lerp(base, Colors.white, 0.25)!],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
