import 'package:flutter/material.dart';

import '../../models/library_book.dart';
import '../../services/calendar_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/library_book_tile.dart';
import 'library_category_screen.dart';
import 'library_pdf_viewer_screen.dart';
import 'library_styles.dart';

/// நூலகம் tab — bookstore-style sections with horizontal book rows.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const double _tileWidth = 108;

  List<BookCategory> _categories = [];
  Map<String, List<LibraryBook>> _booksByCategory = {};
  List<LibraryBook> _recentBooks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cats = await widget.repository.getLibraryCategories();
      final withBooks = cats.where((c) => c.bookCount > 0).toList();
      final results = await Future.wait(
        withBooks.map((c) => widget.repository.getLibraryBooks(c.id)),
      );

      final map = <String, List<LibraryBook>>{};
      for (var i = 0; i < withBooks.length; i++) {
        map[withBooks[i].id] = results[i];
      }

      final allBooks = results.expand((list) => list).toList()
        ..sort((a, b) {
          final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

      if (!mounted) return;
      setState(() {
        _categories = cats;
        _booksByCategory = map;
        _recentBooks = allBooks.take(12).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openBook(LibraryBook book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryPdfViewerScreen(book: book)),
    );
  }

  void _openCategory(BookCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryCategoryScreen(
          repository: widget.repository,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator(color: AppColors.maroon)),
      );
    }

    if (_error != null) {
      return _ErrorCard(message: _error!, onRetry: _load);
    }

    final hasAnyBooks = _booksByCategory.values.any((list) => list.isNotEmpty);
    if (!hasAnyBooks) {
      return _EmptyCard(onRetry: _load);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentBooks.isNotEmpty) ...[
          const LibrarySectionHeader(title: 'அண்மையில் சேர்க்கப்பட்டவை'),
          LibraryBookRow(
            books: _recentBooks,
            accent: AppColors.maroon,
            tileWidth: _tileWidth,
            onBookTap: _openBook,
          ),
        ],
        ..._categories.where((c) => (_booksByCategory[c.id]?.isNotEmpty ?? false)).map((category) {
          final books = _booksByCategory[category.id]!;
          final style = libraryStyleForCategory(category.id);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LibrarySectionHeader(
                title: category.name,
                onSeeAll: category.bookCount > 4 ? () => _openCategory(category) : null,
              ),
              LibraryBookRow(
                books: books,
                accent: style.accent,
                tileWidth: _tileWidth,
                onBookTap: _openBook,
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.maroon, size: 36),
          const SizedBox(height: 8),
          Text('நூலகத்தை ஏற்ற முடியவில்லை', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('மீண்டும் முயற்சி')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.library_books_outlined, size: 40, color: AppColors.textSecondary.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text('இன்னும் நூல்கள் சேர்க்கப்படவில்லை', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('புதுப்பிக்க')),
        ],
      ),
    );
  }
}
