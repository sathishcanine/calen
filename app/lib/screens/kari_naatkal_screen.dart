import 'package:flutter/material.dart';

import '../models/month_calendar.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

/// கரி நாட்கள், அஷ்டமி, நவமி, தசமி — monthly view for a full year.
class KariNaatkalScreen extends StatefulWidget {
  const KariNaatkalScreen({
    super.key,
    required this.repository,
    required this.initialDate,
    this.year = 2026,
  });

  final CalendarRepository repository;
  final DateTime initialDate;
  final int year;

  @override
  State<KariNaatkalScreen> createState() => _KariNaatkalScreenState();
}

class _KariNaatkalScreenState extends State<KariNaatkalScreen>
    with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFE91E8C);
  static const _titleRed = Color(0xFFC62828);

  static const _monthNames = [
    'ஜனவரி',
    'பிப்ரவரி',
    'மார்ச்',
    'ஏப்ரல்',
    'மே',
    'ஜூன்',
    'ஜூலை',
    'ஆகஸ்ட்',
    'செப்டம்பர்',
    'அக்டோபர்',
    'நவம்பர்',
    'டிசம்பர்',
  ];

  late final TabController _tabController;
  late int _year;

  final Map<int, MonthCalendar?> _cache = {};
  final Map<int, String?> _errors = {};
  final Map<int, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    final initialMonth = widget.initialDate.year == _year ? widget.initialDate.month : DateTime.now().month;
    _tabController = TabController(
      length: 12,
      vsync: this,
      initialIndex: (initialMonth - 1).clamp(0, 11),
    );
    _tabController.addListener(_onTabChanged);
    _loadMonth(_tabController.index + 1);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _loadMonth(_tabController.index + 1);
  }

  Future<void> _loadMonth(int month) async {
    if (_loading[month] == true) return;
    setState(() {
      _loading[month] = true;
      _errors[month] = null;
    });
    try {
      final data = await widget.repository.getMonth(_year, month);
      if (mounted) setState(() => _cache[month] = data);
    } catch (e) {
      if (mounted) setState(() => _errors[month] = e.toString());
    } finally {
      if (mounted) setState(() => _loading[month] = false);
    }
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
          'கரி நாட்கள், அஷ்டமி, நவமி ம...',
          style: TextStyle(fontSize: 15),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _YearSelector(
              year: _year,
              onChanged: (y) {
                if (y == _year) return;
                setState(() {
                  _year = y;
                  _cache.clear();
                  _errors.clear();
                  _loading.clear();
                });
                _loadMonth(_tabController.index + 1);
              },
            ),
          ),
          Material(
            color: _pink,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: _pink,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              tabs: _monthNames.map((m) => Tab(text: m)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(12, (i) => _MonthPanel(
                    data: _cache[i + 1],
                    loading: _loading[i + 1] ?? false,
                    error: _errors[i + 1],
                    onRetry: () => _loadMonth(i + 1),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({required this.year, required this.onChanged});

  final int year;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: year,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(value: 2026, child: Text('2026')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _MonthPanel extends StatelessWidget {
  const _MonthPanel({
    required this.data,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final MonthCalendar? data;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading && data == null) {
      return const Center(child: CircularProgressIndicator(color: _KariNaatkalScreenState._pink));
    }
    if (error != null && data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('மீண்டும் முயற்சி')),
            ],
          ),
        ),
      );
    }

    final items = data?.otherDays ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('இந்த மாதத்திற்கு தரவு இல்லை'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['title']}',
                      style: const TextStyle(
                        color: _KariNaatkalScreenState._titleRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item['dates']}',
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
