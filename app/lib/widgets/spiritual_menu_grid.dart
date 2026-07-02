import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_section_header.dart';
import 'menu_icons.dart';

class SpiritualMenuItem {
  const SpiritualMenuItem({
    required this.label,
    required this.iconKind,
    required this.gradient,
    required this.onTap,
    this.featured = false,
    this.imageAsset,
  });

  final String label;
  final MenuIconKind iconKind;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final bool featured;
  final String? imageAsset;
}

/// Bento-style spiritual shortcuts with kaalavidya-themed icons.
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

  List<SpiritualMenuItem> _items() => [
        SpiritualMenuItem(
          label: 'இன்றைய பஞ்சாங்கம்',
          iconKind: MenuIconKind.panchangam,
          gradient: AppDecorations.spiritualGradient,
          onTap: onOpenPanchangam,
          featured: true,
          imageAsset: 'assets/images/icon_panchangam.webp',
        ),
        SpiritualMenuItem(
          label: 'இராகு, குளிகை, எமகண்டம்',
          iconKind: MenuIconKind.inauspicious,
          gradient: AppDecorations.tealGradient,
          onTap: onOpenInauspicious,
        ),
        SpiritualMenuItem(
          label: 'கௌரி பஞ்சாங்கம்',
          iconKind: MenuIconKind.gowri,
          gradient: AppDecorations.forestGradient,
          onTap: onOpenGowri,
        ),
        SpiritualMenuItem(
          label: 'கிரக ஓரைகளின் காலம்',
          iconKind: MenuIconKind.hora,
          gradient: const LinearGradient(
            colors: [Color(0xFF8B1A1A), Color(0xFFC62828)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: onOpenHora,
        ),
        SpiritualMenuItem(
          label: 'கரி நாட்கள், அஷ்டமி, நவமி மற்றும் தசமி',
          iconKind: MenuIconKind.kariNaatkal,
          gradient: const LinearGradient(
            colors: [Color(0xFF6B4F0A), Color(0xFF8B6914)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: onOpenKariNaatkal,
        ),
        SpiritualMenuItem(
          label: 'வாஸ்து நாட்கள் / தகவல்கள்',
          iconKind: MenuIconKind.vastu,
          gradient: const LinearGradient(
            colors: [Color(0xFF3E2723), Color(0xFF5D4037)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: onOpenVastu,
          imageAsset: 'assets/images/icon_temple.webp',
        ),
        SpiritualMenuItem(
          label: 'பஞ்ச பட்சி சாஸ்திரம் / கணக்கீடு',
          iconKind: MenuIconKind.panchaPakshi,
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFF9A825)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onTap: onOpenPanchaPakshi,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final items = _items();
    final featured = items.where((i) => i.featured).toList();
    final regular = items.where((i) => !i.featured).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomeSectionHeader(
          title: 'ஆன்மிக தகவல்கள்',
          subtitle: 'பஞ்சாங்கம் · நேரங்கள் · வாஸ்து',
        ),
        const SizedBox(height: 14),
        if (featured.isNotEmpty)
          _FeaturedSpiritualCard(item: featured.first),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 88,
          ),
          itemCount: regular.length,
          itemBuilder: (context, index) => _CompactSpiritualTile(item: regular[index]),
        ),
      ],
    );
  }
}

class _FeaturedSpiritualCard extends StatelessWidget {
  const _FeaturedSpiritualCard({required this.item});

  final SpiritualMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: item.gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: item.gradient.colors.first.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -20,
                  child: Opacity(
                    opacity: 0.15,
                    child: item.imageAsset != null
                        ? Image.asset(item.imageAsset!, width: 140, height: 140, fit: BoxFit.cover)
                        : MenuIcon(kind: item.iconKind, size: 140, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.4)),
                        ),
                        child: item.imageAsset != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(item.imageAsset!, fit: BoxFit.cover),
                              )
                            : Center(child: MenuIcon(kind: item.iconKind, size: 30)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  'இன்றைய விவரம்',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.goldLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward_rounded, color: AppColors.goldLight, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSpiritualTile extends StatelessWidget {
  const _CompactSpiritualTile({required this.item});

  final SpiritualMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppDecorations.glassCard(),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: AppDecorations.iconTile(item.gradient),
                child: item.imageAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
                        child: Image.asset(item.imageAsset!, fit: BoxFit.cover),
                      )
                    : Center(child: MenuIcon(kind: item.iconKind, size: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        fontSize: 10.5,
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
