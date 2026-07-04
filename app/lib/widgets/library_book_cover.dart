import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Lightweight cover thumbnail — PDF is fetched only when the user opens the book.
class LibraryBookCover extends StatelessWidget {
  const LibraryBookCover({
    super.key,
    required this.previewUrl,
    required this.accent,
    this.width,
    this.height,
    this.borderRadius = 10,
  });

  final String? previewUrl;
  final Color accent;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final w = width ?? double.infinity;
    final h = height ?? double.infinity;

    if (previewUrl != null && previewUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          previewUrl!,
          width: w == double.infinity ? null : w,
          height: h == double.infinity ? null : h,
          fit: BoxFit.cover,
          cacheWidth: 360,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(w, h, showSpinner: true);
          },
          errorBuilder: (context, error, stackTrace) => _placeholder(w, h),
        ),
      );
    }

    return _placeholder(w, h);
  }

  Widget _placeholder(double w, double h, {bool showSpinner = false}) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h == double.infinity ? null : h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.85), accent.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              )
            : const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class LibraryBookMeta extends StatelessWidget {
  const LibraryBookMeta({
    super.key,
    required this.title,
    required this.author,
    required this.fileSizeLabel,
  });

  final String title;
  final String author;
  final String fileSizeLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
        ),
        if (author.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          fileSizeLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
