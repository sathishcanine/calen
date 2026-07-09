import 'package:flutter/material.dart';

import 'home_section_header.dart';
import 'jyotish_palangal_menus.dart';
import 'menu_icons.dart';
import 'menu_row_tile.dart';

class AanmeegamMenuItem {
  const AanmeegamMenuItem({
    required this.label,
    required this.gradient,
    required this.onTap,
    this.iconKind,
    this.icon,
    this.imageAsset,
  });

  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final MenuIconKind? iconKind;
  final IconData? icon;
  final String? imageAsset;
}

/// ஆன்மீகம் tab — Noolagam-style rows + ஜோதிட கணக்கீடு + முக்கிய பலன்கள்.
class AanmeegamMenuGrid extends StatelessWidget {
  const AanmeegamMenuGrid({
    super.key,
    required this.spiritualItems,
    required this.palangalItems,
    required this.jyotishItems,
    required this.onOpenTemples,
  });

  final List<AanmeegamMenuItem> spiritualItems;
  final List<AanmeegamMenuItem> palangalItems;
  final List<JyotishMenuItem> jyotishItems;
  final VoidCallback onOpenTemples;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(title: 'ஜோதிட கணக்கீடு'),
        const SizedBox(height: 12),
        JyotishHorizontalScroller(items: jyotishItems),
        const SizedBox(height: 24),
        _TempleHeroButton(onTap: onOpenTemples),
        const SizedBox(height: 18),
        const HomeSectionHeader(
          title: 'ஆன்மீக தகவல்கள்',
          subtitle: 'பஞ்சாங்கம் · நேரங்கள் · வாஸ்து',
        ),
        const SizedBox(height: 12),
        _MenuGrid(items: spiritualItems),
        const SizedBox(height: 24),
        const HomeSectionHeader(
          title: 'முக்கிய பலன்கள்',
          subtitle: 'கனவு · பல்லி · தாரா · மச்சம்',
        ),
        const SizedBox(height: 12),
        _MenuGrid(items: palangalItems),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<AanmeegamMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 72,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuRowTile(
          label: item.label,
          gradient: item.gradient,
          onTap: item.onTap,
          iconKind: item.iconKind,
          icon: item.icon,
          imageAsset: item.imageAsset,
        );
      },
    );
  }
}

class _TempleHeroButton extends StatelessWidget {
  const _TempleHeroButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E1A47), Color(0xFF5B2E91)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E1A47).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/icon_temple.webp',
                    width: 62,
                    height: 62,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'பிரபல கோவில்கள்',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'படங்களுடன் ஆன்மிக யாத்திரை வழிகாட்டி',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFF5D78E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFFF5D78E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
