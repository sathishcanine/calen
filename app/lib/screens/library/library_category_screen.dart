import 'package:flutter/material.dart';

import '../../models/library_book.dart';
import '../../services/calendar_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/library_book_tile.dart';
import 'library_pdf_viewer_screen.dart';
import 'library_styles.dart';

/// Full category view — 3-column bookstore grid.
class LibraryCategoryScreen extends StatefulWidget {
  const LibraryCategoryScreen({
    super.key,
    required this.repository,
    required this.category,
  });

  final CalendarRepository repository;
  final BookCategory category;

  @override
  State<LibraryCategoryScreen> createState() => _LibraryCategoryScreenState();
}

class _LibraryCategoryScreenState extends State<LibraryCategoryScreen> {
  List<LibraryBook> _books = [];
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
      final books = await widget.repository.getLibraryBooks(widget.category.id);
      if (!mounted) return;
      setState(() {
        _books = books;
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

  @override
  Widget build(BuildContext context) {
    final style = libraryStyleForCategory(widget.category.id);
    final screenWidth = MediaQuery.sizeOf(context).width;
    const horizontalPadding = 16.0;
    const crossSpacing = 14.0;
    const columns = 3;
    final tileWidth =
        (screenWidth - horizontalPadding * 2 - crossSpacing * (columns - 1)) / columns;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.maroon))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('மீண்டும் முயற்சி')),
                      ],
                    ),
                  ),
                )
              : _books.isEmpty
                  ? Center(
                      child: Text(
                        'இந்த வகையில் நூல்கள் இல்லை',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: crossSpacing,
                        childAspectRatio: tileWidth / (LibraryBookTile.rowHeightFor(tileWidth)),
                      ),
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return LibraryBookTile(
                          book: book,
                          accent: style.accent,
                          width: tileWidth,
                          onTap: () => _openBook(book),
                        );
                      },
                    ),
    );
  }
}
