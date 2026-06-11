import 'package:flutter/material.dart';

import '../models/inauspicious_week.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';

/// இராகு, குளிகை, எமகண்டம் — weekly tab view (Sun–Sat).
class InauspiciousWeekScreen extends StatefulWidget {
  const InauspiciousWeekScreen({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime initialDate;

  @override
  State<InauspiciousWeekScreen> createState() => _InauspiciousWeekScreenState();
}

class _InauspiciousWeekScreenState extends State<InauspiciousWeekScreen>
    with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFE91E8C);

  InauspiciousWeek? _week;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final week = await widget.repository.getInauspiciousWeek(widget.initialDate);
      if (mounted) {
        setState(() => _week = week);
        final index = _initialTabIndex(week);
        _tabController.index = index;
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _initialTabIndex(InauspiciousWeek week) {
    final target = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    final idx = week.days.indexWhere(
      (d) =>
          d.gregorianDate.year == target.year &&
          d.gregorianDate.month == target.month &&
          d.gregorianDate.day == target.day,
    );
    if (idx >= 0) return idx;
    return widget.initialDate.weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text(
          'இராகு, குளிகை, எமகண்டம் முதலிய கால...',
          style: TextStyle(fontSize: 15),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _load, child: const Text('மீண்டும் முயற்சி')),
                      ],
                    ),
                  ),
                )
              : _week == null
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
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
                            tabs: _week!.days.map((d) => Tab(text: d.weekdayTa)).toList(),
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _week!.days.map((d) => _DayPanel(day: d)).toList(),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({required this.day});

  final InauspiciousWeekDay day;

  static const _infoBlue = Color(0xFF448AFF);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _infoBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            '* சூரிய உதயத்தில் இருந்து நேரத்தை கணக்கிட்டு கொள்ளவும்.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _DataRow(label: 'இராகு', value: day.rahuKalam),
        const SizedBox(height: 10),
        _DataRow(label: 'குளிகை', value: day.gulikaiKalam),
        const SizedBox(height: 10),
        _DataRow(label: 'எமகண்டம்', value: day.yamagandam),
        const SizedBox(height: 10),
        _DataRow(label: 'சூலம்', value: day.shoolam),
        const SizedBox(height: 10),
        _DataRow(label: 'பரிகாரம்', value: day.pariharam),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _Cell(text: label, isLabel: true)),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: _Cell(text: value.isEmpty ? '—' : value)),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.text, this.isLabel = false});

  final String text;
  final bool isLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isLabel ? FontWeight.w600 : FontWeight.normal,
          color: isLabel ? const Color(0xFF5D1F0E) : AppColors.textPrimary,
        ),
      ),
    );
  }
}
