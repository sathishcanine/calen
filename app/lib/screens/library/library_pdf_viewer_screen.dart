import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/ad_config.dart';
import '../../models/library_book.dart';
import '../../services/ad_service.dart';
import '../../services/budget_rating_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_share.dart';
import '../../widgets/budget/budget_rating_dialog.dart';

class LibraryPdfViewerScreen extends StatefulWidget {
  const LibraryPdfViewerScreen({super.key, required this.book});

  final LibraryBook book;

  @override
  State<LibraryPdfViewerScreen> createState() => _LibraryPdfViewerScreenState();
}

class _LibraryPdfViewerScreenState extends State<LibraryPdfViewerScreen> {
  static const _prefBackCount = 'library_pdf_back_count';

  PdfControllerPinch? _controller;
  bool _loading = true;
  String? _error;
  int _page = 1;
  int _pages = 0;
  bool _handlingBack = false;

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

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(AppShare.playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Pop to Noolagam first, then show interstitial on 1st/3rd/5th… backs (skip if no fill).
  Future<void> _finishBack() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final backCount = prefs.getInt(_prefBackCount) ?? 0;
    // 0,2,4… → 1st,3rd,5th back shows ad; 1,3,5… skips
    final shouldShowAd = backCount.isEven;
    await prefs.setInt(_prefBackCount, backCount + 1);

    if (!mounted) return;
    Navigator.pop(context);

    if (!shouldShowAd) return;

    await AdService.instance.showInterstitialForUnit(
      adUnitId: AdConfig.libraryInterstitialUnitId,
      onFinished: () {},
    );
  }

  Future<void> _handleBack() async {
    if (_handlingBack) return;
    _handlingBack = true;
    try {
      final hasRated = await BudgetRatingService.instance.hasAcceptedRating();
      if (!hasRated) {
        if (!mounted) return;
        final choice = await showBudgetRatingDialog(context);
        if (!mounted) return;
        if (choice == BudgetRatingChoice.yes) {
          await BudgetRatingService.instance.markRatingAccepted();
          await _openPlayStore();
          if (!mounted) return;
          await _finishBack();
          return;
        }
        if (choice == BudgetRatingChoice.maybe) {
          // பிராகு பார்க்கலாம் → Noolagam + alternate interstitial
          await _finishBack();
          return;
        }
        // Dialog dismissed — stay on PDF
        return;
      }

      await _finishBack();
    } finally {
      _handlingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
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
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _loading = true;
                                _error = null;
                              });
                              _loadPdf();
                            },
                            child: const Text('மீண்டும் முயற்சி'),
                          ),
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
                        child: Text(
                          'பக்கம் ஏற்ற முடியவில்லை: $error',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
