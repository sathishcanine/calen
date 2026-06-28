import 'package:flutter/material.dart';

import '../models/vastu.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

/// வாஸ்து நாட்கள் / தகவல்கள் — articles + annual vastu days.
class VastuScreen extends StatefulWidget {
  const VastuScreen({
    super.key,
    required this.repository,
    this.initialYear = 2026,
  });

  final CalendarRepository repository;
  final int initialYear;

  @override
  State<VastuScreen> createState() => _VastuScreenState();
}

class _VastuScreenState extends State<VastuScreen> with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFE91E8C);

  late TabController _tabController;
  late int _year;

  List<VastuArticle> _articles = [];
  List<int> _years = [];
  VastuDays? _days;
  bool _loadingArticles = true;
  bool _loadingDays = true;
  String? _articlesError;
  String? _daysError;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadArticles();
    _loadDays();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  Future<void> _loadArticles() async {
    setState(() {
      _loadingArticles = true;
      _articlesError = null;
    });
    try {
      final articles = await widget.repository.getVastuArticles();
      if (mounted) setState(() => _articles = articles);
    } catch (e) {
      if (mounted) setState(() => _articlesError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingArticles = false);
    }
  }

  Future<void> _loadDays() async {
    setState(() {
      _loadingDays = true;
      _daysError = null;
    });
    try {
      final years = await widget.repository.getVastuYears();
      final days = await widget.repository.getVastuDays(_year);
      if (mounted) {
        setState(() {
          _years = years.isNotEmpty ? years : [_year];
          _days = days;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _daysError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingDays = false);
    }
  }

  List<VastuArticle> get _filteredArticles {
    if (_search.trim().isEmpty) return _articles;
    final q = _search.trim().toLowerCase();
    return _articles.where((a) => a.titleTa.toLowerCase().contains(q)).toList();
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
        title: const Text(
          'வாஸ்து நாட்கள் / தகவல்கள்',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearch(context),
              tooltip: 'தேடல்',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.circular(24),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textPrimary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'தகவல்கள்'),
                  Tab(text: 'நாட்கள்'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ArticlesTab(
                  loading: _loadingArticles,
                  error: _articlesError,
                  articles: _filteredArticles,
                  onRetry: _loadArticles,
                  onTap: (article) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${article.titleTa}\n\nகட்டுரை விரைவில் சேர்க்கப்படும்'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
                _DaysTab(
                  loading: _loadingDays,
                  error: _daysError,
                  days: _days,
                  year: _year,
                  years: _years,
                  onYearChanged: (y) {
                    setState(() => _year = y);
                    _loadDays();
                  },
                  onRetry: _loadDays,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSearch(BuildContext context) async {
    final controller = TextEditingController(text: _search);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('தேடல்'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'தலைப்பில் தேடு...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ரத்து')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('தேடு'),
          ),
        ],
      ),
    );
    if (result != null && mounted) setState(() => _search = result);
  }
}

class _ArticlesTab extends StatelessWidget {
  const _ArticlesTab({
    required this.loading,
    required this.error,
    required this.articles,
    required this.onRetry,
    required this.onTap,
  });

  final bool loading;
  final String? error;
  final List<VastuArticle> articles;
  final VoidCallback onRetry;
  final void Function(VastuArticle) onTap;

  static const _pink = Color(0xFFE91E8C);

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _pink));
    }
    if (error != null) {
      return _ErrorPane(message: error!, onRetry: onRetry);
    }
    if (articles.isEmpty) {
      return const Center(child: Text('தகவல்கள் இல்லை'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: articles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final article = articles[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => onTap(article),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _pink,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${article.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      article.titleTa,
                      style: const TextStyle(fontSize: 14, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DaysTab extends StatelessWidget {
  const _DaysTab({
    required this.loading,
    required this.error,
    required this.days,
    required this.year,
    required this.years,
    required this.onYearChanged,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final VastuDays? days;
  final int year;
  final List<int> years;
  final ValueChanged<int> onYearChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: years.isNotEmpty ? (years.contains(year) ? year : years.first) : year,
                  items: years
                      .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (y) {
                    if (y != null) onYearChanged(y);
                  },
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E8C)))
              : error != null
                  ? _ErrorPane(message: error!, onRetry: onRetry)
                  : days == null || days!.days.isEmpty
                      ? Center(child: Text('$year ஆம் ஆண்டு நாட்கள் இல்லை'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: days!.days.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final day = days!.days[index];
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day.labelLine1Ta,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    day.timeLineTa,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

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
