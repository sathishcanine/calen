import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_section_header.dart';
import 'menu_icons.dart';

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

/// Compact 2-column spiritual menu for the ஆன்மீகம் tab.
class AanmeegamMenuGrid extends StatelessWidget {
  const AanmeegamMenuGrid({
    super.key,
    required this.spiritualItems,
    required this.palangalItems,
  });

  final List<AanmeegamMenuItem> spiritualItems;
  final List<AanmeegamMenuItem> palangalItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'ஆன்மீக தகவல்கள்',
          subtitle: 'பஞ்சாங்கம் · நேரங்கள் · வாஸ்து',
          items: spiritualItems,
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'முக்கிய பலன்கள்',
          subtitle: 'கனவு · பல்லி · தாரா · மச்சம்',
          items: palangalItems,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<AanmeegamMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.maroon.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 50,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _AanmeegamTile(item: items[index]),
          ),
        ],
      ),
    );
  }
}

class _AanmeegamTile extends StatelessWidget {
  const _AanmeegamTile({required this.item});

  final AanmeegamMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.maroon.withValues(alpha: 0.08),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: item.gradient.colors.first.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageAsset != null
                      ? Image.asset(item.imageAsset!, fit: BoxFit.cover)
                      : Center(
                          child: item.iconKind != null
                              ? MenuIcon(kind: item.iconKind!, size: 20)
                              : Icon(
                                  item.icon ?? Icons.auto_awesome_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        height: 1.15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
