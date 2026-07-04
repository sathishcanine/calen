import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LibraryCategoryStyle {
  const LibraryCategoryStyle({
    required this.gradient,
    required this.icon,
    required this.accent,
  });

  final LinearGradient gradient;
  final IconData icon;
  final Color accent;
}

LibraryCategoryStyle libraryStyleForCategory(String id) {
  switch (id) {
    case 'aanmeegam':
      return const LibraryCategoryStyle(
        gradient: AppDecorations.spiritualGradient,
        icon: Icons.self_improvement_rounded,
        accent: Color(0xFF9B7EDE),
      );
    case 'kavidhaigal':
      return const LibraryCategoryStyle(
        gradient: LinearGradient(
          colors: [Color(0xFF5B2C6F), Color(0xFF8E44AD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.auto_stories_rounded,
        accent: Color(0xFFBB8FCE),
      );
    case 'naavalgal':
      return const LibraryCategoryStyle(
        gradient: AppDecorations.tealGradient,
        icon: Icons.menu_book_rounded,
        accent: Color(0xFF76D7C4),
      );
    case 'siru-kadhaigal':
      return const LibraryCategoryStyle(
        gradient: LinearGradient(
          colors: [Color(0xFFB7472A), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.child_care_rounded,
        accent: Color(0xFFF5B041),
      );
    case 'varalaru':
      return const LibraryCategoryStyle(
        gradient: LinearGradient(
          colors: [Color(0xFF6E2C00), Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        icon: Icons.account_balance_rounded,
        accent: Color(0xFFD4A853),
      );
    default:
      return const LibraryCategoryStyle(
        gradient: AppDecorations.headerGradient,
        icon: Icons.folder_special_rounded,
        accent: AppColors.goldLight,
      );
  }
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
