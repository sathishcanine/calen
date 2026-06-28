import 'package:flutter/material.dart';

import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

class PalangalArticleScreen extends StatefulWidget {
  const PalangalArticleScreen({
    super.key,
    required this.repository,
    required this.categoryId,
    required this.articleId,
    required this.titleTa,
  });

  final CalendarRepository repository;
  final String categoryId;
  final int articleId;
  final String titleTa;

  @override
  State<PalangalArticleScreen> createState() => _PalangalArticleScreenState();
}

class _PalangalArticleScreenState extends State<PalangalArticleScreen> {
  String _body = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await widget.repository.getPalangalArticle(widget.categoryId, widget.articleId);
      if (mounted) setState(() => _body = detail.bodyTa);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: Text(widget.titleTa, style: const TextStyle(fontSize: 15)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titleTa,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.maroon,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border(left: BorderSide(color: AppColors.gold, width: 4)),
                        ),
                        child: Text(
                          _body,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
