import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'menu_icons.dart';

/// List-style menu row — icon tile, label, chevron (Noolagam / Mukkiya palangal design).
class MenuRowTile extends StatelessWidget {
  const MenuRowTile({
    super.key,
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppDecorations.glassCard(),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppDecorations.iconTile(gradient),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDecorations.cardRadiusSm),
                  child: imageAsset != null
                      ? Image.asset(imageAsset!, fit: BoxFit.cover)
                      : Center(
                          child: iconKind != null
                              ? MenuIcon(kind: iconKind!, size: 22)
                              : Icon(icon ?? Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.maroon.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
