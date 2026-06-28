import 'package:flutter/material.dart';

import '../models/palangal.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';
import 'palangal_article_screen.dart';
import 'tarabalam_screen.dart';

class PalangalCategoryScreen extends StatefulWidget {
  const PalangalCategoryScreen({
    super.key,
    required this.repository,
    required this.categoryId,
    required this.titleTa,
    this.initialDate,
    this.isCalculator = false,
  });

  final CalendarRepository repository;
  final String categoryId;
  final String titleTa;
  final DateTime? initialDate;
  final bool isCalculator;

  @override
  State<PalangalCategoryScreen> createState() => _PalangalCategoryScreenState();
}

class _PalangalCategoryScreenState extends State<PalangalCategoryScreen> {
  List<PalangalArticle> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isCalculator) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TarabalamScreen(
              repository: widget.repository,
              initialDate: widget.initialDate,
            ),
          ),
        );
      });
      return;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final articles = await widget.repository.getPalangalArticles(widget.categoryId);
      if (mounted) setState(() => _articles = articles);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCalculator) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.titleTa, style: const TextStyle(fontSize: 16)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final article = _articles[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.maroon.withValues(alpha: 0.1),
                          child: Text('${index + 1}', style: const TextStyle(color: AppColors.maroon, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(article.titleTa, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PalangalArticleScreen(
                              repository: widget.repository,
                              categoryId: widget.categoryId,
                              articleId: article.id,
                              titleTa: article.titleTa,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
