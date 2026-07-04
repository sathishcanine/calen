import 'package:flutter/material.dart';

import '../models/library_book.dart';
import '../theme/app_theme.dart';
import 'library_book_cover.dart';

/// Store-style book card: portrait cover, title, author (reference layout).
class LibraryBookTile extends StatelessWidget {
  const LibraryBookTile({
    super.key,
    required this.book,
    required this.accent,
    required this.onTap,
    this.width = 108,
  });

  final LibraryBook book;
  final Color accent;
  final VoidCallback onTap;
  final double width;

  static const double _coverAspect = 1.48;

  double get coverHeight => width * _coverAspect;

  static double rowHeightFor(double tileWidth) => tileWidth * _coverAspect + 52;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: LibraryBookCover(
                    previewUrl: book.previewUrl,
                    accent: accent,
                    width: width,
                    height: coverHeight,
                    borderRadius: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.2,
                      ),
                ),
                if (book.author.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
                          fontSize: 12,
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey section header with optional "see all" action.
class LibrarySectionHeader extends StatelessWidget {
  const LibrarySectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                  ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.maroon,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('அனைத்தும்', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// Horizontal row of book tiles under a section header.
class LibraryBookRow extends StatelessWidget {
  const LibraryBookRow({
    super.key,
    required this.books,
    required this.accent,
    required this.onBookTap,
    this.tileWidth = 108,
  });

  final List<LibraryBook> books;
  final Color accent;
  final ValueChanged<LibraryBook> onBookTap;
  final double tileWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LibraryBookTile.rowHeightFor(tileWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: books.length,
        separatorBuilder: (_, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final book = books[index];
          return LibraryBookTile(
            book: book,
            accent: accent,
            width: tileWidth,
            onTap: () => onBookTap(book),
          );
        },
      ),
    );
  }
}
