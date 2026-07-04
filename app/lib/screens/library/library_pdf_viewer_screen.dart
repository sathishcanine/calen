import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../models/library_book.dart';
import '../../theme/app_theme.dart';

class LibraryPdfViewerScreen extends StatefulWidget {
  const LibraryPdfViewerScreen({super.key, required this.book});

  final LibraryBook book;

  @override
  State<LibraryPdfViewerScreen> createState() => _LibraryPdfViewerScreenState();
}

class _LibraryPdfViewerScreenState extends State<LibraryPdfViewerScreen> {
  PdfControllerPinch? _controller;
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _pages = 0;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final res = await http.get(Uri.parse(widget.book.pdfUrl));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final document = await PdfDocument.openData(res.bodyBytes);
      if (!mounted) return;
      setState(() {
        _controller = PdfControllerPinch(document: Future.value(document));
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.maroonDark,
        foregroundColor: Colors.white,
        actions: [
          if (_pages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_page / $_pages',
                  style: const TextStyle(fontSize: 14, color: AppColors.goldLight),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.gold),
                  SizedBox(height: 12),
                  Text('PDF ஏற்றுகிறது…', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'PDF திறக்க முடியவில்லை',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _loadPdf();
                        }, child: const Text('மீண்டும் முயற்சி')),
                      ],
                    ),
                  ),
                )
              : PdfViewPinch(
                  controller: _controller!,
                  onDocumentLoaded: (doc) {
                    setState(() => _pages = doc.pagesCount);
                  },
                  onPageChanged: (page) {
                    setState(() => _page = page);
                  },
                  builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                    options: const DefaultBuilderOptions(),
                    documentLoaderBuilder: (_) => const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                    pageLoaderBuilder: (_) => const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                    errorBuilder: (_, error) => Center(
                      child: Text('பக்கம் ஏற்ற முடியவில்லை: $error', style: const TextStyle(color: Colors.white70)),
                    ),
                  ),
                ),
    );
  }
}
