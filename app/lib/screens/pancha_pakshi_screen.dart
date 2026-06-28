import 'package:flutter/material.dart';

import '../models/pancha_pakshi.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';
import 'pancha_pakshi_article_screen.dart';
import 'pancha_pakshi_calculator_screen.dart';

/// பஞ்ச பட்சி சாஸ்திரம் — article hub (competitor-style numbered list).
class PanchaPakshiScreen extends StatefulWidget {
  const PanchaPakshiScreen({
    super.key,
    required this.repository,
    this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime? initialDate;

  @override
  State<PanchaPakshiScreen> createState() => _PanchaPakshiScreenState();
}

class _PanchaPakshiScreenState extends State<PanchaPakshiScreen> {
  static const _blue = Color(0xFF1565C0);

  List<PanchaPakshiArticle> _articles = [];
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
      final articles = await widget.repository.getPanchaPakshiArticles();
      if (mounted) setState(() => _articles = articles);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openArticle(PanchaPakshiArticle article) {
    if (article.kind == 'calculator') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PanchaPakshiCalculatorScreen(
            repository: widget.repository,
            initialDate: widget.initialDate ?? DateTime.now(),
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PanchaPakshiArticleScreen(
          repository: widget.repository,
          articleId: article.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('பஞ்ச பட்சி சாஸ்திரம்', style: TextStyle(fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: _articles.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final article = _articles[index];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 0.5,
                        child: InkWell(
                          onTap: () => _openArticle(article),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: _blue,
                                  child: Text(
                                    '${article.id}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    article.titleTa,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('மீண்டும் முயற்சி')),
          ],
        ),
      ),
    );
  }
}
