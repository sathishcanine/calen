import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'menu_icons.dart';

class NavActionCard extends StatelessWidget {
  const NavActionCard({
    super.key,
    required this.gradient,
    required this.iconKind,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compact = false,
    this.imageAsset,
  });

  final List<Color> gradient;
  final MenuIconKind iconKind;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _CompactNavCard(
        gradient: gradient,
        iconKind: iconKind,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        imageAsset: imageAsset,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDecorations.cardRadius),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: MenuIcon(kind: iconKind, size: 26)),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'திறக்க',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.goldLight, size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactNavCard extends StatelessWidget {
  const _CompactNavCard({
    required this.gradient,
    required this.iconKind,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageAsset,
  });

  final List<Color> gradient;
  final MenuIconKind iconKind;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageAsset != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      imageAsset!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: MenuIcon(kind: iconKind, size: 22)),
                  ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 9,
                        height: 1.2,
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
