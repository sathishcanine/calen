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
  });

  final List<AanmeegamMenuItem> spiritualItems;
  final List<AanmeegamMenuItem> palangalItems;
  final List<JyotishMenuItem> jyotishItems;

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
